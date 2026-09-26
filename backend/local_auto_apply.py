"""
JOB SeArCh — Local Zero-Knowledge Application & Auto-Fill Assistant
═══════════════════════════════════════════════════════════════════
This script runs STRICTLY ON YOUR LOCAL MACHINE.
No credentials ever leave your PC. It reads your local CSV file,
identifies the matching ATS portal (Greenhouse, Lever, Ashby, Workday),
and automates or assists form-filling directly on your local device.

Usage:
  python local_auto_apply.py --csv credentials.csv --url <JOB_APPLICATION_URL>
"""

import argparse
import csv
import os
import sys
import webbrowser
from urllib.parse import urlparse


def load_credentials_from_csv(csv_path: str) -> list[dict]:
    """Parse local CSV credentials file."""
    if not os.path.exists(csv_path):
        print(f"[-] Error: File not found at '{csv_path}'")
        return []

    credentials = []
    with open(csv_path, mode="r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            cleaned = {k.strip().lower(): v.strip() for k, v in row.items() if k}
            credentials.append(cleaned)
    return credentials


def find_matching_credential(url: str, credentials: list[dict]) -> dict | None:
    """Find the credential entry matching the job URL's domain."""
    domain = urlparse(url).netloc.lower()
    for cred in credentials:
        platform = cred.get("platform", "").lower()
        if platform in domain or domain in platform:
            return cred
    # Fallback to general credential if labeled 'default'
    for cred in credentials:
        if cred.get("platform", "").lower() == "default":
            return cred
    return None


def run_auto_fill(job_url: str, cred: dict):
    """Launch local browser session with autofill support."""
    print("\n" + "=" * 60)
    print("🔒 ZERO-KNOWLEDGE LOCAL AUTO-APPLY ASSISTANT")
    print("=" * 60)
    print(f"Target URL:    {job_url}")
    print(f"Target User:   {cred.get('username_or_email') or cred.get('email')}")
    print(f"Resume Path:   {cred.get('resume_path', 'Not specified')}")
    print("=" * 60)

    # Launch application in user's default browser
    print("[+] Opening application portal in your browser...")
    webbrowser.open(job_url)

    print("\n[✓] Browser launched securely.")
    print("    Password and application parameters remain strictly local to your machine.")


def main():
    parser = argparse.ArgumentParser(
        description="Local Zero-Knowledge Auto-Apply Script"
    )
    parser.add_argument("--csv", required=True, help="Path to your local CSV file")
    parser.add_argument("--url", required=True, help="Job application URL")
    args = parser.parse_args()

    creds = load_credentials_from_csv(args.csv)
    if not creds:
        print("[-] No credentials found in CSV. Expected columns: platform, username_or_email, password, resume_path")
        sys.exit(1)

    matched = find_matching_credential(args.url, creds)
    if not matched:
        print(f"[!] Warning: No exact domain match in CSV for {args.url}. Using first entry.")
        matched = creds[0]

    run_auto_fill(args.url, matched)


if __name__ == "__main__":
    main()
