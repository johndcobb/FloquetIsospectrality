import re
from pathlib import Path

CACHE = Path(__file__).resolve().parent.parent / "cache"

def sanitize_varname(name):
    s = re.sub(r'\W+', '_', name)
    if re.match(r'^\d', s):
        s = "x_" + s
    return s

def find_outer_brace_content(text):
    i = text.find('{')
    if i == -1:
        return None
    depth = 0
    for j in range(i, len(text)):
        if text[j] == '{':
            depth += 1
        elif text[j] == '}':
            depth -= 1
            if depth == 0:
                return text[i+1:j]
    return None

def split_top_level_items(s):
    items = []
    buf = []
    depth = 0
    # Track braces, parens, brackets
    pairs = {'{': '}', '(': ')', '[': ']'}
    closers = set(pairs.values())
    opens = set(pairs.keys())
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

# pattern for name_{...}
idx_re = re.compile(r'([A-Za-z]\w*)_\{\s*([^\}]*)\s*}')
# pattern for name_1 or name_1,2 (digits, optional comma-separated)
numidx_re = re.compile(r'([A-Za-z]\w*)_\s*([0-9]+(?:\s*,\s*[0-9]+)*)')


def convert_indices(expr):
    # Convert name_{a,b,...} -> name[a,b,...]
    out = idx_re.sub(r'\1[\2]', expr)
    # Convert name_1 or name_1,2 -> name[1] or name[1,2]
    # Apply after brace-style conversion to avoid double-replacing.
    def num_repl(m: re.Match) -> str:
        name = m.group(1)
        idxs = m.group(2)
        # normalize commas and whitespace
        idxs = ",".join([p.strip() for p in idxs.split(",")])
        return f"{name}[{idxs}]"

    out = numidx_re.sub(num_repl, out)
    return out

def convert_file(m2path, jlpath):
    text = m2path.read_text()
    content = find_outer_brace_content(text)
    if content is None:
        print(f"no top-level {{...}} found in {m2path.name}; skipping")
        return
    items = split_top_level_items(content)
    varname = sanitize_varname(m2path.stem)
    lines = []
    lines.append(f"# generated from {m2path.name}")
    lines.append(f"{varname} = Any[]")
    tmp_counter = 0
    # helper: split top-level + terms (not inside parentheses/brackets)
    def split_top_level_plus(s: str):
        parts = []
        buf = []
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
            if ch == '+' and not stack:
                part = ''.join(buf).strip()
                parts.append(part)
                buf = []
            else:
                buf.append(ch)
        last = ''.join(buf).strip()
        if last:
            parts.append(last)
        return parts

    CHUNK_SIZE = 60  # max number of '+' terms per chunk; tune if needed

    for it in items:
        it2 = convert_indices(it)
        # If the expression is a large sum, break into chunks and build with tmp var
        terms = split_top_level_plus(it2)
        if len(terms) <= CHUNK_SIZE:
            lines.append(f"push!({varname}, {it2})")
        else:
            # build chunk expressions
            chunks = ["+".join(terms[i:i+CHUNK_SIZE]) for i in range(0, len(terms), CHUNK_SIZE)]
            tmp_var = f"_expr{tmp_counter}"
            tmp_counter += 1
            # initialize tmp with first chunk
            lines.append(f"{tmp_var} = {chunks[0]}")
            for c in chunks[1:]:
                lines.append(f"{tmp_var} += ({c})")
            lines.append(f"push!({varname}, {tmp_var})")
    jlpath.write_text("\n".join(lines) + "\n")
    print(f"wrote {jlpath} ({len(items)} items)")

def main():
    CACHE.mkdir(parents=True, exist_ok=True)
    for m2 in sorted(CACHE.glob("*.m2")):
        jl = m2.with_suffix(".jl")
        convert_file(m2, jl)

if __name__ == "__main__":
    main()