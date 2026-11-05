# Blackwell / RTX 50-series porting research

**Status: investigation only — no Blackwell unlock support is implemented or claimed.**

This document records the first source audit of the Windows GPU UNLOCK fork and defines a fail-closed research path. It deliberately does not add a GPU family, firmware selector, machine profile, writable EFI path, PCI/MMIO transaction, or guessed register values.

## Audit snapshot

- Repository: `wall3rsyt/windows-gpu-unlock`
- Base: `main` at `fd8bbea5b1db991805ffcd7ba84e73fa7867bd8a` (2026-11-01)
- Upstream comparison: fork `main` matches upstream `main` at the same commit.
- Existing family catalog: GA102, GA104 and GA106 only (`internal-boot/unlock/gpu-family.h`; `docs/GPU-FAMILIES.en.md`).
- Existing unlock payload is specifically named and pinned as NVIDIA 610.43.03 / GA102: `booter_load_ga102.bin`, `v67-ga102-610.43.03.bin`, `gsp_ga10x.bin`, `gsp_boot_ga102.bin`, `gsp_boot_desc_ga102.bin`.
- Existing firmware/profile layer has fixed AMI templates and exact per-machine PCI, PROM, VRAM, BAR, display-path and driver fingerprints. A GPU-family label alone cannot supply those values.
- The existing transaction/layout implementation is the GA10x/V67 path in `vendor/unlock_610.c`, `layout_610.c` and related files. Its register, Falcon/FWSEC, Booter, GSP and WPR assumptions must not be presumed valid for GB20x.

## What the first audit establishes

1. Adding GB202/GB203/GB205/GB206/GB207 names or PCI IDs to `gpu-family.h` would be unsafe and insufficient.
2. Blackwell needs independently established chip identity/revision, PCI and BAR resource semantics, PROM/VBIOS parsing, driver/GSP/FWSEC payload provenance, memory/WPR layout, console/EDID/nvgop fingerprints, and a separately reviewed transaction.
3. Existing GA10x firmware assets are not Blackwell firmware. Do not rename, patch, or reuse the GA102 assets as a Blackwell payload.
4. No write-enabled profile may be generated from marketing model names, Windows inventory alone, a guessed device ID, or synthetic tests.
5. The read-only inventory reported in upstream issue #151 includes an RTX 5080 (PCI ID `10de:2c02`) as a secondary/display GPU in a dual-GPU machine. It is explicitly inventory-only; no RTX 5080 unlock was attempted or demonstrated.

## Research stages

### Stage A — read-only evidence collection

- Collect exact GPU PCI vendor/device/subsystem/revision IDs and PCI segment:BDF.
- Record BAR0–BAR5 descriptors, sizes and assigned resources from Windows; do not write PCI configuration or MMIO.
- Record board model, BIOS version, CPU, Windows build, NVIDIA driver version, VBIOS version and physical display route.
- Obtain legally sourced, hash-verified public driver/firmware artifacts and document exact versions and licenses. Do not publish private VBIOS/PROM dumps, serials, machine identifiers or raw firmware captures.
- Keep inventory findings separate from pre-boot observations and hardware unlock results.

### Stage B — Blackwell reverse-engineering boundary

- Identify whether the Blackwell driver exposes the same firmware image families, formats and versioned symbols/structures as the existing GA10x path.
- Determine whether the FWSEC/Falcon engine map, security state machine, DMA descriptors, Booter signing/patch process, GSP boot descriptor and WPR2 layout changed.
- Establish a Blackwell-specific layout model from evidence and independent reference implementations; do not extrapolate the 610.43.03 GA102 offsets.
- Identify the exact console/GOP/EDID ownership graph and driver code fingerprints for the target board/BIOS.
- Document unknowns and negative results. No register writes or device release during this stage.

### Stage C — host-only implementation and validation

- Keep Blackwell identity parsing separate from write eligibility.
- Add parsers and layout calculations only after their input formats and invariants are evidenced.
- Add positive and negative unit tests for malformed images, truncated sections, unsupported revisions, integer overflow, resource bounds, identity drift and mismatched firmware hashes.
- Ensure every unknown or ambiguous case fails closed before PCI/MMIO writes, bus mastering, DMA allocation, driver release or FLR.
- Preserve the existing GA10x regression suite unchanged and prove no behavior regression.

### Stage D — hardware qualification (separate authorization required)

- Require exact card, PROM, board, BIOS, PCI topology, display path and driver/firmware fingerprints.
- Require multiple cold-boot read-only captures and complete host replay for that exact profile.
- Only after independent review should a separately authorized, recoverable hardware experiment be considered.
- Report hardware results, recovery, Windows driver rebind, controlled locked/unlocked benchmarks and repeatability separately. A host-test pass is not a hardware success.

## Current blockers / next evidence needed

- No GB20x family implementation or verified Blackwell firmware asset set exists in this repository snapshot.
- No Blackwell-specific firmware/GSP/FWSEC register map or memory-layout evidence has been established by this audit.
- No Blackwell machine profile, host fixture, hardware success report or recovery evidence exists here.
- The next useful contribution is a sanitized, read-only RTX 50-series compatibility inventory plus traceable, legally obtained driver/firmware version references. This does not authorize or attempt an unlock.

## Safety rule

Until the above evidence exists, Blackwell remains **unsupported / not assessed**. Do not attempt to boot a modified EFI on an RTX 50-series card, force a GA10x profile, change PROM hashes, bypass guards, flash a VBIOS, or test guessed register offsets. Such changes can hang the GPU, lose display output or leave the device requiring a full power removal.
