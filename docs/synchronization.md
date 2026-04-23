# Synchronization Logic (`ph_synchronization.m`)

## Goal

Convert behavioral sample times (DAG trial stream) into timestamps in the
ephys block time frame (TDT stream).

## Data Streams Used

- **Behavioral stream**
  - `behavioral_data.trial(t).state`
  - `behavioral_data.trial(t).tSample_from_time_start`
  - `behavioral_data.run`

- **Ephys trial/run stream**
  - `ephys_data.epocs.Tnum.data` (trial numbering)
  - `ephys_data.epocs.Tnum.onset` (trial onset times)
  - `ephys_data.epocs.RunN.data` (run numbering)

- **Ephys state stream**
  - `ephys_data.epocs.SVal.data`
  - `ephys_data.epocs.SVal.onset`

## Alignment Rule

Per behavioral trial `t`:

1. Find first behavior sample where `state == 2`.
2. Find first ephys state onset where:
   - `SVal == 2`
   - onset is after the corresponding ephys trial onset for trial `t`.
3. Shift all behavioral sample timestamps of trial `t` to ephys time:

`behavior_sample_time - behavior_state2_time + ephys_state2_onset`

## Outputs

`[continuous_timestamps, continuous_data, Trial_timestamps, report]`

- `continuous_timestamps`
  - concatenated sample-wise timestamps in ephys block time (seconds).
- `continuous_data`
  - concatenated behavioral fields:
    `state`, `x_eye`, `y_eye`, `x_hnd`, `y_hnd`, `sen_L`, `sen_R`, `jaw`, `body`.
- `Trial_timestamps`
  - one timestamp per trial, using the state-2 ephys anchor.
- `report`
  - string array containing informational and warning messages emitted during
    synchronization (useful for QA and batch logs).

## Run Filtering Behavior

If one ephys block contains trials from multiple behavioral runs, only entries
matching `behavioral_data.run` are retained before alignment.

## Expected Input Contract

Minimum required fields:

- `behavioral_data.trial`
- `behavioral_data.run`
- `ephys_data.epocs.Tnum`
- `ephys_data.epocs.RunN`
- `ephys_data.epocs.SVal`

Optional input:

- `debug_on` (logical)
  - enables/disables legacy anomaly handling branch.

See `docs/known-limitations.md` for current edge cases and caveats.

## Batch Validation Across All Blocks

`DAG_synchronization_all_blocks_example.m` provides a dataset-wide wrapper that:

1. Scans `<subject_root>/<YYYYMMDD>/Block-*`
2. Locates matching behavioral `.mat` files per block
3. Runs `ph_synchronization` block-by-block
4. Continues on failures and writes a consolidated
   `synchronization_report.txt` in the subject root folder
