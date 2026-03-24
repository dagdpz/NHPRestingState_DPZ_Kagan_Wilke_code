# NHPRestingState_DPZ_Kagan_Wilke_code

Utility MATLAB scripts for preparing and validating uploads to:
[NHPRestingState_DPZ_Kagan_Wilke](https://gin.g-node.org/NHPRestingState/NHPRestingState_DPZ_Kagan_Wilke)

This repository currently contains two operational components:

1. **Data packaging/copy utility**
   - Copies selected TDT `Block-*` folders and matching behavioral `.mat` runs
     into the target repository layout.
2. **Behavior-ephys synchronization utility**
   - Aligns behavioral sample timestamps to ephys block time using TDT epocs.

## Repository Contents

- `nhprs_kw_copy_blocks_runs.m`
  - Batch copy tool driven by a `[Session, Run, Block]` table.
- `ph_synchronization.m`
  - Core alignment function from behavioral time to ephys block time.
- `DAG_synchronization_example.m`
  - Minimal example script for one run/block synchronization call.
- `TDTbin2mat_working.m`
  - Local customized fork of TDT readout function used by this project.

## Documentation Index

- `docs/workflow.md`
  - End-to-end data flow and directory conventions.
- `docs/synchronization.md`
  - Detailed synchronization logic, data contracts, and output definitions.
- `docs/known-limitations.md`
  - Current assumptions, edge cases, and known implementation risks.
- `docs/tdtbin2mat-working-diff.md`
  - Local fork differences from upstream TDT `TDTbin2mat.m`.

## Quick Start

### 1) Copy selected sessions/runs/blocks

```matlab
SesRunBlo = xlsread('Sorting table.xlsx', 'Mag dPul_r', 'D:F');
nhprs_kw_copy_blocks_runs('', '', '', 'Mag', SesRunBlo, 'dPul_l', false);
```

Use `dry_run=true` to print planned actions without copying:

```matlab
nhprs_kw_copy_blocks_runs('', '', '', 'Mag', SesRunBlo, 'dPul_l', true);
```

### 2) Synchronize one behavioral run to one ephys block

```matlab
ephys_data = TDTbin2mat_working(ephys_folder, 'EXCLUSIVELYREAD', {'SVal','Tnum','RunN','Sess'});
behavioral_data = load(behavior_file, 'trial');
behavioral_data.run = str2num(behavior_file(end-5:end-4));
[continuous_timestamps, continuous_data, Trial_timestamps] = ph_synchronization(ephys_data, behavioral_data);
```

## Important Assumptions

- Behavioral filename encodes run number as `..._NN.mat`.
- Session identifier is interpreted as `YYYYMMDD`.
- Synchronization anchor is **state 2** in behavior and `SVal==2` in ephys.
- TDT epoc stores required for sync: `Tnum`, `RunN`, `SVal`.

## Notes on Current State

- `TDTbin2mat_working.m` diverges substantially from current upstream
  `TDTbin2mat.m` and includes project-specific behavior.
- `ph_synchronization.m` is functional for expected datasets but still has
  known robustness limitations; see `docs/known-limitations.md`.
