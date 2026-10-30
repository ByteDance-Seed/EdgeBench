# internal/cases/ — Remote Evaluation Dataset

> **Not distributed to Agent.** Used by task authors/ops during each evaluation deployment.

## File Listing

```
cases/
├── README.md                  # This file
├── bks_snapshot.csv           # BKS for 56 instances (from SINTEF 2024 snapshot)
├── solomon_to_extended.py     # Solomon original format → task extended format converter
├── scramble_nodes.py          # Node ID scrambling script (prevents hardcoded answers)
├── gen_custom.py              # Custom large-scale instance generator (backup, not in main leaderboard)
├── raw_solomon100/            # 56 Solomon-100 original files (GitHub public mirror copy)
│   └── *.txt × 56
├── raw/                       # Converted extended-format instances (evaluation input)
│   ├── README.md              # Data provenance + conversion pipeline
│   └── *.txt × 56
└── scrambled/                 # Node-ID-scrambled remote version (regenerated each deployment)
```

## Data Flow

```
   GitHub public mirror                Step 1
   iRB-Lab/py-ga-VRPTW   ──curl──►  raw_solomon100/
                                          │
                                          │ Step 2
                                          │ python3 solomon_to_extended.py
                                          ▼
                                        raw/                   Step 3
                                          │  ──python3 scramble_nodes.py──►
                                          ▼
                                                              scrambled/
                                                                   │
                                                                   │ docker volume mount
                                                                   ▼
                                                              evaluator
```

## Operations Guide (Evaluation Deployment)

### Step 1: Fetch 56 original Solomon-100 files
```bash
mkdir -p raw_solomon100
for name in $(awk -F, 'NR>1{print $1}' bks_snapshot.csv); do
    curl -sfL --max-time 15 \
        "https://raw.githubusercontent.com/iRB-Lab/py-ga-VRPTW/master/data/text/${name}.txt" \
        -o "raw_solomon100/${name}.txt"
done
test "$(ls raw_solomon100/*.txt | wc -l)" -eq 56 || echo "FAIL: missing instances"
```

### Step 2: Convert to extended format
```bash
python3 solomon_to_extended.py raw_solomon100/ raw/
```

### Step 3: Scramble node IDs
```bash
python3 scramble_nodes.py \
    --src raw/ \
    --dst scrambled/ \
    --map ../scramble_map.json \
    --seed 20260507
```
- `--seed` determines the scrambling key; same seed is reproducible.
- Outputs 56 `<orig>_<6hex>.txt` files; geometric coordinates unchanged, only customer IDs reshuffled.
- `scramble_map.json` stores the reverse mapping (for evaluator to recompute original BKS); not distributed.

### Step 4: Start evaluator and mount data
```bash
docker run -d --name evaluator -p 8080:8080 \
    -v "$PWD/scrambled":/srv/cvrptw/cases:ro \
    -v "$PWD/bks_snapshot.csv":/srv/cvrptw/bks_snapshot.csv:ro \
    -v "$PWD/../scramble_map.json":/srv/cvrptw/scramble_map.json:ro \
    -v /var/run/docker.sock:/var/run/docker.sock \
    cvrptw-evaluator:latest
```

## BKS Source Declaration

Each row in `bks_snapshot.csv` contains:
- `name`: Instance name (consistent with SINTEF/Solomon 1987)
- `nv`: Best known number of vehicles
- `td`: Best known total distance at that nv
- `source`: `SINTEF-Solomon-2024`
- `verified`: Date independently verified by task author

All 56 BKS values are consistent with the SINTEF VRPTW page (https://www.sintef.no/projectweb/top/vrptw/solomon-benchmark/100-customers/) public leaderboard.

## Custom Instance Generator (Backup)

`gen_custom.py` is used during review/debugging to quickly generate larger-scale instances (200/500/1000/... nodes):
```bash
python3 gen_custom.py --n 200 --kind C  --seed 42 --out /tmp/c200_42.txt
```
Not included in official evaluation; used only for:
- Verifying solver stability at larger scales (regression test);
- Creating "BKS breakthrough" manual baselines;
- Anti-contamination — LLM training data will not contain these seed+shape combinations.
