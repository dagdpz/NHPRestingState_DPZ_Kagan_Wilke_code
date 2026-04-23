# Known Limitations and Assumptions

This document captures current assumptions and implementation risks in the
existing MATLAB scripts. It is intended to make behavior explicit before any
functional refactor.

## `ph_synchronization.m`

### Assumptions

- Behavioral file contains `trial` with expected fields.
- `behavioral_data.run` is correctly set by caller.
- Trial index `t` in behavioral stream corresponds to TDT trial numbering
  used in `Tnum.data`.
- Each trial has at least one `state == 2` sample in behavior.
- Ephys has at least one matching `SVal == 2` onset after each trial onset.

### Current Risks

- The optional `debug_on` branch relies on legacy `Sess` logic and may not be
  robust across all datasets and may skip some legacy corrections when `Sess`
  is unavailable.
- If many trials are skipped due to missing anchors, downstream analyses should
  explicitly verify expected trial coverage in `Trial_timestamps` and inspect
  synchronization messages in `report`.

## `DAG_synchronization_example.m`

### Assumptions

- Run number parsing uses filename suffix indexing (`end-5:end-4`), which
  assumes a fixed `..._NN.mat` naming pattern with exactly two run digits.

### Risk

- If filename pattern changes, run extraction can fail or parse incorrectly.

## `DAG_synchronization_all_blocks_example.m`

### Assumptions

- Subject folder contains day folders named exactly `YYYYMMDD`.
- Each block folder contains at least one behavioral file matching:
  - `<Subject><YYYY-MM-DD>_*.mat`
- Run number is parsed from trailing filename token:
  - `..._<Run>.mat`

### Current Behavior Notes

- The function continues across blocks when one block fails and records failure
  text in `synchronization_report.txt`.
- If multiple behavioral MAT files match one block, alphabetical first is used
  and a warning is logged.

### Risk

- Multiple-match selection is deterministic but may not be semantically correct
  without stricter run/block metadata in filenames.

## `nhprs_kw_copy_blocks_runs.m`

### Assumptions

- Sessions are numeric and represent `YYYYMMDD`.
- Behavioral run files follow:
  - `<Mon><YYYY-MM-DD>_<NN>.mat`
- Block folder naming is:
  - `Block-<BlockNumber>`

### Current Behavior Notes

- Existing destination block folders are skipped.
- In dry-run mode, actions are logged and no file copy occurs.
- If source block folder or run file is missing, that row is skipped.

## `TDTbin2mat_working.m`

### Divergence from Upstream

- Local fork includes project-specific parameters and logic:
  - `DONTREAD`
  - `EXCLUSIVELYREAD`
  - `CHANNELS`
  - `STREAMSWITHLIMITEDCHANNELS`
  - `BROA`/`Broa` handling
  - `SEV2mat_working` integration

### Risk

- Behavior differs from current upstream TDT SDK and should not be assumed
  equivalent without explicit diff validation.
