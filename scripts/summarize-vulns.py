#!/usr/bin/env python3
"""
Summarize vulnerabilities from a vulnxscan CSV report, focusing on Critical CVEs.
"""

import argparse
import csv
import os
import sys

def parse_args():
    parser = argparse.ArgumentParser(description="Summarize vulnxscan CSV report")
    parser.add_argument("csv_path", help="Path to vulns.csv report")
    parser.add_argument(
        "--min-severity",
        type=float,
        default=9.0,
        help="Minimum CVSS severity score to report (default: 9.0 for CRITICAL)",
    )
    return parser.parse_args()

def main():
    args = parse_args()
    if not os.path.exists(args.csv_path):
        print(f"Error: report file '{args.csv_path}' not found", file=sys.stderr)
        sys.exit(1)

    critical_findings = []
    seen = set()

    with open(args.csv_path, mode="r", encoding="utf-8", errors="replace") as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                sev = float(row.get("severity") or 0.0)
            except ValueError:
                sev = 0.0

            if sev >= args.min_severity:
                vuln_id = row.get("vuln_id", "UNKNOWN")
                package = row.get("package", "UNKNOWN")
                version = row.get("version_local", "")
                url = row.get("url", "")
                key = (vuln_id, package)
                if key not in seen:
                    seen.add(key)
                    critical_findings.append({
                        "severity": sev,
                        "vuln_id": vuln_id,
                        "package": package,
                        "version": version,
                        "url": url,
                    })

    critical_findings.sort(key=lambda x: x["severity"], reverse=True)

    header_label = "CRITICAL" if args.min_severity >= 9.0 else f"SEVERITY >= {args.min_severity}"
    print(f"\n\033[1;31m=== {header_label} Vulnerabilities (CVSS >= {args.min_severity}): {len(critical_findings)} found ===\033[0m")

    if not critical_findings:
        print("  \033[1;32m✓ No matching vulnerabilities detected!\033[0m")
    else:
        for item in critical_findings:
            sev = item["severity"]
            vid = item["vuln_id"]
            pkg = item["package"]
            ver = f"({item['version']})" if item["version"] else ""
            url = f"-> {item['url']}" if item["url"] else ""
            print(f"  \033[1;31m• [{sev:0.1f}]\033[0m \033[1m{vid}\033[0m: {pkg} {ver} {url}".strip())

if __name__ == "__main__":
    main()
