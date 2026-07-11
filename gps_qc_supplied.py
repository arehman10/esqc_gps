name: Validate Stata net-install package

on:
  push:
    branches: [main]
  pull_request:

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Check required root files and package manifest
        shell: python
        run: |
          from pathlib import Path
          import re

          required = [
              "stata.toc",
              "esqc_gps.pkg",
              "esqc_gps.ado",
              "esqc_gps.sthlp",
              "esqc_gps.jar",
              "esqc_gps_log.ado",
              "esqc_gps_log.sthlp",
          ]
          missing = [name for name in required if not Path(name).is_file()]
          if missing:
              raise SystemExit("Missing required repository-root files: " + ", ".join(missing))

          pkg = Path("esqc_gps.pkg").read_text(encoding="utf-8")
          toc = Path("stata.toc").read_text(encoding="utf-8")
          if not pkg.startswith("v 3"):
              raise SystemExit("esqc_gps.pkg does not start with 'v 3'")
          if not toc.startswith("v 3"):
              raise SystemExit("stata.toc does not start with 'v 3'")

          listed = re.findall(r"^f\s+(.+?)\s*$", pkg, flags=re.M)
          expected = [
              "esqc_gps.ado",
              "esqc_gps.sthlp",
              "esqc_gps.jar",
              "esqc_gps_log.ado",
              "esqc_gps_log.sthlp",
          ]
          if listed != expected:
              raise SystemExit(f"Unexpected package file list: {listed!r}")
          absent = [name for name in listed if not Path(name).is_file()]
          if absent:
              raise SystemExit("Package references missing files: " + ", ".join(absent))

          print("Stata package layout is valid.")
