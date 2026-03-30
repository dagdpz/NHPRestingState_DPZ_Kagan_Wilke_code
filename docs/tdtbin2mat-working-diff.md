# `TDTbin2mat_working.m` vs Upstream `TDTbin2mat.m`

## Purpose

This document summarizes the known differences between the local
`TDTbin2mat_working.m` implementation and the current upstream TDT MATLAB SDK
`TDTbin2mat.m`.

Upstream reference:
- https://github.com/tdtneuro/TDTMatlabSDK

## High-Level Status

- Local file is a **substantial fork**, not a small patch.
- It includes project-specific behavior required by this repository.
- It should not be treated as drop-in equivalent to current upstream.

## Local Additions (Project-Specific)

- Added optional parameters:
  - `DONTREAD`
  - `EXCLUSIVELYREAD`
  - `CHANNELS`
  - `STREAMSWITHLIMITEDCHANNELS`
- Added stream/channel filtering logic tied to those parameters.
- Added `BROA`/`Broa` normalization patch for store-name conflicts.
- Added use of `SEV2mat_working` in stream loading paths.

## Divergence From Upstream Behavior

- Upstream parameter-validation scaffolding differs from local.
- Some upstream options/features are absent in local fork (for example,
  options introduced or maintained in newer upstream revisions).
- No-TSQ handling behavior differs from upstream fallback behavior.
- Platform-specific TSQ cleanup behavior in upstream may not be mirrored
  identically in local.

## Operational Implications

- Replacing local file with upstream can break:
  - selective store loading used by pipeline scripts,
  - channel-limited stream extraction behavior,
  - compatibility with existing local `SEV2mat_working` usage.
- Keeping local fork without tracking upstream updates can miss bug fixes and
  new compatibility work in TDT SDK.

## Recommended Maintenance Policy

1. Treat local file as a maintained fork with explicit change tracking.
2. Keep this document updated when local behavior changes.
3. When updating from upstream:
   - diff upstream and local first,
   - reapply only required local patches,
   - validate key datasets before replacing production copy.

## Suggested Validation Checklist (After Any Update)

- Parameter parsing works for:
  - `EXCLUSIVELYREAD`, `DONTREAD`, `CHANNELS`
- Known problematic stores (`BROA`/`Broa`) are handled as expected.
- Stream extraction parity on representative sessions:
  - timestamps, channel counts, output shape, sample rate.
- Synchronization pipeline still produces expected:
  - `continuous_timestamps`, `continuous_data`, `Trial_timestamps`.
