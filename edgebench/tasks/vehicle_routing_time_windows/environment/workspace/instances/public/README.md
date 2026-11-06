# instances/public/ — Public Instance Set

> This directory hosts 56 public CVRPTW instances (Solomon 100 + Gehring-Homberger 200/400/600/800/1000)
> for the Agent to iterate quickly locally. **Remote evaluation uses shuffled-node-index copies of the same instances.**

## Directory Contents

The repository comes with 3 **hand-crafted small example instances** (10-30 nodes, for quick sub-second debugging):

| File | N | Type | BKS (NV, TD) |
|---|---|---|---|
| `EX_C25.txt`  | 25 | C-type (clustered, tight time windows) | (3, 191.70) |
| `EX_R20.txt`  | 20 | R-type (dispersed, loose time windows) | (3, 336.70) |
| `EX_RC15.txt` | 15 | RC-type (mixed)                        | (4, 405.20) |

The full 56 instances must be installed via `fetch_solomon.sh` (network is disabled on the remote judge; only available in the local environment):
```bash
cd instances/public
# Offline mode (recommended): use the tarball provided by the competition organizer
bash fetch_solomon.sh --offline /path/to/cvrptw-bundle-v1.0.tar.gz
```
This extracts 56 `*.txt` + `*.bks` files into this directory.

> Because SINTEF / CVRPLIB no longer offers a unified download bundle (each instance must be
> fetched individually and the site structure may change), it is recommended to use the pre-packaged
> `cvrptw-bundle-vX.Y.tar.gz` from the competition organizer (same data as the remote judge,
> just without node-index shuffling). Contact your competition liaison for the tarball.

## .bks File Format

Each `<name>.bks` file contains one line: `<NV> <TD>`, e.g. `25 828.94`.
- BKS values come from the SINTEF/CVRPLIB public leaderboard (2024 snapshot).
- These values are only used for the Agent's local self-evaluation; **the remote judge uses an independently stored BKS table** and recomputes scores for each submission.

## Data Source Attribution

- Solomon 100: M.M. Solomon, "Algorithms for the vehicle routing and scheduling problem with time window constraints", Operations Research 35(2), 1987.
- Gehring-Homberger 200-1000: H. Gehring, J. Homberger, "A parallel hybrid evolutionary metaheuristic for the vehicle routing problem with time windows", 1999.
- The datasets are freely available for academic evaluation (see SINTEF official terms of use).
