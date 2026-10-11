"""
JOB SeArCh — Ashby ATS Form Driver
═══════════════════════════════════
Fills application forms on Ashby-powered career pages.

Ashby forms are typically inline on the job description page.
Simpler structure than Greenhouse/Lever:
- Resume upload at top
- Standard personal fields
- Custom questions inline
- EEO section at bottom
"""

import asyncio
from playwright.async_api import Page

from .question_answerer import answer_screening_question, determine_work_auth_answer


async def fill_ashby_form(
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
    """Fill an Ashby application form with candidate profile data."""

    log.append("[Ashby] Starting form fill...")

    # ── Click "Apply" button if on JD page ──
    try:
        apply_btn = page.locator(
            "button:has-text('Apply'), "
            "a:has-text('Apply for this job'), "
            "[data-testid='apply-button']"
        )
        if await apply_btn.count() > 0:
            await apply_btn.first.click()
            await page.wait_for_load_state("networkidle", timeout=8000)
            log.append("[Ashby] Clicked Apply button")
    except Exception:
        pass

    # Wait for form
    try:
        await page.wait_for_selector(
            "form, .ashby-application-form, [data-testid='application-form']",
            timeout=10000,
        )
        log.append("[Ashby] Application form detected")
    except Exception:
        log.append("[Ashby] Could not find application form, attempting best-effort fill")

    # ── Resume Upload ──
    if resume_path:
        try:
            file_input = page.locator('input[type="file"]')
            if await file_input.count() > 0:
                await file_input.first.set_input_files(resume_path)
                log.append(f"[Ashby] Uploaded resume: {resume_path}")
                await asyncio.sleep(1)
        except Exception as e:
            log.append(f"[Ashby] Resume upload failed: {e}")

    # ── Fill all visible input fields by scanning labels ──
    # Ashby uses a clean label → input structure
    await _fill_by_label_scan(page, profile_dict, log)

    # ── Custom Questions ──
    await _fill_ashby_questions(
        page, profile_dict, job_title, job_company,
        job_description, resume_text, custom_answers, log,
    )

    # ── EEO Fields ──
    await _fill_ashby_eeo(page, profile_dict, log)

    log.append("[Ashby] Form fill complete — ready for review")


async def _fill_by_label_scan(
    page: Page, profile_dict: dict, log: list[str]
) -> None:
    """Scan all labels on the page and fill corresponding inputs."""

    label_to_value = {
        "first name": profile_dict.get("first_name", ""),
        "last name": profile_dict.get("last_name", ""),
        "full name": profile_dict.get("full_name", ""),
        "name": profile_dict.get("full_name", ""),
        "email": profile_dict.get("email", ""),
        "phone": profile_dict.get("phone", ""),
        "location": profile_dict.get("location", ""),
        "city": profile_dict.get("location", ""),
        "current company": profile_dict.get("current_company", ""),
        "company": profile_dict.get("current_company", ""),
        "current title": profile_dict.get("current_title", ""),
        "linkedin": profile_dict.get("linkedin_url", ""),
        "github": profile_dict.get("github_url", ""),
        "portfolio": profile_dict.get("portfolio_url", ""),
        "website": profile_dict.get("website_url", ""),
    }

    labels = page.locator("label")
    label_count = await labels.count()

    for i in range(label_count):
        try:
            label_el = labels.nth(i)
            label_text = (await label_el.inner_text()).strip().lower()

            # Find matching value
            matched_value = None
            for key, value in label_to_value.items():
                if key in label_text and value:
                    matched_value = value
                    break

            if not matched_value:
                continue

            # Find the associated input
            label_for = await label_el.get_attribute("for")
            if label_for:
                target = page.locator(f"#{label_for}")
            else:
                # Try sibling/child input
                parent = label_el.locator("..")
                target = parent.locator("input, textarea")

            if await target.count() > 0:
                current = await target.first.input_value()
                if not current:
                    await target.first.fill(matched_value)
                    log.append(f"[Ashby] Filled '{label_text}': {matched_value[:30]}...")

        except Exception:
            continue


async def _fill_ashby_questions(
    page: Page,
    profile_dict: dict,
    job_title: str,
    job_company: str,
    job_description: str,
    resume_text: str,
    custom_answers: dict,
    log: list[str],
) -> None:
    """Fill custom questions in Ashby forms."""

    # 1. Textareas (screening paragraphs / cover notes)
    textareas = page.locator("textarea")
    ta_count = await textareas.count()

    for i in range(ta_count):
        try:
            ta = textareas.nth(i)
            current = await ta.input_value()
            if current:
                continue

            ta_id = await ta.get_attribute("id")
            question_text = ""

            if ta_id:
                label = page.locator(f'label[for="{ta_id}"]')
                if await label.count() > 0:
                    question_text = (await label.first.inner_text()).strip()

            if not question_text:
                parent = ta.locator("..")
                label = parent.locator("label")
                if await label.count() > 0:
                    question_text = (await label.first.inner_text()).strip()

            if question_text and len(question_text) > 5:
                answer = answer_screening_question(
                    question_text, job_title, job_company,
                    job_description, resume_text, profile_dict, custom_answers,
                )
                if answer:
                    await ta.fill(answer)
                    log.append(f"[Ashby] Answered textarea: '{question_text[:40]}...'")

        except Exception as e:
            log.append(f"[Ashby] Error filling textarea {i}: {e}")

    # 2. Screening Text Inputs (custom text questions)
    inputs = page.locator("input[type='text'], input:not([type])")
    inp_count = await inputs.count()
    standard_keys = ["first name", "last name", "full name", "email", "phone", "location", "city", "linkedin", "github", "portfolio", "website"]

    for i in range(inp_count):
        try:
            inp = inputs.nth(i)
            current = await inp.input_value()
            if current:
                continue

            inp_id = await inp.get_attribute("id")
            question_text = ""
            if inp_id:
                label = page.locator(f'label[for="{inp_id}"]')
                if await label.count() > 0:
                    question_text = (await label.first.inner_text()).strip()

            if not question_text:
                parent = inp.locator("..")
                label = parent.locator("label")
                if await label.count() > 0:
                    question_text = (await label.first.inner_text()).strip()

            if question_text and len(question_text) > 5:
                # Skip standard contact fields
                if any(k in question_text.lower() for k in standard_keys):
                    continue
                answer = answer_screening_question(
                    question_text, job_title, job_company,
                    job_description, resume_text, profile_dict, custom_answers,
                )
                if answer:
                    await inp.fill(answer)
                    log.append(f"[Ashby] Answered text input: '{question_text[:40]}...'")
        except Exception:
            continue

    # 3. Select Dropdowns (Work auth & sponsorship)
    selects = page.locator("select")
    sel_count = await selects.count()

    for i in range(sel_count):
        try:
            sel = selects.nth(i)
            sel_id = await sel.get_attribute("id")
            question_text = ""
            if sel_id:
                label = page.locator(f'label[for="{sel_id}"]')
                if await label.count() > 0:
                    question_text = (await label.first.inner_text()).strip()
            if not question_text:
                parent = sel.locator("..")
                label = parent.locator("label")
                if await label.count() > 0:
                    question_text = (await label.first.inner_text()).strip()

            if question_text:
                auth_val = determine_work_auth_answer(question_text, profile_dict)
                if auth_val:
                    try:
                        await sel.select_option(label=auth_val)
                        log.append(f"[Ashby] Selected '{auth_val}' for select: '{question_text[:40]}...'")
                        continue
                    except Exception:
                        options = sel.locator("option")
                        for j in range(await options.count()):
                            opt_text = (await options.nth(j).inner_text()).strip()
                            if auth_val.lower() == opt_text.lower():
                                await sel.select_option(index=j)
                                log.append(f"[Ashby] Selected '{opt_text}' for select: '{question_text[:40]}...'")
                                break
        except Exception:
            continue

    # 4. Radio Groups (Work auth & sponsorship)
    fieldsets = page.locator("fieldset, div:has(input[type='radio'])")
    fs_count = await fieldsets.count()

    for i in range(fs_count):
        try:
            fs = fieldsets.nth(i)
            legend = fs.locator("legend, label.group-label, span.question-title")
            question_text = ""
            if await legend.count() > 0:
                question_text = (await legend.first.inner_text()).strip()

            if not question_text:
                first_label = fs.locator("label").first
                if await first_label.count() > 0:
                    question_text = (await first_label.inner_text()).strip()

            if question_text:
                auth_val = determine_work_auth_answer(question_text, profile_dict)
                if auth_val:
                    target = auth_val.lower()
                    radio_labels = fs.locator("label")
                    for j in range(await radio_labels.count()):
                        lbl_text = (await radio_labels.nth(j).inner_text()).strip().lower()
                        if lbl_text == target or target in lbl_text:
                            await radio_labels.nth(j).click()
                            log.append(f"[Ashby] Clicked radio '{auth_val}' for: '{question_text[:40]}...'")
                            break
        except Exception:
            continue


async def _fill_ashby_eeo(page: Page, profile_dict: dict, log: list[str]) -> None:
    """Fill Ashby EEO fields."""
    eeo_map = {
        "gender": profile_dict.get("gender", "Decline to self-identify"),
        "race": profile_dict.get("race_ethnicity", "Decline to self-identify"),
        "ethnicity": profile_dict.get("race_ethnicity", "Decline to self-identify"),
        "veteran": profile_dict.get("veteran_status", "I am not a protected veteran"),
        "disability": profile_dict.get("disability_status", "I don't wish to answer"),
    }

    for keyword, value in eeo_map.items():
        try:
            selects = page.locator(
                f'select[name*="{keyword}" i], '
                f'select[id*="{keyword}" i], '
                f'select[aria-label*="{keyword}" i]'
            )
            if await selects.count() > 0:
                try:
                    await selects.first.select_option(label=value)
                    log.append(f"[Ashby] Set EEO {keyword}: {value}")
                    continue
                except Exception:
                    options = selects.first.locator("option")
                    for j in range(await options.count()):
                        opt_text = (await options.nth(j).inner_text()).strip()
                        if value.lower() in opt_text.lower():
                            opt_val = await options.nth(j).get_attribute("value")
                            if opt_val:
                                await selects.first.select_option(value=opt_val)
                                log.append(f"[Ashby] Set EEO {keyword}: {opt_text}")
                                break
                    continue

            # Radio fallback for EEO
            radios = page.locator(f'fieldset:has-text("{keyword}" i), div:has(label:has-text("{keyword}" i))')
            if await radios.count() > 0:
                labels = radios.first.locator("label")
                for j in range(await labels.count()):
                    lbl_text = (await labels.nth(j).inner_text()).strip().lower()
                    if value.lower() in lbl_text or "decline" in lbl_text:
                        await labels.nth(j).click()
                        log.append(f"[Ashby] Set EEO radio {keyword}: {lbl_text}")
                        break
        except Exception:
            pass
