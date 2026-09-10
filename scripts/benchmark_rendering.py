"""Render a deterministic synthetic schema and report local measurements as JSON."""

import argparse
import json
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tables", type=int, required=True)
    args = parser.parse_args()
    if args.tables < 1:
        parser.error("--tables must be positive")
    root = Path(__file__).resolve().parents[1]
    directory = root / "generated" / f"benchmark-{args.tables}"
    migrations = directory / "migrations"
    migrations.mkdir(parents=True, exist_ok=True)
    statements = []
    for number in range(args.tables):
        extra = ""
        if number:
            extra = (
                f", parent_id BIGINT REFERENCES bench.t{number - 1:04d}(id)"
                f", owner_id BIGINT REFERENCES bench.t{number // 7:04d}(id)"
            )
        statements.append(
            f"CREATE TABLE bench.t{number:04d} (id BIGINT PRIMARY KEY, name TEXT, status INT, created_at TIMESTAMPTZ{extra});"
        )
    (migrations / "V1__synthetic.sql").write_text(
        "\n".join(statements), encoding="utf-8"
    )
    source = directory / "schema.d2"
    started = time.monotonic()
    subprocess.run(
        [
            sys.executable,
            "-m",
            "erd_generator",
            "--migrations",
            str(migrations),
            "--out",
            str(source),
            "--show-types",
            "--render",
            "svg",
        ],
        cwd=root,
        check=True,
        capture_output=True,
        text=True,
        timeout=180,
    )
    elapsed = time.monotonic() - started
    svg = source.with_suffix(".svg")
    rendered = ET.parse(svg).getroot()
    labels = {
        "".join(e.itertext()) for e in rendered.iter("{http://www.w3.org/2000/svg}text")
    }
    assert {f"bench.t{i:04d}" for i in range(args.tables)} <= labels
    peak = None
    if sys.platform in ("darwin", "linux"):
        import resource

        usage = resource.getrusage(resource.RUSAGE_CHILDREN)
        peak = usage.ru_maxrss / (1024 * 1024 if sys.platform == "darwin" else 1024)
    report = {
        "tables": args.tables,
        "columns": 4 + 6 * (args.tables - 1),
        "foreign_keys": 2 * (args.tables - 1),
        "elapsed_seconds": round(elapsed, 3),
        "peak_child_rss_mib": round(peak, 1) if peak is not None else None,
        "svg_bytes": svg.stat().st_size,
        "viewBox": rendered.attrib.get("viewBox"),
    }
    (directory / "metrics.json").write_text(
        json.dumps(report, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(report))


if __name__ == "__main__":
    main()
