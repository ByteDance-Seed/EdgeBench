import os
import re

omit_proofs = True

# Converts a block of lean code to latex.
def lean_to_latex(lean: str):
    # Remove imports.
    lean = re.sub(r'import .*', '', lean)
    # Remove `open` declarations.
    lean = re.sub(r'open .*', '', lean)
    # Remove `universe` declarations.
    lean = re.sub(r'universe .*', '', lean)
    # Remove `namespace ConNF` and `end ConNF`.
    lean = lean.replace('namespace ConNF', '')
    lean = lean.replace('end ConNF', '')
    # Remove `noncomputable section`.
    lean = lean.replace('noncomputable section', '')

    # Replace any triple newlines that we just created with double newlines.
    while True:
        old_lean = lean
        lean = lean.replace('\n\n\n', '\n\n')
        if old_lean == lean:
            break

    if omit_proofs:
        # Remove large tactic blocks.
        # If `by` occurs at the end of a line with some indent level, then depending on the next line's
        # indent level, we do different things.
        # If the next line is at a lower indent level, the proof is considered to run until we get
        # back to indent level 0.
        # If the next line is at a higher indent level, the proof is considered to end once we get
        # back to the original indent level.

        output = ""
        in_large_proof = False
        for line in lean.splitlines():
            indent_result = re.search(r' *', line)
            indent = indent_result.end() - indent_result.start()

            if in_large_proof:
                if proof_target_indent is None:
                    if indent < by_indent:
                        proof_target_indent = 0
                    else:
                        proof_target_indent = by_indent
                if indent <= proof_target_indent:
                    # The proof is done.
                    in_large_proof = False
                    if proof_target_indent == 0:
                        output += "\n "
                    if proof_lines == 1:
                        output += " <1 line>"
                    else:
                        output += f" <{proof_lines} lines>"
                else:
                    # Consume this line entirely.
                    proof_lines += 1
                    continue

            output += '\n' + line
            if line.endswith(':= by'):
                in_large_proof = True
                by_indent = indent
                proof_target_indent = None
                proof_lines = 0
    else:
        output = lean

    output = output.strip()
    if output == '':
        return ''
    else:
        return r'\begin{leancode}' + '\n' + output + '\n' + r'\end{leancode}' + '\n'

# Converts a block of markdown documentation to latex.
def docs_to_latex(docs: str, file_name: str):
    output = ''
    in_list = False
    in_code_block = False
    for line in docs.splitlines():
        if in_code_block:
            if line.startswith('```'):
                # End this code block.
                in_code_block = False
                output += '\n' + r'\begin{leancode}' + '\n' + current_code_block.strip() + '\n' + r'\end{leancode}'
            else:
                current_code_block += line + '\n'
            continue
        if line.startswith('```'):
            # Start a code block.
            in_code_block = True
            current_code_block = ""
            continue

        output += '\n'

        # Convert inline code.
        line = re.sub(r'`(.*?)`', r'\\lean{\1}', line)
        # Convert quote marks.
        line = re.sub(r'\'([^ ].*?)\'', '`\\1\'', line)
        line = re.sub(r'"([^ ].*?)"', '``\\1\'\'', line)
        # Convert italics.
        line = re.sub(r'\*([^ ].*?)\*', r'\\textit{\1}', line)

        if line.startswith('* '):
            if not in_list:
                output += r'\begin{itemize}' + '\n'
            in_list = True
            output += r'\item ' + line[2:]
            continue
        elif not line.startswith(' '):
            if in_list:
                output += r'\end{itemize}' + '\n'
                in_list = False

        done = False
        for i in range(1,6):
            if line.startswith('#' * i + ' '):
                output += '\\' + ('sub' * (i - 1)) + 'section{' + line[i + 1:] + '}'
                done = True
                if i == 1:
                    output += '\n' + r'\textit{File name: } \verb|' + file_name + '|\\textit{.}'
                break
        if done: continue

        output += line

    if in_list:
        output += '\n' + r'\end{itemize}'

    return '\n' + output.strip() + '\n\n'

# Converts an entire file of lean code to latex.
def convert(lean: str, file_name: str):
    # First, extract the module documentation and regular documentation blocks.
    output = ''
    while True:
        result = re.search(r'/-[-!]', lean)
        if result is None:
            output += lean_to_latex(lean)
            break
        else:
            i = lean.find('-/')
            doc_block = lean[result.end():i]
            output += lean_to_latex(lean[:result.start()])
            output += docs_to_latex(doc_block, file_name)
            lean = lean[i+2:]
    return output

os.chdir('..')
for root, dirs, files in os.walk('ConNF'):
    path = root.split(os.sep)
    newroot = os.path.join('latex', 'generated', *path[1:])
    os.makedirs(newroot, exist_ok=True)
    for file in files:
        with open(os.path.join(root, file)) as f:
            content = f.read()
        with open(os.path.join(newroot, file.removesuffix('.lean') + '.tex'), 'w') as f:
            f.write(convert(content, '.'.join([*path, file.removesuffix('.lean')])))
