"""
JOB SeArCh — Auto-Apply Core Engine
════════════════════════════════════
Orchestrates the full auto-apply pipeline:
1. Detect ATS type from URL
2. Launch Playwright stealth browser
3. Route to the appropriate ATS form driver
4. Take verification screenshot
5. Return structured result

Zero-Knowledge: Everything runs locally. No credentials leave your machine.
"""

import asyncio
import os
import sys
import time
from dataclasses import dataclass, field
from enum import Enum
from urllib.parse import urlparse

# Add parent directory for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from candidate_profile import CandidateProfile, load_profile


class ATSType(str, Enum):
    GREENHOUSE = "greenhouse"
    LEVER = "lever"
    ASHBY = "ashby"
    GENERIC = "generic"


@dataclass
class ApplyResult:
    """Result of an auto-apply attempt."""
    success: bool
    ats_type: str
    job_url: str
    screenshot_path: str = ""
    log: list[str] = field(default_factory=list)
    error: str = ""
    fields_filled: int = 0
    duration_seconds: float = 0.0

    def to_dict(self) -> dict:
        return {
            "success": self.success,
            "ats_type": self.ats_type,
            "job_url": self.job_url,
            "screenshot_path": self.screenshot_path,
            "log": self.log,
            "error": self.error,
            "fields_filled": self.fields_filled,
            "duration_seconds": round(self.duration_seconds, 2),
        }


def detect_ats_type(url: str) -> ATSType:
    """Detect which ATS system a job URL belongs to."""
    url_lower = url.lower()
    parsed = urlparse(url_lower)
    domain = parsed.netloc

    # Greenhouse
    if "greenhouse.io" in domain or "boards.greenhouse" in domain:
        return ATSType.GREENHOUSE
    if "greenhouse" in url_lower:
        return ATSType.GREENHOUSE

    # Lever
    if "lever.co" in domain or "jobs.lever" in domain:
        return ATSType.LEVER
    if "lever" in domain:
        return ATSType.LEVER

    # Ashby
    if "ashbyhq.com" in domain or "jobs.ashby" in domain:
        return ATSType.ASHBY
    if "ashby" in domain:
        return ATSType.ASHBY

    return ATSType.GENERIC


STEALTH_EVASION_SCRIPT = """
(() => {
    // 1. Prototype-level webdriver override (matches standard non-automated Chrome returning false)
    try {
        const proto = Object.getPrototypeOf(navigator);
        delete proto.webdriver;
        Object.defineProperty(proto, 'webdriver', {
            get: () => false,
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(navigator, 'webdriver', {
            get: () => false,
            enumerable: false,
            configurable: true
        });
    } catch (e) {}

    // 2. Realistic window.chrome object with runtime, app, csi, loadTimes
    try {
        if (!window.chrome) {
            window.chrome = {};
        }
        if (!window.chrome.runtime) {
            window.chrome.runtime = {
                connect: function() {},
                sendMessage: function() {},
                onMessage: { addListener: function() {}, removeListener: function() {} },
                onConnect: { addListener: function() {}, removeListener: function() {} },
                PlatformOs: { MAC: 'mac', WIN: 'win', ANDROID: 'android', CROS: 'cros', LINUX: 'linux', OPENBSD: 'openbsd' },
                PlatformArch: { ARM: 'arm', X86_32: 'x86-32', X86_64: 'x86-64' },
                PlatformNaclArch: { ARM: 'arm', X86_32: 'x86-32', X86_64: 'x86-64' },
                RequestUpdateCheckStatus: { THROTTLED: 'throttled', NO_UPDATE: 'no_update', UPDATE_AVAILABLE: 'update_available' },
                OnInstalledReason: { INSTALL: 'install', UPDATE: 'update', CHROME_UPDATE: 'chrome_update', SHARED_MODULE_UPDATE: 'shared_module_update' },
                OnRestartRequiredReason: { APP_UPDATE: 'app_update', OS_UPDATE: 'os_update', PERIODIC: 'periodic' }
            };
        }
        if (!window.chrome.app) {
            window.chrome.app = {
                isInstalled: false,
                InstallState: { DISABLED: 'disabled', INSTALLED: 'installed', NOT_INSTALLED: 'not_installed' },
                RunningState: { CANNOT_RUN: 'cannot_run', READY_TO_RUN: 'ready_to_run', RUNNING: 'running' }
            };
        }
        if (!window.chrome.csi) {
            window.chrome.csi = function() { return { startE: Date.now(), onloadT: Date.now() + 100, pageT: 250, tran: 15 }; };
        }
        if (!window.chrome.loadTimes) {
            window.chrome.loadTimes = function() {
                return {
                    requestTime: Date.now() / 1000,
                    startLoadTime: Date.now() / 1000,
                    commitLoadTime: Date.now() / 1000 + 0.1,
                    finishDocumentLoadTime: Date.now() / 1000 + 0.2,
                    firstPaintTime: Date.now() / 1000 + 0.25,
                    finishLoadTime: Date.now() / 1000 + 0.3,
                    wasFetchedViaSpdy: true,
                    wasNpnNegotiated: true,
                    npnNegotiatedProtocol: 'h2',
                    wasAlternateProtocolAvailable: false,
                    connectionInfo: 'h2'
                };
            };
        }
    } catch (e) {}

    // 3. Realistic navigator.plugins & navigator.mimeTypes
    try {
        function fakePlugin(name, filename, description, mimeTypes) {
            const plugin = Object.create(Plugin.prototype);
            Object.defineProperties(plugin, {
                name: { value: name, enumerable: true },
                filename: { value: filename, enumerable: true },
                description: { value: description, enumerable: true },
                length: { value: mimeTypes.length, enumerable: true }
            });
            mimeTypes.forEach((mt, i) => {
                const mime = Object.create(MimeType.prototype);
                Object.defineProperties(mime, {
                    type: { value: mt.type, enumerable: true },
                    suffixes: { value: mt.suffixes, enumerable: true },
                    description: { value: mt.description, enumerable: true },
                    enabledPlugin: { value: plugin, enumerable: true }
                });
                plugin[i] = mime;
                plugin[mt.type] = mime;
            });
            return plugin;
        }

        const pdfPlugin = fakePlugin(
            'PDF Viewer', 'internal-pdf-viewer', 'Portable Document Format',
            [{ type: 'application/pdf', suffixes: 'pdf', description: 'Portable Document Format' },
             { type: 'text/pdf', suffixes: 'pdf', description: 'Portable Document Format' }]
        );
        const chromePdfPlugin = fakePlugin(
            'Chrome PDF Viewer', 'internal-pdf-viewer', 'Portable Document Format',
            [{ type: 'application/pdf', suffixes: 'pdf', description: 'Portable Document Format' }]
        );
        const plugins = [pdfPlugin, chromePdfPlugin];
        const pluginArray = Object.create(PluginArray.prototype);
        plugins.forEach((p, i) => {
            pluginArray[i] = p;
            pluginArray[p.name] = p;
        });
        Object.defineProperty(pluginArray, 'length', { value: plugins.length, enumerable: true });
        Object.defineProperty(navigator, 'plugins', { get: () => pluginArray, enumerable: true });
    } catch (e) {}

    // 4. Realistic languages and device specs
    try {
        Object.defineProperty(navigator, 'languages', {
            get: () => ['en-US', 'en'],
            enumerable: true
        });
        if (!navigator.hardwareConcurrency || navigator.hardwareConcurrency < 2) {
            Object.defineProperty(navigator, 'hardwareConcurrency', { get: () => 8, enumerable: true });
        }
        if (!navigator.deviceMemory || navigator.deviceMemory < 2) {
            Object.defineProperty(navigator, 'deviceMemory', { get: () => 8, enumerable: true });
        }
    } catch (e) {}

    // 5. Realistic permissions status
    try {
        const originalQuery = window.navigator.permissions.query;
        window.navigator.permissions.query = (parameters) => (
            parameters && parameters.name === 'notifications' ?
                Promise.resolve({ state: Notification.permission === 'granted' ? 'granted' : 'prompt' }) :
                originalQuery(parameters)
        );
    } catch (e) {}

    // 6. WebGL Vendor & Renderer spoofing (avoid SwiftShader / llvmpipe)
    try {
        const getParameter = WebGLRenderingContext.prototype.getParameter;
        WebGLRenderingContext.prototype.getParameter = function(parameter) {
            if (parameter === 37445) return 'Google Inc. (NVIDIA)';
            if (parameter === 37446) return 'ANGLE (NVIDIA, NVIDIA GeForce RTX 3060 Direct3D11 vs_5_0 ps_5_0, D3D11)';
            return getParameter.apply(this, [parameter]);
        };
        if (typeof WebGL2RenderingContext !== 'undefined') {
            const getParameter2 = WebGL2RenderingContext.prototype.getParameter;
            WebGL2RenderingContext.prototype.getParameter = function(parameter) {
                if (parameter === 37445) return 'Google Inc. (NVIDIA)';
                if (parameter === 37446) return 'ANGLE (NVIDIA, NVIDIA GeForce RTX 3060 Direct3D11 vs_5_0 ps_5_0, D3D11)';
                return getParameter2.apply(this, [parameter]);
            };
        }
    } catch (e) {}
})();
"""


async def _check_and_handle_turnstile(page, log: list[str], timeout_sec: int = 5) -> bool:
    """Detect Cloudflare Turnstile widget, attempt interaction, and check challenge status."""
    try:
        turnstile_frame = page.locator('iframe[src*="challenges.cloudflare.com"], div[class*="cf-turnstile"]')
        if await turnstile_frame.count() > 0:
            log.append("[Engine] 🛡 Cloudflare Turnstile challenge detected on page")

            # Check if token is already solved
            token_input = page.locator('input[name="cf-turnstile-response"]')
            for _ in range(3):
                if await token_input.count() > 0:
                    val = await token_input.first.input_value()
                    if val and len(val) > 10:
                        log.append("[Engine] ✓ Cloudflare Turnstile challenge verified automatically")
                        return True
                await asyncio.sleep(0.5)

            # If not solved, try clicking interactive checkbox if present in Turnstile iframe
            try:
                cf_iframe = page.frame_locator('iframe[src*="challenges.cloudflare.com"]')
                checkbox = cf_iframe.locator('input[type="checkbox"], #cf-stage, .ctp-checkbox-label, div[role="checkbox"]')
                if await checkbox.count() > 0:
                    log.append("[Engine] 🖱 Clicking Cloudflare Turnstile challenge checkbox...")
                    await checkbox.first.click()
                    await asyncio.sleep(1.0)
            except Exception:
                pass

            # Wait for response token
            for _ in range(timeout_sec * 2):
                if await token_input.count() > 0:
                    val = await token_input.first.input_value()
                    if val and len(val) > 10:
                        log.append("[Engine] ✓ Cloudflare Turnstile challenge verified successfully")
                        return True
                await asyncio.sleep(0.5)

            log.append("[Engine] ⚠ Turnstile challenge pending — manual solve required if headful")
            return False
    except Exception:
        pass
    return False


async def _run_auto_apply_async(
    job_url: str,
    job_title: str = "",
    job_company: str = "",
    job_description: str = "",
    resume_text: str = "",
    profile: CandidateProfile | None = None,
    headless: bool = True,
) -> ApplyResult:
    """
    Internal async implementation of the auto-apply pipeline.
    
    1. Loads candidate profile
    2. Detects ATS type
    3. Launches Playwright stealth browser
    4. Fills the application form
    5. Takes a verification screenshot
    6. Returns result (does NOT submit)
    """
    start_time = time.time()
    log: list[str] = []
    ats_type = detect_ats_type(job_url)
    log.append(f"[Engine] Detected ATS: {ats_type.value}")
    log.append(f"[Engine] Target URL: {job_url}")

    # Load profile
    if profile is None:
        profile = load_profile()

    if not profile.is_configured:
        return ApplyResult(
            success=False,
            ats_type=ats_type.value,
            job_url=job_url,
            log=log,
            error="Candidate profile not configured. Fill out backend/candidate_profile.yaml first.",
        )

    log.append(f"[Engine] Profile loaded: {profile.full_name} ({profile.email})")

    profile_dict = profile.to_form_dict()
    resume_path = profile.resume_path if profile.has_resume else ""
    custom_answers = profile.custom_answers

    # Screenshot directory
    screenshot_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "apply_screenshots")
    os.makedirs(screenshot_dir, exist_ok=True)
    timestamp = int(time.time())
    screenshot_path = os.path.join(
        screenshot_dir, f"apply_{ats_type.value}_{timestamp}.png"
    )

    try:
        from playwright.async_api import async_playwright

        log.append("[Engine] Launching stealth browser...")

        async with async_playwright() as p:
            # Launch with robust anti-bot flags to defeat Turnstile and ATS fingerprinting
            browser = await p.chromium.launch(
                headless=headless,
                args=[
                    "--disable-blink-features=AutomationControlled",
                    "--disable-infobars",
                    "--disable-features=IsolateOrigins,site-per-process",
                    "--no-sandbox",
                    "--disable-dev-shm-usage",
                    "--no-default-browser-check",
                    "--lang=en-US,en",
                    "--window-size=1440,900",
                ],
            )

            context = await browser.new_context(
                viewport={"width": 1440, "height": 900},
                user_agent=(
                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                    "AppleWebKit/537.36 (KHTML, like Gecko) "
                    "Chrome/131.0.0.0 Safari/537.36"
                ),
                locale="en-US",
                timezone_id="America/New_York",
            )

            # Inject comprehensive stealth evasion script before any page scripts execute
            await context.add_init_script(STEALTH_EVASION_SCRIPT)

            page = await context.new_page()

            # Navigate to the job URL
            log.append(f"[Engine] Navigating to {job_url}...")
            try:
                await page.goto(job_url, wait_until="domcontentloaded", timeout=25000)
                try:
                    await page.wait_for_load_state("networkidle", timeout=5000)
                except Exception:
                    pass
            except Exception as nav_err:
                log.append(f"[Engine] Navigation notice: {nav_err}; continuing form detection...")
            log.append(f"[Engine] Page loaded: {await page.title()}")

            # Check for Cloudflare Turnstile bot challenges
            await _check_and_handle_turnstile(page, log)

            # Route to the appropriate ATS driver
            if ats_type == ATSType.GREENHOUSE:
                from .greenhouse import fill_greenhouse_form
                await fill_greenhouse_form(
                    page, profile_dict, resume_path,
                    job_title, job_company, job_description,
                    resume_text, custom_answers, log,
                )
            elif ats_type == ATSType.LEVER:
                from .lever import fill_lever_form
                await fill_lever_form(
                    page, profile_dict, resume_path,
                    job_title, job_company, job_description,
                    resume_text, custom_answers, log,
                )
            elif ats_type == ATSType.ASHBY:
                from .ashby import fill_ashby_form
                await fill_ashby_form(
                    page, profile_dict, resume_path,
                    job_title, job_company, job_description,
                    resume_text, custom_answers, log,
                )
            else:
                from .generic import fill_generic_form
                await fill_generic_form(
                    page, profile_dict, resume_path,
                    job_title, job_company, job_description,
                    resume_text, custom_answers, log,
                )

            # Take verification screenshot
            log.append("[Engine] Taking verification screenshot...")
            await page.screenshot(path=screenshot_path, full_page=True)
            log.append(f"[Engine] Screenshot saved: {screenshot_path}")

            # Count filled fields for reporting (accurately treating radio buttons and checkboxes)
            filled_count = await page.evaluate("""
                () => {
                    let count = 0;
                    document.querySelectorAll('input, textarea, select').forEach(el => {
                        if (el.type === 'radio' || el.type === 'checkbox') {
                            if (el.checked) count++;
                        } else if (el.value && el.value.trim()) {
                            count++;
                        }
                    });
                    return count;
                }
            """)

            await browser.close()

            duration = time.time() - start_time
            log.append(f"[Engine] ✓ Auto-apply complete in {duration:.1f}s — {filled_count} fields filled")
            log.append("[Engine] ⚠ Form is filled but NOT submitted — review and submit manually")

            return ApplyResult(
                success=True,
                ats_type=ats_type.value,
                job_url=job_url,
                screenshot_path=screenshot_path,
                log=log,
                fields_filled=filled_count,
                duration_seconds=duration,
            )

    except ImportError:
        log.append("[Engine] ERROR: Playwright not installed. Run: pip install playwright && playwright install chromium")
        return ApplyResult(
            success=False,
            ats_type=ats_type.value,
            job_url=job_url,
            log=log,
            error="Playwright not installed. Run: pip install playwright && python -m playwright install chromium",
            duration_seconds=time.time() - start_time,
        )
    except Exception as e:
        log.append(f"[Engine] ERROR: {str(e)}")
        return ApplyResult(
            success=False,
            ats_type=ats_type.value,
            job_url=job_url,
            log=log,
            error=str(e),
            duration_seconds=time.time() - start_time,
        )


def run_auto_apply(
    job_url: str,
    job_title: str = "",
    job_company: str = "",
    job_description: str = "",
    resume_text: str = "",
    profile: CandidateProfile | None = None,
    headless: bool = True,
) -> ApplyResult:
    """
    Synchronous wrapper for the auto-apply engine.
    
    Launches a Playwright browser, navigates to the job URL,
    detects the ATS, fills the form, and returns the result.
    
    DOES NOT SUBMIT — user always reviews first.
    """
    return asyncio.run(
        _run_auto_apply_async(
            job_url=job_url,
            job_title=job_title,
            job_company=job_company,
            job_description=job_description,
            resume_text=resume_text,
            profile=profile,
            headless=headless,
        )
    )


# ── CLI Entry Point ──
if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="JOB SeArCh Auto-Apply Engine")
    parser.add_argument("--url", required=True, help="Job application URL")
    parser.add_argument("--title", default="", help="Job title")
    parser.add_argument("--company", default="", help="Company name")
    parser.add_argument("--visible", action="store_true", help="Show browser (non-headless)")
    args = parser.parse_args()

    result = run_auto_apply(
        job_url=args.url,
        job_title=args.title,
        job_company=args.company,
        headless=not args.visible,
    )

    print("\n" + "=" * 60)
    print("🚀 AUTO-APPLY RESULT")
    print("=" * 60)
    print(f"Status:    {'✓ Success' if result.success else '✗ Failed'}")
    print(f"ATS Type:  {result.ats_type}")
    print(f"Fields:    {result.fields_filled} filled")
    print(f"Duration:  {result.duration_seconds}s")
    if result.screenshot_path:
        print(f"Screenshot: {result.screenshot_path}")
    if result.error:
        print(f"Error:     {result.error}")
    print("\n── Log ──")
    for line in result.log:
        print(f"  {line}")
    print("=" * 60)
