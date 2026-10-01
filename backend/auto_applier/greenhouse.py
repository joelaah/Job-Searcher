"""
JOB SeArCh — Greenhouse ATS Form Driver
════════════════════════════════════════
Fills application forms on boards.greenhouse.io.

Greenhouse forms are typically a single page with:
- Name, email, phone, location fields at the top
- Resume file upload
- LinkedIn, website, and other link fields
- Custom questions (text, select, radio, checkbox)
- EEO section at the bottom with dropdowns
"""

import asyncio
from playwright.async_api import Page, Locator, TimeoutError as PlaywrightTimeout

from .question_answerer import answer_screening_question, generate_tailored_cover_pitch


async def fill_greenhouse_form(
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
    """Fill a Greenhouse application form with candidate profile data."""

    log.append("[Greenhouse] Starting form fill...")

    # ── Click "Apply for this job" if we're on the JD page ──
    try:
        apply_btn = page.locator("a:has-text('Apply for this job'), button:has-text('Apply for this job')")
        if await apply_btn.count() > 0:
            await apply_btn.first.click()
            await page.wait_for_load_state("networkidle", timeout=8000)
            log.append("[Greenhouse] Clicked 'Apply for this job'")
    except Exception:
        pass

    # Wait for the form to appear
    await page.wait_for_selector("#application_form, form[action*='application'], .application-form", timeout=10000)
    log.append("[Greenhouse] Application form detected")

    # ── Personal Info Fields ──
    field_map = {
        "#first_name": profile_dict.get("first_name", ""),
        "#last_name": profile_dict.get("last_name", ""),
        "#email": profile_dict.get("email", ""),
        "#phone": profile_dict.get("phone", ""),
        "#location": profile_dict.get("location", ""),
    }

    for selector, value in field_map.items():
        if not value:
            continue
        try:
            field = page.locator(selector)
            if await field.count() > 0:
                await field.first.clear()
                await field.first.fill(value)
                log.append(f"[Greenhouse] Filled {selector}: {value[:30]}...")
        except Exception as e:
            log.append(f"[Greenhouse] Could not fill {selector}: {e}")

    # ── Also try name-based selectors (Greenhouse variants) ──
    name_map = {
        'input[name*="first_name"]': profile_dict.get("first_name", ""),
        'input[name*="last_name"]': profile_dict.get("last_name", ""),
        'input[name*="email"]': profile_dict.get("email", ""),
        'input[name*="phone"]': profile_dict.get("phone", ""),
    }

    for selector, value in name_map.items():
        if not value:
            continue
        try:
            field = page.locator(selector)
            if await field.count() > 0:
                el = field.first
                current_val = await el.input_value()
                if not current_val:
                    await el.fill(value)
        except Exception:
            pass

    # ── Location field with autocomplete ──
    try:
        location_field = page.locator('#location, input[name*="location"]')
        if await location_field.count() > 0:
            loc_value = profile_dict.get("location", "")
            if loc_value:
                await location_field.first.clear()
                await location_field.first.type(loc_value, delay=50)
                await asyncio.sleep(1.5)
                # Click first autocomplete suggestion if present
                suggestion = page.locator(".pac-item, .location-autocomplete-item, [role='option']")
                if await suggestion.count() > 0:
                    await suggestion.first.click()
                    log.append(f"[Greenhouse] Selected location autocomplete: {loc_value}")
    except Exception as e:
        log.append(f"[Greenhouse] Location autocomplete issue: {e}")

    # ── Resume Upload ──
    if resume_path:
        try:
            file_input = page.locator('input[type="file"]')
            if await file_input.count() > 0:
                await file_input.first.set_input_files(resume_path)
                log.append(f"[Greenhouse] Uploaded resume: {resume_path}")
                await asyncio.sleep(1)
        except Exception as e:
            log.append(f"[Greenhouse] Resume upload failed: {e}")

    # ── Link fields (LinkedIn, GitHub, Portfolio, Website) ──
    link_fields = {
        "linkedin": profile_dict.get("linkedin_url", ""),
        "github": profile_dict.get("github_url", ""),
        "portfolio": profile_dict.get("portfolio_url", ""),
        "website": profile_dict.get("website_url", ""),
    }

    for keyword, url in link_fields.items():
        if not url:
            continue
        try:
            # Find input fields by label or name containing the keyword
            field = page.locator(f'input[name*="{keyword}"], input[id*="{keyword}"]')
            if await field.count() > 0:
                await field.first.fill(url)
                log.append(f"[Greenhouse] Filled {keyword}: {url[:40]}...")
            else:
                # Try finding by label text
                label = page.locator(f'label:has-text("{keyword}")')
                if await label.count() > 0:
                    label_for = await label.first.get_attribute("for")
                    if label_for:
                        target = page.locator(f"#{label_for}")
                        if await target.count() > 0:
                            await target.first.fill(url)
                            log.append(f"[Greenhouse] Filled {keyword} (via label): {url[:40]}...")
        except Exception:
            pass

    # ── Custom Questions (text inputs, textareas, selects, radios) ──
    await _fill_custom_questions(
        page, profile_dict, job_title, job_company,
        job_description, resume_text, custom_answers, log,
    )

    # ── EEO / Demographic Fields ──
    await _fill_eeo_fields(page, profile_dict, log)

    log.append("[Greenhouse] Form fill complete — ready for review")


async def _fill_custom_questions(
    page: Page,
    profile_dict: dict,
    job_title: str,
    job_company: str,
    job_description: str,
    resume_text: str,
    custom_answers: dict,
    log: list[str],
) -> None:
    """Fill custom screening questions using AI."""

    # Find all question containers (Greenhouse uses div.field with labels)
    question_blocks = page.locator(
        ".field:has(label), .application-field:has(label), "
        "[data-field]:has(label)"
    )
    count = await question_blocks.count()
    log.append(f"[Greenhouse] Found {count} question blocks to process")

    for i in range(count):
        block = question_blocks.nth(i)
        try:
            label_el = block.locator("label").first
            question_text = (await label_el.inner_text()).strip()

            if not question_text or len(question_text) < 3:
                continue

            # Skip fields we've already filled (name, email, etc.)
            skip_keywords = ["first name", "last name", "email", "phone", "resume", "cover letter"]
            if any(kw in question_text.lower() for kw in skip_keywords):
                continue

            # Check for textarea
            textarea = block.locator("textarea")
            if await textarea.count() > 0:
                current = await textarea.first.input_value()
                if not current:
                    answer = answer_screening_question(
                        question_text, job_title, job_company,
                        job_description, resume_text, profile_dict, custom_answers,
                    )
                    if answer:
                        await textarea.first.fill(answer)
                        log.append(f"[Greenhouse] Answered textarea '{question_text[:50]}...'")
                continue

            # Check for text input (not already filled)
            text_input = block.locator("input[type='text'], input:not([type])")
            if await text_input.count() > 0:
                current = await text_input.first.input_value()
                if not current:
                    answer = answer_screening_question(
                        question_text, job_title, job_company,
                        job_description, resume_text, profile_dict, custom_answers,
                    )
                    if answer:
                        await text_input.first.fill(answer)
                        log.append(f"[Greenhouse] Answered text '{question_text[:50]}...'")
                continue

            # Check for select dropdown
            select = block.locator("select")
            if await select.count() > 0:
                await _fill_select_field(select.first, question_text, profile_dict, log)
                continue

            # Check for radio buttons
            radios = block.locator("input[type='radio']")
            if await radios.count() > 0:
                await _fill_radio_field(block, question_text, profile_dict, log)

        except Exception as e:
            log.append(f"[Greenhouse] Error processing question block {i}: {e}")


async def _fill_select_field(
    select: Locator,
    question_text: str,
    profile_dict: dict,
    log: list[str],
) -> None:
    """Fill a select/dropdown field based on question context."""
    q_lower = question_text.lower()

    # Work authorization
    if any(kw in q_lower for kw in ["authorized", "eligible", "legally"]):
        val = "Yes" if profile_dict.get("authorized_to_work", True) else "No"
        try:
            await select.select_option(label=val)
            log.append(f"[Greenhouse] Selected '{val}' for work auth")
        except Exception:
            pass
        return

    # Sponsorship
    if "sponsorship" in q_lower:
        val = "Yes" if profile_dict.get("requires_sponsorship", False) else "No"
        try:
            await select.select_option(label=val)
            log.append(f"[Greenhouse] Selected '{val}' for sponsorship")
        except Exception:
            pass
        return

    log.append(f"[Greenhouse] Skipped unknown select: '{question_text[:50]}...'")


async def _fill_radio_field(
    block: Locator,
    question_text: str,
    profile_dict: dict,
    log: list[str],
) -> None:
    """Fill radio button fields based on question context."""
    q_lower = question_text.lower()

    target_value = None
    if any(kw in q_lower for kw in ["authorized", "eligible"]):
        target_value = "yes" if profile_dict.get("authorized_to_work", True) else "no"
    elif "sponsorship" in q_lower:
        target_value = "yes" if profile_dict.get("requires_sponsorship", False) else "no"
    elif any(kw in q_lower for kw in ["relocate", "willing to"]):
        target_value = "yes"

    if target_value:
        try:
            labels = block.locator("label")
            label_count = await labels.count()
            for i in range(label_count):
                label_text = (await labels.nth(i).inner_text()).strip().lower()
                if label_text == target_value:
                    await labels.nth(i).click()
                    log.append(f"[Greenhouse] Selected radio '{target_value}' for '{question_text[:40]}...'")
                    return
        except Exception:
            pass


async def _fill_eeo_fields(page: Page, profile_dict: dict, log: list[str]) -> None:
    """Fill EEO demographic fields (voluntary self-identification)."""
    eeo_map = {
        "gender": profile_dict.get("gender", "Decline to self-identify"),
        "race": profile_dict.get("race_ethnicity", "Decline to self-identify"),
        "ethnicity": profile_dict.get("race_ethnicity", "Decline to self-identify"),
        "veteran": profile_dict.get("veteran_status", "I am not a protected veteran"),
        "disability": profile_dict.get("disability_status", "I don't wish to answer"),
    }

    for keyword, value in eeo_map.items():
        try:
            selects = page.locator(f'select[name*="{keyword}"], select[id*="{keyword}"]')
            if await selects.count() > 0:
                try:
                    await selects.first.select_option(label=value)
                    log.append(f"[Greenhouse] Set EEO {keyword}: {value}")
                except Exception:
                    # Try partial match on option text
                    options = selects.first.locator("option")
                    opt_count = await options.count()
                    for i in range(opt_count):
                        opt_text = (await options.nth(i).inner_text()).strip()
                        if value.lower() in opt_text.lower() or opt_text.lower() in value.lower():
                            opt_val = await options.nth(i).get_attribute("value")
                            if opt_val:
                                await selects.first.select_option(value=opt_val)
                                log.append(f"[Greenhouse] Set EEO {keyword}: {opt_text}")
                                break
        except Exception:
            pass
