#!/usr/bin/env python3
"""MCP integration wrapper for PDF → City of Thought JSON.
Этот скрипт вызывается из Godot через OS.execute() или из Hermes MCP.

Usage (from Hermes): python3 /path/to/pdf_city_mcp.py --pdf PATH [--author NAME] [--title TITLE]
Output: stdout = JSON string для city_manager.load_from_json()

Usage (from Godot):
    var output = []
    var code = OS.execute("python3", ["tools/pdf_city_mcp.py", "--pdf", pdf_path], output, true)
    var json = JSON.new()
    json.parse(output[0])
"""

import sys, os, subprocess, json, argparse

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PDF_SCRIPT = os.path.join(SCRIPT_DIR, "pdf_to_preset.py")


def run_pdf_analysis(pdf_path: str, author: str = "Unknown", title: str = "", year: int = 1900) -> dict:
    """Запускает pdf_to_preset.py и возвращает JSON"""
    cmd = [
        "python3", PDF_SCRIPT,
        pdf_path,
        "--author", author,
        "--title", title if title else os.path.basename(pdf_path).replace(".pdf", ""),
        "--year", str(year),
        "-o", "/tmp/city_preset_tmp.json"
    ]
    
    r = subprocess.run(cmd, capture_output=True, text=True)
    
    if r.stderr:
        print(f"[MCP-LOG] {r.stderr.strip()}", file=sys.stderr)
    
    if os.path.exists("/tmp/city_preset_tmp.json"):
        with open("/tmp/city_preset_tmp.json", "r") as f:
            return json.load(f)
    
    return {"error": "Failed to generate preset", "stderr": r.stderr}


def main():
    parser = argparse.ArgumentParser(description="MCP: PDF book → City preset")
    parser.add_argument("--pdf", required=True, help="Path to PDF")
    parser.add_argument("--author", default="Unknown")
    parser.add_argument("--title", default="")
    parser.add_argument("--year", type=int, default=1900)
    args = parser.parse_args()
    
    result = run_pdf_analysis(args.pdf, args.author, args.title, args.year)
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
