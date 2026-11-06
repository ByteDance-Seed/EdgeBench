# Git to Zig

Reimplement git in Zig as a drop-in replacement for the `git` binary. The C
source for git v2.47.0 is fetched while building the task image from the pinned
upstream FrontierSWE git-to-zig assets and placed in the sibling `git-src/`
directory under the workspace root. In SE-Bench this is usually `/home/workspace/git-src/`; in the
standalone task image it may be `/app/git-src/`. Read it, understand it, and
rewrite it. Your binary must behave identically to the real `git` — same CLI
interface, same output formats, same exit codes.

Your Zig implementation workspace is the `zig-port/` directory, normally the
current working directory. The build scaffold compiles with Zig 0.14.0 and links
zlib. `zig build` produces `zig-out/bin/git`. The system `git` is installed —
use it to test your implementation as you go.

## Time Budget

Your wall-clock budget is enforced by Harbor and exposed through a timer daemon:

```bash
# SE-Bench harness
cat /home/workspace/.timer/remaining_secs   # seconds remaining
cat /home/workspace/.timer/elapsed_secs     # seconds elapsed

# Standalone Harbor image
cat /app/.timer/remaining_secs
cat /app/.timer/elapsed_secs
```

You have a fixed wall-clock budget for this task. Plan your work to make effective use of the available time.

No internet at task runtime. Do not compile or link the C source or wrap around the existing git binary — write Zig.
Work autonomously, do not ask user for input.
