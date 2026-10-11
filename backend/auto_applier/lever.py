"""
JOB SeArCh — Lever ATS Form Driver
═══════════════════════════════════
Fills application forms on jobs.lever.co.

Lever forms are typically accessed by clicking "Apply for this job"
on the job description page, which navigates to /apply.

Key Lever quirks:
- Location field uses Google Places autocomplete
- Resume upload is at the top
- Standard fields: name, email, phone, company, links
- Custom questions appear in labeled sections
- EEO section at the bottom with <select> dropdowns
- Checkbox fields (like pronouns) need click, not form_input
"""

import asyncio
from playwright.async_api import Page, TimeoutError as PlaywrightTimeout

from .question_answerer import answer_screening_question, determine_work_auth_answer


async def fill_lever_form(
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
    """Fill a Lever application form with candidate profile data."""

    log.append("[Lever] Starting form fill...")

    # ── Navigate to /apply page if needed ──
    current_url = page.url
    if "/apply" not in current_url:
        try:
            apply_link = page.locator(
                "a:has-text('Apply for this job'), "
                "a.postings-btn, "
                "a[href*='/apply']"
            )
            if await apply_link.count() > 0:
                await apply_link.first.click()
                await page.wait_for_load_state("networkidle", timeout=8000)
                log.append("[Lever] Navigated to apply page")
        except Exception as e:
            log.append(f"[Lever] Could not find apply button: {e}")

    # Wait for the application form
    await page.wait_for_selector(
        "form.application-form, .application-page, #application-form",
        timeout=10000,
    )
    log.append("[Lever] Application form detected")

    # ── Resume Upload (Lever puts this first) ──
    if resume_path:
        try:
            file_input = page.locator('input[type="file"][name*="resume"], input[type="file"]')
            if await file_input.count() > 0:
                await file_input.first.set_input_files(resume_path)
                log.append(f"[Lever] Uploaded resume: {resume_path}")
                await asyncio.sleep(1.5)
        except Exception as e:
            log.append(f"[Lever] Resume upload failed: {e}")

    # ── Personal Info Fields ──
    personal_fields = {
        'input[name="name"]': profile_dict.get("full_name", ""),
        'input[name="email"]': profile_dict.get("email", ""),
        'input[name="phone"]': profile_dict.get("phone", ""),
        'input[name="org"]': profile_dict.get("current_company", ""),
        'input[name="company"]': profile_dict.get("current_company", ""),
    }

    for selector, value in personal_fields.items():
        if not value:
            continue
        try:
            field = page.locator(selector)
            if await field.count() > 0:
                await field.first.clear()
                await field.first.fill(value)
                log.append(f"[Lever] Filled {selector}: {value[:30]}...")
        except Exception as e:
            log.append(f"[Lever] Could not fill {selector}: {e}")

    # ── Location field with Google Places autocomplete ──
    try:
        location_field = page.locator('input[name="location"], input[name*="location"]')
        if await location_field.count() > 0:
            loc_value = profile_dict.get("location", "")
            if loc_value:
                await location_field.first.click()
                await location_field.first.clear()
                await location_field.first.type(loc_value, delay=60)
                await asyncio.sleep(2)
                # Wait for and click the autocomplete suggestion
                suggestion = page.locator(
                    ".pac-item, .pac-container .pac-item, "
                    "[role='option'], .location-suggestion"
                )
                if await suggestion.count() > 0:
                    await suggestion.first.click()
                    log.append(f"[Lever] Selected location: {loc_value}")
                else:
                    log.append(f"[Lever] Typed location (no autocomplete): {loc_value}")
    except Exception as e:
        log.append(f"[Lever] Location field issue: {e}")

    # ── Link fields ──
    link_fields = {
        "linkedin": profile_dict.get("linkedin_url", ""),
        "github": profile_dict.get("github_url", ""),
        "portfolio": profile_dict.get("portfolio_url", ""),
        "website": profile_dict.get("website_url", ""),
        "twitter": profile_dict.get("twitter_url", ""),
    }

    for keyword, url in link_fields.items():
        if not url:
            continue
        try:
            # Lever uses input[name="urls[keyword]"] or similar patterns
            field = page.locator(
                f'input[name*="{keyword}"], '
                f'input[placeholder*="{keyword}" i]'
            )
            if await field.count() > 0:
                await field.first.fill(url)
                log.append(f"[Lever] Filled {keyword} link: {url[:40]}...")
            else:
                # Try by label
                label = page.locator(f'label:has-text("{keyword}")')
                if await label.count() > 0:
                    # Find the next input sibling
                    parent = label.first.locator("..")
                    inp = parent.locator("input")
                    if await inp.count() > 0:
                        await inp.first.fill(url)
                        log.append(f"[Lever] Filled {keyword} (via label)")
        except Exception:
            pass

    # ── Custom Questions ──
    await _fill_lever_custom_questions(
        page, profile_dict, job_title, job_company,
        job_description, resume_text, custom_answers, log,
    )

    # ── EEO Fields ──
    await _fill_lever_eeo(page, profile_dict, log)

    log.append("[Lever] Form fill complete — ready for review")


async def _fill_lever_custom_questions(
    page: Page,
    profile_dict: dict,
    job_title: str,
    job_company: str,
    job_description: str,
    resume_text: str,
    custom_answers: dict,
    log: list[str],
) -> None:
    """Process custom questions in Lever forms."""

    # Lever groups custom questions in sections
    question_groups = page.locator(
        ".application-question, .custom-question, "
        ".application-field, [data-qa='question']"
    )
    count = await question_groups.count()
    log.append(f"[Lever] Found {count} custom question groups")

    for i in range(count):
        group = question_groups.nth(i)
        try:
            label = group.locator("label, .question-label, legend")
            if await label.count() == 0:
                continue

            question_text = (await label.first.inner_text()).strip()
            if not question_text or len(question_text) < 3:
                continue

            # Skip already-handled fields
            skip_terms = ["name", "email", "phone", "resume", "location", "company"]
            if any(term in question_text.lower() for term in skip_terms):
                continue

            # Textarea
            textarea = group.locator("textarea")
            if await textarea.count() > 0:
                current = await textarea.first.input_value()
                if not current:
                    answer = answer_screening_question(
                        question_text, job_title, job_company,
                        job_description, resume_text, profile_dict, custom_answers,
                    )
                    if answer:
                        await textarea.first.fill(answer)
                        log.append(f"[Lever] Answered textarea: '{question_text[:40]}...'")
                continue

            # Text input
            text_input = group.locator("input[type='text'], input[type='url'], input:not([type])")
            if await text_input.count() > 0:
                current = await text_input.first.input_value()
                if not current:
                    answer = answer_screening_question(
                        question_text, job_title, job_company,
                        job_description, resume_text, profile_dict, custom_answers,
                    )
                    if answer:
                        await text_input.first.fill(answer)
                        log.append(f"[Lever] Answered text: '{question_text[:40]}...'")
                continue

            # Select/Dropdown
            select = group.locator("select")
            if await select.count() > 0:
                auth_val = determine_work_auth_answer(question_text, profile_dict)
                if auth_val:
                    try:
                        await select.first.select_option(label=auth_val)
                        log.append(f"[Lever] Selected '{auth_val}' for auth question")
                    except Exception:
                        pass
                continue

            # Radio buttons
            radios = group.locator("input[type='radio']")
            if await radios.count() > 0:
                auth_val = determine_work_auth_answer(question_text, profile_dict)
                target = auth_val.lower() if auth_val else None

                if target:
                    radio_labels = group.locator("label")
                    for j in range(await radio_labels.count()):
                        lbl_text = (await radio_labels.nth(j).inner_text()).strip().lower()
                        if lbl_text == target:
                            await radio_labels.nth(j).click()
                            log.append(f"[Lever] Selected radio '{target}'")
                            break

        except Exception as e:
            log.append(f"[Lever] Error on question {i}: {e}")


async def _fill_lever_eeo(page: Page, profile_dict: dict, log: list[str]) -> None:
    """Fill Lever EEO fields — these are typically <select> dropdowns at the bottom."""
    eeo_keywords = {
        "gender": profile_dict.get("gender", "Decline to self-identify"),
        "race": profile_dict.get("race_ethnicity", "Decline to self-identify"),
        "ethnicity": profile_dict.get("race_ethnicity", "Decline to self-identify"),
        "veteran": profile_dict.get("veteran_status", "I am not a protected veteran"),
        "disability": profile_dict.get("disability_status", "I don't wish to answer"),
    }

    for keyword, value in eeo_keywords.items():
        try:
            # Lever often uses select elements inside EEO sections
            eeo_selects = page.locator(
                f'select[name*="{keyword}"], '
                f'select[id*="{keyword}"], '
                f'select[aria-label*="{keyword}" i]'
            )
            if await eeo_selects.count() > 0:
                try:
                    await eeo_selects.first.select_option(label=value)
                    log.append(f"[Lever] Set EEO {keyword}: {value}")
                except Exception:
                    # Partial match fallback
                    options = eeo_selects.first.locator("option")
                    for j in range(await options.count()):
                        opt_text = (await options.nth(j).inner_text()).strip()
                        if value.lower() in opt_text.lower():
                            opt_val = await options.nth(j).get_attribute("value")
                            if opt_val:
                                await eeo_selects.first.select_option(value=opt_val)
                                log.append(f"[Lever] Set EEO {keyword}: {opt_text}")
                                break
        except Exception:
            pass
