#!/usr/bin/env python3
"""Convert a Macaulay2 list file (.m2) containing a single top-level list
into a Julia file (.jl) that assigns the list to a variable.

Specifically converts symbols like `v_{1, 2, 3}` into `v[1,2,3]` and
turns the surrounding `{ ... }` into a Julia array `[ ... ]`.

Usage: python3 scripts/convert_m2_to_jl.py
"""
import re
from pathlib import Path


def convert_m2_to_julia(content: str, varname: str) -> str:
    # Find the outermost braces containing the list
    start = content.find("{")
    end = content.rfind("}")
    if start == -1 or end == -1 or end <= start:
        raise ValueError("Could not find a top-level {...} list in input")

    inner = content[start+1:end]

    # Replace symbols like v_{1, 2, 3} -> v[1,2,3]
    pattern = re.compile(r"([A-Za-z_]\w*)_\{([^}]+)\}")

    def idx_repl(m: re.Match) -> str:
        name = m.group(1)
        idx = m.group(2)
        # remove spaces after commas in indices
        idx = ",".join([p.strip() for p in idx.split(",")])
        return f"{name}[{idx}]"

    inner = pattern.sub(idx_repl, inner)

    # Clean up some spacing: remove again any ", " -> "," globally (safe for our use)
    inner = inner.replace(", ", ",")

    # Wrap in a Julia assignment using the provided variable name
    julia = "[" + inner + "]\n"
    return julia


def sanitize_varname(name: str) -> str:
    # Make a safe Julia variable name from the file stem
    var = re.sub(r"[^0-9A-Za-z_]", "_", name)
    if re.match(r"^[0-9]", var):
        var = "x_" + var
    return var


def main():
    repo_root = Path(__file__).resolve().parents[1]
    cache_dir = repo_root / "cache"
    if not cache_dir.exists():
        print(f"Cache directory not found: {cache_dir}")
        return 2

    m2_files = sorted(cache_dir.glob("*.m2"))
    if not m2_files:
        print(f"No .m2 files found in {cache_dir}")
        return 0

    for in_path in m2_files:
        stem = in_path.stem
        varname = sanitize_varname(stem)
        out_path = cache_dir / f"{stem}.jl"
        content = in_path.read_text()
        try:
            julia = convert_m2_to_julia(content, varname)
        except Exception as e:
            print(f"Conversion failed for {in_path}: {e}")
            continue
        out_path.write_text(julia)
        print(f"Wrote Julia file to: {out_path}")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
