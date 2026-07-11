from __future__ import annotations

import os
import shutil
import subprocess
import sys
import zipfile
import tempfile
import unittest
from pathlib import Path

from .test_worker import write_layer

ROOT = Path(__file__).resolve().parents[1]
JAVA_SOURCE = ROOT / "src" / "org" / "worldbank" / "esqc" / "GpsSfi.java"
JAVA_RUNTIME = ROOT / "tests" / "java_runtime"
WORKER = ROOT / "resources" / "gps_qc.py"
JAR = ROOT / "esqc_gps.jar"
BUILD_SCRIPT = ROOT / "tools" / "build_jar.py"


class JavaBridgeTests(unittest.TestCase):
    def test_java11_bridge_runs_worker_and_publishes_strict_results(self) -> None:
        if shutil.which("javac") is None or shutil.which("java") is None:
            self.skipTest("JDK is not installed")
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            classes = root / "classes"
            classes.mkdir()
            sources = [
                JAVA_RUNTIME / "com" / "stata" / "sfi" / "Data.java",
                JAVA_RUNTIME / "com" / "stata" / "sfi" / "Missing.java",
                JAVA_RUNTIME / "com" / "stata" / "sfi" / "SFIToolkit.java",
                JAVA_SOURCE,
                JAVA_RUNTIME / "Harness.java",
            ]
            compile_result = subprocess.run(
                ["javac", "--release", "11", "-d", str(classes), *map(str, sources)],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
                timeout=90,
            )
            self.assertEqual(compile_result.returncode, 0, compile_result.stderr)

            class_file = classes / "org" / "worldbank" / "esqc" / "GpsSfi.class"
            raw = class_file.read_bytes()
            self.assertEqual(int.from_bytes(raw[6:8], "big"), 55)  # Java 11 class-file major version

            shp = write_layer(root / "shape")
            config = root / "bridge.tsv"
            values = {
                "shapefile": str(shp),
                "country": "Testland",
                "ai": "false",
                "keyfile": "",
                "model": "gpt-5.6-luna",
                "vision": "false",
                "websearch": "false",
                "basemap": "osm",
                "reasoning": "medium",
                "batchsize": "10",
                "timeout": "120",
                "python": sys.executable,
                "worker": str(WORKER),
                "cache": "",
                "mapgeojson": "",
                "maphtml": "",
                "ailog": "",
                "ailogpayload": "false",
                "rerun": "false",
                "snaptolerance": "0",
                "assumewgs84": "false",
                "countryfield": "NAM_0",
                "admin1field": "NAM_1",
                "admin2field": "NAM_2",
                "keepfiles": "false",
                "verbose": "true",
            }
            config.write_text("".join(f"{key}\t{value}\n" for key, value in values.items()), encoding="utf-8")
            run = subprocess.run(
                ["java", "-cp", str(classes), "Harness", str(config)],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
                timeout=180,
            )
            self.assertEqual(run.returncode, 0, run.stderr + run.stdout)
            self.assertIn("RC=0", run.stdout)
            self.assertIn("STATUS1=ok", run.stdout)
            self.assertIn("FLAG1=0.0", run.stdout)
            self.assertIn("ADMIN1_1=North", run.stdout)
            self.assertIn("ADMIN2_1=Alpha", run.stdout)
            self.assertIn("STATUS2=outside_country", run.stdout)
            self.assertIn("FLAG2=1.0", run.stdout)
            self.assertIn("esqc_gps: wrote 2 row(s)", run.stdout)

    def test_built_jar_embeds_worker_and_runs_without_external_worker(self) -> None:
        if shutil.which("javac") is None or shutil.which("java") is None:
            self.skipTest("JDK is not installed")
        build = subprocess.run(
            [sys.executable, str(BUILD_SCRIPT), "--output", str(JAR)],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
            timeout=120,
        )
        self.assertEqual(build.returncode, 0, build.stderr + build.stdout)
        with zipfile.ZipFile(JAR) as archive:
            names = archive.namelist()
            self.assertIn("resources/gps_qc.py", names)
            self.assertIn("org/worldbank/esqc/GpsSfi.class", names)
            self.assertFalse(any(name.startswith("com/stata/") for name in names))
            raw = archive.read("org/worldbank/esqc/GpsSfi.class")
            self.assertEqual(int.from_bytes(raw[6:8], "big"), 55)

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            classes = root / "classes"
            classes.mkdir()
            sources = [
                JAVA_RUNTIME / "com" / "stata" / "sfi" / "Data.java",
                JAVA_RUNTIME / "com" / "stata" / "sfi" / "Missing.java",
                JAVA_RUNTIME / "com" / "stata" / "sfi" / "SFIToolkit.java",
                JAVA_RUNTIME / "Harness.java",
            ]
            compile_result = subprocess.run(
                ["javac", "--release", "11", "-cp", str(JAR), "-d", str(classes), *map(str, sources)],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
                timeout=90,
            )
            self.assertEqual(compile_result.returncode, 0, compile_result.stderr)

            shp = write_layer(root / "shape")
            config = root / "bridge.tsv"
            values = {
                "shapefile": str(shp),
                "country": "Testland",
                "ai": "false",
                "keyfile": "",
                "model": "gpt-5.6-luna",
                "vision": "false",
                "websearch": "false",
                "basemap": "osm",
                "reasoning": "medium",
                "batchsize": "10",
                "timeout": "120",
                "python": sys.executable,
                "worker": "",
                "cache": "",
                "mapgeojson": "",
                "maphtml": "",
                "ailog": "",
                "ailogpayload": "false",
                "rerun": "false",
                "snaptolerance": "0",
                "assumewgs84": "false",
                "countryfield": "NAM_0",
                "admin1field": "NAM_1",
                "admin2field": "NAM_2",
                "keepfiles": "false",
                "verbose": "true",
            }
            config.write_text("".join(f"{key}\t{value}\n" for key, value in values.items()), encoding="utf-8")
            classpath = str(classes) + os.pathsep + str(JAR)
            run = subprocess.run(
                ["java", "-cp", classpath, "Harness", str(config)],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
                timeout=180,
            )
            self.assertEqual(run.returncode, 0, run.stderr + run.stdout)
            self.assertIn("RC=0", run.stdout)
            self.assertIn("STATUS1=ok", run.stdout)
            self.assertIn("STATUS2=outside_country", run.stdout)

    def test_java_bridge_rejects_unknown_status_without_publishing(self) -> None:
        if shutil.which("javac") is None or shutil.which("java") is None:
            self.skipTest("JDK is not installed")
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            classes = root / "classes"
            classes.mkdir()
            sources = [
                JAVA_RUNTIME / "com" / "stata" / "sfi" / "Data.java",
                JAVA_RUNTIME / "com" / "stata" / "sfi" / "Missing.java",
                JAVA_RUNTIME / "com" / "stata" / "sfi" / "SFIToolkit.java",
                JAVA_SOURCE,
                JAVA_RUNTIME / "Harness.java",
            ]
            compile_result = subprocess.run(
                ["javac", "--release", "11", "-d", str(classes), *map(str, sources)],
                text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                check=False, timeout=90,
            )
            self.assertEqual(compile_result.returncode, 0, compile_result.stderr)

            fake_worker = root / "bad_worker.py"
            fake_worker.write_text(
                """import csv, json, sys\n
with open(sys.argv[1], encoding='utf-8') as f:
    cfg = json.load(f)
header = ['row_id','tid','lat','lon','gps_status','gps_flag','predicted_admin2','predicted_admin1','a3a_status','a3x_status','detail']
rows = [
    [1,'case-1','10.50000000','10.50000000','invented_status',1,'Alpha','North','match','match','bad contract'],
    [2,'case-2','20.00000000','20.00000000','outside_country',1,'','','','','outside'],
]
with open(cfg['OUTPUT_CSV'], 'w', newline='', encoding='utf-8') as f:
    w = csv.writer(f); w.writerow(header); w.writerows(rows)
with open(cfg['SUCCESS_MARKER'], 'w', encoding='utf-8') as f:
    f.write('ESQC_GPS_OK\\tversion=1.2.0\\tschema=sfi11\\trows=2\\n')
""",
                encoding="utf-8",
            )
            shp = write_layer(root / "shape")
            config = root / "bridge.tsv"
            values = {
                "shapefile": str(shp), "country": "Testland", "ai": "false",
                "keyfile": "", "model": "gpt-5.6-luna", "vision": "false",
                "websearch": "false", "basemap": "osm", "reasoning": "medium",
                "batchsize": "10", "timeout": "120", "python": sys.executable,
                "worker": str(fake_worker), "cache": "", "mapgeojson": "",
                "maphtml": "",
                "ailog": "", "ailogpayload": "false", "rerun": "false",
                "snaptolerance": "0", "assumewgs84": "false",
                "countryfield": "NAM_0", "admin1field": "NAM_1",
                "admin2field": "NAM_2", "keepfiles": "false", "verbose": "false",
            }
            config.write_text("".join(f"{k}\t{v}\n" for k, v in values.items()), encoding="utf-8")
            run = subprocess.run(
                ["java", "-cp", str(classes), "Harness", str(config)],
                text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                check=False, timeout=180,
            )
            self.assertIn("RC=459", run.stdout)
            self.assertIn("unknown gps_status", run.stderr)
            self.assertIn("STATUS1=<missing-variable>", run.stdout)
            self.assertIn("FLAG1=<missing-variable>", run.stdout)


if __name__ == "__main__":
    unittest.main(verbosity=2)
