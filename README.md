# node-package-scanner

A Windows batch script to scan directories for Node.js packages and check if installed modules match a CSV list of known compromised npm packages (e.g., with worms or malware). Results are written to a log file for review.

## Features
- Recursively scans user-defined folders for `node_modules` directories
- Compares installed packages against a CSV of compromised npm packages
- Reports matches, version mismatches, and critical findings
- Outputs a detailed summary and warnings to a result file

## Usage
1. Edit `roots.txt` to specify which folders to scan (one path per line).
2. Place your CSV of compromised packages as `packages.csv` (see credits below).
3. Run `search.bat`.
4. Review `found_packages.txt` for results.

## Disclaimer
This tool is for private use by PixoVoid (https://PixoVoid.dev). Use at your own risk. Never trust or run code from the internet without reviewing it yourself. No warranty or guarantee of correctness is provided. The author accepts no liability for any damages or issues arising from use.

## Credits
The CSV of compromised npm packages was downloaded from:
https://www.koi.ai/incident/live-updates-sha1-hulud-the-second-coming-hundred-npm-packages-compromised
on 25.11.2025 at 13:00 CET.

Please give credit to the source above if you use or share this project.
