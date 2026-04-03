# ADR-006: Graceful Degradation for Cross-Project Compatibility

## Context
TAT is developed while being actively used in other projects (PatchPilot, articles). `install.sh` deploys globally — a single install updates TAT across all projects simultaneously. New features like `state.json` and review gates depend on artifacts that may not exist in projects that haven't been migrated.

## Options Considered
1. Hard fail when artifacts are missing — forces migration but breaks active projects
2. Fail silently when artifacts don't exist — new features opt-in by presence of artifact

## Decision
Option 2: New features fail silently when their artifacts don't exist. A missing `state.json` means the feature is inactive, not an error. A missing review gate config means the gate is skipped.

## Rationale
`install.sh` deploys globally. We cannot gate a global deploy on every active project being migration-ready. Graceful degradation means TAT can ship improvements continuously without coordinating upgrades across all projects. Projects adopt new features by adding the artifact, not by unblocking a deploy.
