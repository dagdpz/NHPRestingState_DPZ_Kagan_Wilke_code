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

- Early return path can occur before outputs are explicitly initialized.
- Required fields besides `Tnum` are used without explicit guards in code.
- The optional `debug_on` branch relies on legacy `Sess` logic and may not be
  robust across all datasets.
- Empty matches (missing state-2 in behavior or ephys) are not explicitly
  handled with controlled fallback behavior.

## `DAG_synchronization_example.m`

### Assumptions

- Run number parsing uses filename suffix indexing (`end-5:end-4`), which
  assumes a fixed `..._NN.mat` naming pattern.

### Risk

- If filename pattern changes, run extraction can fail or parse incorrectly.

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
