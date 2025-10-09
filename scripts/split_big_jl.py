import re
from pathlib import Path
import shutil

CACHE = Path(__file__).resolve().parent.parent / "cache"

def find_bracket_content(text, open_ch='[', close_ch=']'):
    i = text.find(open_ch)
    if i == -1:
        return None, None, None
    depth = 0
    for j in range(i, len(text)):
        ch = text[j]
        if ch == open_ch:
            depth += 1
        elif ch == close_ch:
            depth -= 1
            if depth == 0:
                return i, j, text[i+1:j]
    return None, None, None

def split_top_level_items(s):
    items = []
    buf = []
    # track (), [], {}
    pairs = {'{': '}', '(': ')', '[': ']'}
    opens = set(pairs.keys())
    closers = set(pairs.values())
    stack = []
    for ch in s:
        if ch in opens:
            stack.append(pairs[ch])
        elif ch in closers:
            if stack and stack[-1] == ch:
                stack.pop()
        if ch == ',' and not stack:
            item = ''.join(buf).strip()
            if item:
                items.append(item)
            buf = []
        else:
            buf.append(ch)
    last = ''.join(buf).strip()
    if last:
        items.append(last)
    return items

def process_file(path: Path):
    text = path.read_text()
    # match "name = [" at top (allow whitespace/comments before)
    m = re.search(r'^\s*([A-Za-z_]\w*)\s*=\s*\[', text, re.M)
    if not m:
        print(f"no top-level array assignment in {path.name}; skipping")
        return
    name = m.group(1)
    bstart, bend, content = find_bracket_content(text[m.start():], '[', ']')
    if content is None:
        print(f"could not find matching brackets in {path.name}; skipping")
        return
    # adjust indexes because we searched from m.start()
    bstart += m.start()
    bend += m.start()
    items = split_top_level_items(content)
    if len(items) < 1000:
        print(f"{path.name} has {len(items)} items (<1000) — rewrite may not be necessary; still rewriting")
    # backup
    bak = path.with_suffix(path.suffix + ".bak")
    shutil.copy(path, bak)
    out_lines = []
    out_lines.append(f"# generated from {path.name} (original backed up as {bak.name})")
    out_lines.append(f"{name} = Any[]")
    for it in items:
        out_lines.append(f"push!({name}, {it})")
    out_lines.append("")  # trailing newline
    path.write_text("\n".join(out_lines))
    print(f"rewrote {path.name}: {len(items)} items (backup -> {bak.name})")

def main():
    for p in sorted(CACHE.glob("*.jl")):
        # only process files larger than 1MB (adjust threshold if wanted)
        if p.stat().st_size > 1_000_000:
            process_file(p)
        else:
            print(f"skip {p.name} (size {p.stat().st_size} bytes)")

if __name__ == "__main__":
    main()