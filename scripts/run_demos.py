"""Run the checked-in fictional scenarios through the public CLI and build a gallery."""

import argparse
import html
import json
import shlex
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NS = "{http://www.w3.org/2000/svg}"


def run_case(case, output, executable, *, seed=None):
    directory = output / case["id"]
    directory.mkdir(parents=True, exist_ok=True)
    source, svg = directory / "schema.d2", directory / "schema.svg"
    if seed is not None:
        source.write_bytes(seed[0])
        svg.write_bytes(seed[1])
    command = [
        sys.executable,
        "-m",
        "erd_generator",
        "--migrations",
        str(ROOT / case["migrations"]),
        "--out",
        str(source),
        "--log-dir",
        str(directory),
        "--render",
        "svg",
        "--d2-binary",
        executable,
    ]
    if case.get("fk_config"):
        command.extend(["--fk-config", str(ROOT / case["fk_config"])])
    command.extend(case.get("args", []))
    (directory / "command.txt").write_text(shlex.join(command) + "\n", encoding="utf-8")
    started = time.monotonic()
    try:
        process = subprocess.run(
            command, cwd=ROOT, capture_output=True, text=True, timeout=390
        )
        code, stdout, stderr = process.returncode, process.stdout, process.stderr
    except subprocess.TimeoutExpired:
        code, stdout, stderr = -1, "", "Demo CLI exceeded its total 390-second budget."
    (directory / "console.log").write_text(stdout + stderr, encoding="utf-8")
    expected_exit = case.get("exit_code", 0)
    result = {
        "id": case["id"],
        "title": case["title"],
        "kind": "expected failure" if expected_exit else "render",
        "expected_exit": expected_exit,
        "actual_exit": code,
        "elapsed_seconds": round(time.monotonic() - started, 3),
        "passed": code == expected_exit,
        "detail": "",
    }
    if case.get("visual_note"):
        result["visual_note"] = case["visual_note"]
    if expected_exit:
        source_bytes = source.read_bytes() if source.is_file() else b""
        svg_bytes = svg.read_bytes() if svg.is_file() else b""
        result["source_preserved"] = seed is not None and source_bytes == seed[0]
        result["svg_preserved"] = seed is not None and svg_bytes == seed[1]
        result["diagnostic_matched"] = case["error"] in stderr
        source_ok = result["source_preserved"]
        if case["id"] == "missing_renderer":
            source_ok = (
                bool(source_bytes)
                and not result["source_preserved"]
                and b"shape: sql_table" in source_bytes
                and "SVG was not updated" in stderr
            )
        result["passed"] &= (
            result["svg_preserved"] and source_ok and result["diagnostic_matched"]
        )
        result["detail"] = case["error"]
    elif code == 0:
        try:
            image = ET.parse(svg).getroot()
            labels = {"".join(e.itertext()) for e in image.iter(NS + "text")}
            required = set(case["tables"]) | set(case.get("labels", []))
            missing = required - labels
            retired = set(case.get("absent_labels", [])) & labels
            result["passed"] &= image.tag == NS + "svg" and not missing and not retired
            result["table_count"] = len(case["tables"])
            result["svg_bytes"] = svg.stat().st_size
            result["viewBox"] = image.get("viewBox")
            if missing or retired:
                result["detail"] = (
                    f"SVG label check failed: missing={sorted(missing)!r}, retired={sorted(retired)!r}"
                )
        except (OSError, ET.ParseError) as exc:
            result["passed"] = False
            result["detail"] = f"SVG verification failed: {exc}"
    else:
        result["detail"] = "CLI failed; inspect console.log."
    print(
        f"{'PASS' if result['passed'] else 'FAIL'} {case['id']}: exit={code}, {result['elapsed_seconds']:.3f}s",
        flush=True,
    )
    return result


def write_gallery(output, cases, report):
    escape = html.escape
    definitions = {case["id"]: case for case in cases}
    cards, errors = [], []
    for result in report:
        key = result["id"]
        title = escape(result["title"])
        status = "通过" if result["passed"] else "未通过"
        links = f'<a href="{key}/command.txt">实际命令</a> · <a href="{key}/console.log">运行日志</a>'
        if result["kind"] == "expected failure":
            preserved = (
                "原有 SVG 保留" if result.get("svg_preserved") else "产物保护未通过"
            )
            source = (
                "源码已更新"
                if result.get("source_preserved") is False
                else "原有源码保留"
            )
            errors.append(
                f"<tr><td>{title}</td><td>{result['expected_exit']} / {result['actual_exit']}</td>"
                f"<td>{status}；{preserved}；{source}</td><td>{links}</td></tr>"
            )
            continue
        case = definitions[key]
        if result["passed"]:
            links = f'<a href="{key}/schema.svg">打开 SVG 原图</a> · <a href="{key}/schema.d2">D2 源码</a> · {links}'
        visual_note = (
            f'<p class="layout-note">{escape(case["visual_note"])}</p>'
            if case.get("visual_note")
            else ""
        )
        image = (
            f'<a href="{key}/schema.svg"><img src="{key}/schema.svg" alt="{title} ER 图" loading="lazy"></a>'
            if result["passed"]
            else f'<p class="failed">{escape(result["detail"])}</p>'
        )
        cards.append(
            f'<article id="{key}"><h2>{title}</h2><p>{escape(case["description"])}</p>'
            f"<p>自动检查{status} · {result['elapsed_seconds']:.3f}s · {links}</p>"
            f"{visual_note}{image}</article>"
        )
    passed = sum(result["passed"] for result in report)
    failures = (
        "<article><h2>预期拒绝（expected failure）</h2>"
        "<p>先复制本轮成功生成的图，再执行错误命令。只有退出码、诊断和产物保护都符合预期才记为通过。"
        "这些目录里的旧 SVG 不能当作本次生成结果。</p>"
        '<div class="table"><table><thead><tr><th>场景</th><th>预期 / 实际退出码</th><th>核验</th><th>证据</th></tr></thead>'
        f"<tbody>{''.join(errors)}</tbody></table></div></article>"
        if errors
        else ""
    )
    page = f"""<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>D2 + ELK 场景演示</title><style>
body{{margin:0;background:#f2f5f9;color:#15253b;font:16px/1.65 system-ui,sans-serif}}
main{{max-width:1240px;margin:auto;padding:24px}}h1,h2{{line-height:1.3}}h1{{font-size:32px}}
article{{background:white;border:1px solid #d6dfeb;border-radius:12px;margin:24px 0;padding:24px}}
a{{color:#1757a3;text-underline-offset:3px}}img{{display:block;width:100%;height:520px;object-fit:contain;background:#fff}}
table{{border-collapse:collapse;width:100%;text-align:left}}td,th{{padding:12px;border-bottom:1px solid #d6dfeb}}
.table{{overflow:auto}}.failed{{color:#a11c2e}}code{{background:#e8eef5;padding:2px 5px}}
.layout-note{{padding:12px;background:#fff5dc;border-left:4px solid #9a6500}}
@media(max-width:600px){{main{{padding:12px}}article{{padding:14px}}img{{height:340px}}}}
</style></head><body><main><h1>D2 + ELK 场景演示</h1>
<p>本轮自动核验：{passed} / {len(report)} 通过；不等同于视觉验收。输入均为虚构业务，不连接数据库。</p>
<p>点击原图后可放大查看字段连线；仅用缩略图无法判断复杂图的可读性。<a href="report.json">查看机器可读报告</a></p>
{"".join(cards)}{failures}
</main></body></html>
"""
    (output / "index.html").write_text(page, encoding="utf-8")
    (output / "report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


def main():
    catalog = json.loads((ROOT / "examples/scenarios.json").read_text(encoding="utf-8"))
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "generated/demos")
    parser.add_argument(
        "--case", choices=["all", *(c["id"] for c in catalog["success"])], default="all"
    )
    parser.add_argument("--d2-binary", default="d2")
    args = parser.parse_args()
    output = args.output.expanduser().resolve()
    output.mkdir(parents=True, exist_ok=True)
    cases = [c for c in catalog["success"] if args.case in ("all", c["id"])]
    report, seed = [], None
    for case in cases:
        result = run_case(case, output, args.d2_binary)
        report.append(result)
        if result["passed"] and seed is None:
            directory = output / case["id"]
            seed = (
                (directory / "schema.d2").read_bytes(),
                (directory / "schema.svg").read_bytes(),
            )
    if args.case == "all":
        if seed is None:
            print(
                "Failure demonstrations require a successful fresh render; no previous files will be used.",
                file=sys.stderr,
            )
        else:
            for case in catalog["failure"]:
                report.append(run_case(case, output, args.d2_binary, seed=seed))
    write_gallery(output, cases, report)
    print(f"Gallery written to {output / 'index.html'}")
    return 0 if all(result["passed"] for result in report) else 1


if __name__ == "__main__":
    raise SystemExit(main())
