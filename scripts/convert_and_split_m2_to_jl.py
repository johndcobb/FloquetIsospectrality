
import re
import os
import argparse
import json

def convert_m2_to_jl_line(m2_line):
    """Converts a single line of Macaulay2 content to Julia syntax."""
    # First, convert simple subscripts like x_1 -> x[1]
    jl_line = re.sub(r'(?<!\w)x_(\d+)', r'x[\1]', m2_line)

    # Convert patterns like name_{1,2,3} -> name[1,2,3]
    # Allow optional spaces after commas inside the braces and normalize them.
    def _braced_sub(match):
        name = match.group(1)
        nums = match.group(2)
        # split on commas and strip whitespace, then re-join with commas
        parts = [p.strip() for p in nums.split(',') if p.strip()]
        return f"{name}[{','.join(parts)}]"

    jl_line = re.sub(r"(\w+)_\{\s*([0-9,\s]+?)\s*\}", _braced_sub, jl_line)

    # Also handle single-index with braces: x_{1} -> x[1]
    jl_line = re.sub(r'(\w+)_\{\s*(\d+)\s*\}', r'\1[\2]', jl_line)

    # As a final pass, convert any remaining simple a_1 style (non-x) -> a[1]
    jl_line = re.sub(r'(?<!\w)([A-Za-z]\w*)_(\d+)', r'\1[\2]', jl_line)

    return jl_line


def format_entry_multiline(expr, indent='    ', max_len=2000):
    """Format a polynomial expression into multiple shorter lines by splitting on + and - terms.
    Returns a string with indentation at the start of the first line (suitable for inclusion in a Julia array).
    """
    terms = re.findall(r'[+-]?[^+-]+', expr)
    terms = [t.strip() for t in terms if t.strip()]
    if not terms:
        return indent + expr
    lines = []
    current = terms[0]
    for t in terms[1:]:
        if len(current) + 1 + len(t) <= max_len:
            current = current + t if t.startswith(('+','-')) else current + '+' + t
        else:
            lines.append(current)
            current = t
    lines.append(current)
    out = ("\n" + indent).join([lines[0]] + [l for l in lines[1:]])
    return indent + out

def stream_m2_entries(file_path):
    """
    Generator function to read a Macaulay2 file and yield one entry at a time.
    This avoids reading the whole file into memory.
    It assumes the file contains a list where entries are separated by commas,
    and can be nested with {}.
    """
    with open(file_path, 'r') as f:
        current_entry = ""
        brace_level = 0

        # Consume initial whitespace and detect opening '{' for top-level list.
        while True:
            ch = f.read(1)
            if not ch:
                return
            if ch.isspace():
                continue
            if ch == '{':
                brace_level = 1
                break
            # not a brace-started list; rewind one char and proceed
            f.seek(f.tell() - 1)
            break

        while True:
            ch = f.read(1)
            if not ch:
                # EOF; yield any remaining entry
                if current_entry.strip():
                    yield current_entry.strip()
                break

            if ch == '{':
                brace_level += 1
                current_entry += ch
                continue

            if ch == '}':
                # closing a brace
                brace_level -= 1
                # if we've closed the top-level list, yield the last item and stop
                if brace_level == 0:
                    if current_entry.strip():
                        yield current_entry.strip()
                    break
                else:
                    current_entry += ch
                    continue

            # top-level separators are commas at brace_level == 1
            if ch == ',' and brace_level == 1:
                yield current_entry.strip()
                current_entry = ""
                continue

            current_entry += ch


def process_file(input_file, chunk_size):
    """Processes a single Macaulay2 file, converting it into chunked Julia files."""
    base_name = os.path.splitext(os.path.basename(input_file))[0]
    output_dir = os.path.dirname(input_file)
    main_jl_file = os.path.join(output_dir, base_name + '.jl')

    chunk_files = []
    chunk_index = 1
    entries_in_current_chunk = []

    print(f"--- Starting conversion of {input_file} with chunk size {chunk_size} ---")

    for entry in stream_m2_entries(input_file):
        entries_in_current_chunk.append(entry)
        if len(entries_in_current_chunk) >= chunk_size:
            chunk_file_name = f"{base_name}_chunk_{chunk_index}.jl"
            chunk_file_path = os.path.join(output_dir, chunk_file_name)
            
            def _write_chunk_file(path, entries):
                # write each entry on multiple shorter lines by splitting on +/ - term boundaries
                def _multiline_format(expr, indent='    ', max_len=2000):
                    # split into terms preserving leading sign
                    terms = re.findall(r'[+-]?[^+-]+', expr)
                    # normalize whitespace in terms
                    terms = [t.strip() for t in terms if t.strip()]
                    if not terms:
                        return indent + expr
                    lines = []
                    current = terms[0]
                    for t in terms[1:]:
                        # try adding term to current line
                        if len(current) + 1 + len(t) <= max_len:
                            current = current + t if t.startswith(('+','-')) else current + '+' + t
                        else:
                            lines.append(current)
                            current = t
                    lines.append(current)
                    # join lines with newline and proper indentation
                    out = ("\n" + indent).join([lines[0]] + [l for l in lines[1:]])
                    return indent + out

            with open(chunk_file_path, 'w') as f:
                f.write(f"# Chunk {chunk_index} from {os.path.basename(input_file)}\n")
                f.write("[\n")
                for e in entries_in_current_chunk:
                    # convert subscripts and normalize internal whitespace/newlines so
                    # we never accidentally split tokens (like v[1,3,3]) across lines.
                    jl_e = convert_m2_to_jl_line(e)
                    # collapse any internal newlines/whitespace to single spaces
                    jl_e = re.sub(r"\s+", " ", jl_e)
                    # format into shorter human-readable form (but we will store as a
                    # quoted string so the Julia parser never sees token fragments).
                    formatted = format_entry_multiline(jl_e)
                    # strip leading indentation from the formatted expression and
                    # write it as a JSON-escaped string literal so newlines are \n
                    payload = json.dumps(formatted.strip())
                    f.write('    ' + payload + ",\n")
                f.write("]\n")

            chunk_files.append(chunk_file_name)
            print(f"Generated {chunk_file_name}")
            
            chunk_index += 1
            entries_in_current_chunk = []

    # Write any remaining entries to a final chunk file
    if entries_in_current_chunk:
        chunk_file_name = f"{base_name}_chunk_{chunk_index}.jl"
        chunk_file_path = os.path.join(output_dir, chunk_file_name)
        
        def _write_chunk_file(path, entries):
            def _multiline_format(expr, indent='    ', max_len=2000):
                terms = re.findall(r'[+-]?[^+-]+', expr)
                terms = [t.strip() for t in terms if t.strip()]
                if not terms:
                    return indent + expr
                lines = []
                current = terms[0]
                for t in terms[1:]:
                    if len(current) + 1 + len(t) <= max_len:
                        current = current + t if t.startswith(('+','-')) else current + '+' + t
                    else:
                        lines.append(current)
                        current = t
                lines.append(current)
                out = ("\n" + indent).join([lines[0]] + [l for l in lines[1:]])
                return indent + out

        with open(chunk_file_path, 'w') as f:
            f.write(f"# Chunk {chunk_index} from {os.path.basename(input_file)}\n")
            f.write("[\n")
            for e in entries_in_current_chunk:
                # normalize whitespace/newlines inside each entry before formatting
                jl_e = convert_m2_to_jl_line(e)
                jl_e = re.sub(r"\s+", " ", jl_e)
                formatted = format_entry_multiline(jl_e)
                payload = json.dumps(formatted.strip())
                f.write('    ' + payload + ",\n")
            f.write("]\n")

        chunk_files.append(chunk_file_name)
        print(f"Generated {chunk_file_name}")

    # Create the main Julia file that exposes chunk metadata and helpers but
    # does NOT automatically concatenate all chunks. This allows `include`
    # to be cheap and lets users load chunks piecewise.
    with open(main_jl_file, 'w') as f:
        f.write(f"# Main file for {base_name}, chunk metadata and helpers.\n")
        f.write(f"# Generated from {os.path.basename(input_file)}\n\n")

        # Chunk files array (paths are joined with @__DIR__ at runtime)
        f.write(f"const {base_name}_CHUNK_FILES = [\n")
        for cf in chunk_files:
            f.write(f"    \"{cf}\",\n")
        f.write("]\n\n")

        # Helpers: count, load single chunk, iterate over chunks, and optional concat
        f.write(f"function {base_name}_chunk_count()\n")
        f.write(f"    return length({base_name}_CHUNK_FILES)\n")
        f.write("end\n\n")

        f.write(f"function {base_name}_load_chunk(i::Integer)\n")
        f.write(f"    @assert 1 <= i <= {base_name}_chunk_count()\n")
        f.write(f"    chunk_file = {base_name}_CHUNK_FILES[i]\n")
        f.write(f"    return include(joinpath(@__DIR__, chunk_file))\n")
        f.write("end\n\n")

        f.write(f"function {base_name}_each_chunk(f::Function)\n")
        f.write(f"    for cf in {base_name}_CHUNK_FILES\n")
        f.write(f"        data = include(joinpath(@__DIR__, cf))\n")
        f.write(f"        f(data)\n")
        f.write(f"        GC.gc()\n")
        f.write(f"    end\n")
        f.write("end\n\n")

        f.write(f"function {base_name}_get_all_entries()\n")
        f.write(f"    all = []\n")
        f.write(f"    for i in 1:{base_name}_chunk_count()\n")
        f.write(f"        append!(all, {base_name}_load_chunk(i))\n")
        f.write(f"    end\n")
        f.write(f"    return all\n")
        f.write("end\n\n")

        f.write(f"# Usage: include(joinpath(@__DIR__, \"{os.path.basename(main_jl_file)}\"))\n")
        f.write(f"# Then either call {base_name}_load_chunk(i) to load chunk i,\n")
        f.write(f"# use {base_name}_each_chunk(f) to process chunks one-by-one, or\n")
        f.write(f"# call {base_name}_get_all_entries() to concatenate all chunks into memory.\n")

    print(f"Successfully converted {input_file}.")
    print(f"Main Julia file created at: {main_jl_file}")
    print(f"Generated {len(chunk_files)} chunk files in {output_dir}\n")


def main():
    # Hardcode the input directory and chunk size for simplicity
    input_dir = 'cache/'
    chunk_size = 10

    # Get the absolute path to the input directory
    # Assumes the script is in a 'scripts' folder at the project root
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    abs_input_dir = os.path.join(project_root, input_dir)

    if not os.path.isdir(abs_input_dir):
        print(f"Error: Directory not found at '{abs_input_dir}'")
        print("Please ensure the 'cache' directory exists at the root of the project.")
        return

    print(f"Processing all .m2 files in '{abs_input_dir}'...")
    m2_files_found = False
    for filename in os.listdir(abs_input_dir):
        if filename.endswith('.m2'):
            m2_files_found = True
            input_file = os.path.join(abs_input_dir, filename)
            process_file(input_file, chunk_size)
    
    if not m2_files_found:
        print("No .m2 files found to process.")
    else:
        print("All .m2 files processed.")

if __name__ == '__main__':
    main()
