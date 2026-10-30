# CAS Schema Migration System

This document explains how CAS handles database schema migrations, updates, and upgrades.

## Overview

CAS uses a forward-only migration system with:
- **Versioned migrations** tracked in `cas_migrations` table
- **Bootstrap detection** for existing databases
- **Explicit upgrade** via `cas update` command
- **No rollback support** (keep it simple)

## Architecture

```
src/migration/
├── mod.rs          # Runner, registry, public API
├── migrations.rs   # All migration definitions
└── detector.rs     # Schema introspection utilities
```

## Migration Structure

Each migration is defined in `migrations.rs`:

```rust
Migration {
    id: 91,                              // Unique sequential ID
    name: "task_leases_add_epoch",       // Machine-readable name
    subsystem: Subsystem::Agents,        // Which subsystem it affects
    description: "Add epoch column...",  // Human-readable description
    up: &["ALTER TABLE task_leases ADD COLUMN epoch INTEGER NOT NULL DEFAULT 1"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('task_leases') WHERE name = 'epoch'"),
}
```

### ID Ranges by Subsystem

| Subsystem | ID Range | Description |
|-----------|----------|-------------|
| Entries | 1-50 | Entry storage (entries, sessions tables) |
| Rules | 51-70 | Rule storage |
| Skills | 71-90 | Skill storage |
| Agents | 91-110 | Agent coordination (agents, task_leases) |
| Entities | 111-130 | Entity/knowledge graph |
| Verification | 131-150 | Task verification |
| Loops | 151-170 | Iteration loops |

## Adding a New Migration

### Step 1: Update Base Schema

For **new databases**, add the column to the base schema in the appropriate store file:

```rust
// In src/store/sqlite.rs or src/store/skill_store.rs
const SCHEMA: &str = r#"
CREATE TABLE IF NOT EXISTS entries (
    ...
    new_column TEXT NOT NULL DEFAULT '',  // Add here
    ...
);
"#;
```

### Step 2: Add Migration Definition

For **existing databases**, add a migration in `src/migration/migrations.rs`:

```rust
Migration {
    id: 29,  // Next available ID in subsystem range
    name: "entries_add_new_column",
    subsystem: Subsystem::Entries,
    description: "Add new_column for feature X",
    up: &["ALTER TABLE entries ADD COLUMN new_column TEXT NOT NULL DEFAULT ''"],
    detect: Some("SELECT COUNT(*) FROM pragma_table_info('entries') WHERE name = 'new_column'"),
},
```

### Step 3: Add Index (if needed)

If the column needs an index, add a separate migration:

```rust
Migration {
    id: 30,
    name: "entries_idx_new_column",
    subsystem: Subsystem::Entries,
    description: "Add index on new_column",
    up: &["CREATE INDEX IF NOT EXISTS idx_entries_new_column ON entries(new_column)"],
    detect: Some("SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_entries_new_column'"),
},
```

### Step 4: Run Tests

```bash
cargo test migration
```

## Detection Queries

Every migration needs a `detect` query that returns > 0 if the migration is already applied. Common patterns:

```sql
-- Column exists
SELECT COUNT(*) FROM pragma_table_info('table_name') WHERE name = 'column_name'

-- Index exists
SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_name'

-- Table exists
SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='table_name'
```

## CLI Commands

### Check for Updates
```bash
cas update --check
```
Shows both binary and schema update status.

### Preview Migrations
```bash
cas update --dry-run
```
Shows what migrations would be applied without running them.

### Run Migrations
```bash
cas update --schema-only
```
Applies pending schema migrations.

### Full Update
```bash
cas update
```
Updates binary (from GitHub releases) then runs schema migrations.

### Doctor Check
```bash
cas doctor
```
Shows schema version and table details:
```
✓ schema [OK]: v91 (up to date)
✓ tables [OK]: 16 tables, 175 columns, 255 rows total
```

## Bootstrap Process

When CAS encounters a database without migration tracking:

1. Creates `cas_migrations` table
2. Runs detection query for each migration
3. Marks detected migrations as applied with `applied_at = 'BOOTSTRAP'`
4. Applies only truly pending migrations

This ensures existing databases upgrade smoothly without re-running migrations.

## Important Rules

### DO:
- Always add both base schema column AND migration
- Use sequential IDs within subsystem range
- Include detection query for every migration
- Test with fresh database AND existing database
- Keep migrations idempotent where possible

### DON'T:
- Reuse or change existing migration IDs
- Modify applied migrations
- Add migrations without updating base schema
- Create circular dependencies between migrations

## Separate Database Files

CAS uses multiple database files:

| File | Contents | Migration Handling |
|------|----------|-------------------|
| `cas.db` | Entries, rules, skills, agents, tasks | Migration system |
| `traces.db` | Tool traces, trace events | In-place in TraceStore::open() |

Tracing migrations are NOT in the migration system because they use a separate database file.

## Error Handling

If a migration fails:
1. Transaction is rolled back
2. Error is reported with migration name
3. Subsequent migrations are skipped
4. User must fix issue and re-run

Common errors:
- `duplicate column name` - Column already exists (detection query may be wrong)
- `no such table` - Table doesn't exist yet (migration order issue)

## Version Tracking

The `cas_migrations` table:

```sql
CREATE TABLE cas_migrations (
    id INTEGER PRIMARY KEY,       -- Migration ID
    name TEXT NOT NULL UNIQUE,    -- Migration name
    subsystem TEXT NOT NULL,      -- Subsystem affected
    applied_at TEXT NOT NULL      -- Timestamp or 'BOOTSTRAP'
);
```

Query current schema version:
```sql
SELECT MAX(id) FROM cas_migrations;
```
