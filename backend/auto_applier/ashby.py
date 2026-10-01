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

from .question_answerer import answer_screening_question


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

    # Find unfilled textareas and text inputs that aren't standard fields
    textareas = page.locator("textarea")
    ta_count = await textareas.count()

    for i in range(ta_count):
        try:
            ta = textareas.nth(i)
            current = await ta.input_value()
            if current:
                continue

            # Find the label for this textarea
            ta_id = await ta.get_attribute("id")
            question_text = ""

            if ta_id:
                label = page.locator(f'label[for="{ta_id}"]')
                if await label.count() > 0:
                    question_text = (await label.first.inner_text()).strip()

            if not question_text:
                # Try parent container label
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
                    log.append(f"[Ashby] Answered: '{question_text[:40]}...'")

        except Exception as e:
            log.append(f"[Ashby] Error filling textarea {i}: {e}")


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
                except Exception:
                    # Try partial text match
                    options = selects.first.locator("option")
                    for j in range(await options.count()):
                        opt_text = (await options.nth(j).inner_text()).strip()
                        if value.lower() in opt_text.lower():
                            opt_val = await options.nth(j).get_attribute("value")
                            if opt_val:
                                await selects.first.select_option(value=opt_val)
                                log.append(f"[Ashby] Set EEO {keyword}: {opt_text}")
                                break
        except Exception:
            pass
