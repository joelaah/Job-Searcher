"""
JOB SeArCh — Generic ATS Form Driver
═════════════════════════════════════
Fallback form filler for unknown ATS systems.
Uses a heuristic label-scanning approach to fill any HTML form.
"""

import asyncio
from playwright.async_api import Page

from .question_answerer import answer_screening_question, determine_work_auth_answer


async def fill_generic_form(
    page: Page,
    profile_dict: dict,
    resume_path: str,
    job_title: str,
    job_company: str,
    job_description: str,
    resume_text: str,
    custom_answers: dict[str, str],
    log: list[str],
) -> None:
    """Best-effort form fill for unknown ATS systems."""

    log.append("[Generic] Starting heuristic form fill...")

    # ── Click any visible "Apply" button ──
    try:
        apply_btn = page.locator(
            "a:has-text('Apply'), button:has-text('Apply'), "
            "a:has-text('Submit Application'), button:has-text('Submit Application'), "
            "[data-action='apply']"
        )
        if await apply_btn.count() > 0:
            await apply_btn.first.click()
            await page.wait_for_load_state("networkidle", timeout=8000)
            log.append("[Generic] Clicked Apply button")
    except Exception:
        pass

    await asyncio.sleep(1)

    # ── Resume Upload ──
    if resume_path:
        try:
            file_input = page.locator('input[type="file"]')
            if await file_input.count() > 0:
                await file_input.first.set_input_files(resume_path)
                log.append(f"[Generic] Uploaded resume: {resume_path}")
                await asyncio.sleep(1)
        except Exception as e:
            log.append(f"[Generic] Resume upload failed: {e}")

    # ── Build a comprehensive keyword → value map ──
    keyword_map = _build_keyword_map(profile_dict)

    # ── Scan all form inputs and try to fill by attribute matching ──
    all_inputs = page.locator(
        "input[type='text'], input[type='email'], input[type='tel'], "
        "input[type='url'], input:not([type]), textarea"
    )
    input_count = await all_inputs.count()
    log.append(f"[Generic] Found {input_count} fillable fields")

    for i in range(input_count):
        try:
            inp = all_inputs.nth(i)

            # Skip hidden or already-filled fields
            if not await inp.is_visible():
                continue
            current = await inp.input_value()
            if current:
                continue

            # Gather all identifying attributes
            name_attr = (await inp.get_attribute("name") or "").lower()
            id_attr = (await inp.get_attribute("id") or "").lower()
            placeholder = (await inp.get_attribute("placeholder") or "").lower()
            aria_label = (await inp.get_attribute("aria-label") or "").lower()
            input_type = (await inp.get_attribute("type") or "text").lower()

            # Combine all identifiers for matching
            identifiers = f"{name_attr} {id_attr} {placeholder} {aria_label}"

            # Try to match against keyword map
            matched = False
            for keywords, value in keyword_map.items():
                if any(kw in identifiers for kw in keywords):
                    tag_name = await inp.evaluate("el => el.tagName.toLowerCase()")
                    if tag_name == "textarea":
                        # For textareas, check if it's a custom question
                        label_text = await _get_label_for_input(page, inp)
                        if label_text and len(label_text) > 20:
                            answer = answer_screening_question(
                                label_text, job_title, job_company,
                                job_description, resume_text, profile_dict, custom_answers,
                            )
                            if answer:
                                await inp.fill(answer)
                                log.append(f"[Generic] AI-answered: '{label_text[:40]}...'")
                                matched = True
                        elif value:
                            await inp.fill(value)
                            matched = True
                    else:
                        await inp.fill(value)
                        log.append(f"[Generic] Filled field ({identifiers[:30]}): {value[:30]}...")
                        matched = True
                    break

            if not matched:
                # Last resort: check label text for context
                label_text = await _get_label_for_input(page, inp)
                if label_text:
                    label_lower = label_text.lower()
                    for keywords, value in keyword_map.items():
                        if any(kw in label_lower for kw in keywords):
                            await inp.fill(value)
                            log.append(f"[Generic] Filled by label '{label_text[:30]}': {value[:30]}...")
                            break

        except Exception as e:
            log.append(f"[Generic] Error on field {i}: {e}")

    # ── Handle select/dropdown fields ──
    await _fill_generic_selects(page, profile_dict, log)

    # ── Handle radio buttons ──
    await _fill_generic_radios(page, profile_dict, log)

    # ── Fill unfilled textareas with AI answers ──
    await _fill_remaining_textareas(
        page, profile_dict, job_title, job_company,
        job_description, resume_text, custom_answers, log,
    )

    log.append("[Generic] Heuristic form fill complete — ready for review")


def _build_keyword_map(profile_dict: dict) -> dict[tuple, str]:
    """Build a keyword tuple → value mapping for form field matching."""
    return {
        ("first_name", "first-name", "firstname", "fname"): profile_dict.get("first_name", ""),
        ("last_name", "last-name", "lastname", "lname", "surname"): profile_dict.get("last_name", ""),
        ("full_name", "full-name", "fullname", "your name", "applicant name"): profile_dict.get("full_name", ""),
        ("email", "e-mail", "emailaddress", "email_address"): profile_dict.get("email", ""),
        ("phone", "telephone", "tel", "mobile", "cell"): profile_dict.get("phone", ""),
        ("location", "city", "address", "where are you"): profile_dict.get("location", ""),
        ("linkedin", "linked-in"): profile_dict.get("linkedin_url", ""),
        ("github", "git-hub"): profile_dict.get("github_url", ""),
        ("portfolio", "personal site"): profile_dict.get("portfolio_url", ""),
        ("website", "web site", "homepage"): profile_dict.get("website_url", ""),
        ("company", "current_company", "current company", "org", "organization"): profile_dict.get("current_company", ""),
        ("title", "current_title", "current title", "job title", "position"): profile_dict.get("current_title", ""),
    }


async def _get_label_for_input(page: Page, inp) -> str:
    """Find the label text associated with an input element."""
    try:
        inp_id = await inp.get_attribute("id")
        if inp_id:
            label = page.locator(f'label[for="{inp_id}"]')
            if await label.count() > 0:
                return (await label.first.inner_text()).strip()

        # Try parent container
        parent = inp.locator("..")
        label = parent.locator("label")
        if await label.count() > 0:
            return (await label.first.inner_text()).strip()

        # Try aria-label
        aria = await inp.get_attribute("aria-label")
        if aria:
            return aria.strip()

    except Exception:
        pass
    return ""


async def _fill_generic_selects(page: Page, profile_dict: dict, log: list[str]) -> None:
    """Fill select/dropdown fields in generic forms."""
    selects = page.locator("select:visible")
    sel_count = await selects.count()

    for i in range(sel_count):
        try:
            sel = selects.nth(i)
            name = (await sel.get_attribute("name") or "").lower()
            sel_id = (await sel.get_attribute("id") or "").lower()
            label_text = await _get_label_for_input(page, sel)
            identifiers = f"{name} {sel_id} {label_text}".lower().strip()

            # 1. Work authorization / visa sponsorship
            auth_val = determine_work_auth_answer(identifiers, profile_dict)
            if auth_val:
                try:
                    await sel.select_option(label=auth_val)
                    log.append(f"[Generic] Selected '{auth_val}' for auth/sponsorship: {identifiers[:40]}...")
                    continue
                except Exception:
                    options = sel.locator("option")
                    for j in range(await options.count()):
                        opt_text = (await options.nth(j).inner_text()).strip()
                        if auth_val.lower() == opt_text.lower():
                            await sel.select_option(index=j)
                            log.append(f"[Generic] Selected '{opt_text}' for {identifiers[:40]}...")
                            break
                    continue

            # 2. EEO/demographic fields
            if "gender" in identifiers:
                val = profile_dict.get("gender", "Decline to self-identify")
                try:
                    await sel.select_option(label=val)
                    log.append(f"[Generic] Set gender: {val}")
                except Exception:
                    pass
            elif any(kw in identifiers for kw in ["race", "ethnicity"]):
                val = profile_dict.get("race_ethnicity", "Decline to self-identify")
                try:
                    await sel.select_option(label=val)
                    log.append(f"[Generic] Set race/ethnicity: {val}")
                except Exception:
                    pass
            elif "veteran" in identifiers:
                val = profile_dict.get("veteran_status", "I am not a protected veteran")
                try:
                    await sel.select_option(label=val)
                    log.append(f"[Generic] Set veteran: {val}")
                except Exception:
                    pass
            elif "disability" in identifiers:
                val = profile_dict.get("disability_status", "I don't wish to answer")
                try:
                    await sel.select_option(label=val)
                    log.append(f"[Generic] Set disability: {val}")
                except Exception:
                    pass

        except Exception:
            continue


async def _fill_generic_radios(page: Page, profile_dict: dict, log: list[str]) -> None:
    """Fill radio button groups by analyzing the question text."""
    # Find fieldset or radio groups
    fieldsets = page.locator("fieldset:has(input[type='radio'])")
    fs_count = await fieldsets.count()

    for i in range(fs_count):
        try:
            fs = fieldsets.nth(i)
            legend = fs.locator("legend, label.group-label")
            if await legend.count() == 0:
                continue

            question = (await legend.first.inner_text()).strip()
            auth_val = determine_work_auth_answer(question, profile_dict)
            target = auth_val.lower() if auth_val else None

            if not target and "relocate" in question.lower():
                target = "yes"

            if target:
                labels = fs.locator("label")
                for j in range(await labels.count()):
                    text = (await labels.nth(j).inner_text()).strip().lower()
                    if text == target:
                        await labels.nth(j).click()
                        log.append(f"[Generic] Radio '{target}' for '{question[:30]}...'")
                        break

        except Exception:
            continue


async def _fill_remaining_textareas(
    page: Page,
    profile_dict: dict,
    job_title: str,
    job_company: str,
    job_description: str,
    resume_text: str,
    custom_answers: dict,
    log: list[str],
) -> None:
    """Fill any remaining empty textareas using AI."""
    textareas = page.locator("textarea:visible")
    ta_count = await textareas.count()

    for i in range(ta_count):
        try:
            ta = textareas.nth(i)
            current = await ta.input_value()
            if current:
                continue

            label_text = await _get_label_for_input(page, ta)
            if label_text and len(label_text) > 5:
                answer = answer_screening_question(
                    label_text, job_title, job_company,
                    job_description, resume_text, profile_dict, custom_answers,
                )
                if answer:
                    await ta.fill(answer)
                    log.append(f"[Generic] AI-answered textarea: '{label_text[:40]}...'")

        except Exception:
            continue
