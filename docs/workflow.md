# Workflow and Data Layout

## Purpose

This document describes the intended end-to-end workflow:

1. Select `(Session, Run, Block)` rows for export.
2. Copy source data into repository layout.
3. Run synchronization checks for behavior-ephys alignment.
4. Upload prepared folders to the shared repository.

## Source Inputs

- **TDT block source**
  - Folder pattern: `<block_path>/<Session>/Block-<BlockNumber>`
- **Behavior source**
  - File pattern: `<run_path>/<Session>/<Mon><YYYY-MM-DD>_<NN>.mat`
- **Selection table**
  - `SesRunBlo` matrix with columns:
    1. Session (`YYYYMMDD`)
    2. Run number
    3. Block number

## Destination Layout

`nhprs_kw_copy_blocks_runs.m` writes data to:

`<data_path>/<Mon>/<Session>/Block-<BlockNumber>`

Expected contents per block folder:

- Original TDT block files
- Matching behavioral run `.mat`

## Operational Steps

### Step 1: Build selection matrix

Typical source:

```matlab
SesRunBlo = xlsread('Sorting table.xlsx', '<sheet-name>', 'D:F');
```

### Step 2: Run copy utility

```matlab
nhprs_kw_copy_blocks_runs(block_path, run_path, data_path, Mon, SesRunBlo, target, dry_run)
```

- `dry_run = true` prints intended actions only.
- `dry_run = false` performs actual copy.

### Step 3: Validate synchronization

For a quick single run/block check:

Use `DAG_synchronization_example.m` and `ph_synchronization.m` to verify that
aligned timestamps and trial anchors are plausible.

For full subject-level validation across all days and blocks:

```matlab
[results, report] = DAG_synchronization_all_blocks_example(subject_root_folder);
```

This writes a text report to:

`<subject_root_folder>/synchronization_report.txt`

The function continues across blocks even if one block fails, and records
block-level failures in the report output.

## Logging

`nhprs_kw_copy_blocks_runs.m` writes a diary log:

`<data_path>/<Mon>/<target>.txt`

This log records missing sources, skipped blocks, and copy attempts.
