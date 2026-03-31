# ADR-006: Graceful Degradation for Cross-Project Compatibility

## Context
TAT is developed in the tinyaiteam repo while actively used in PatchPilot, articles, and oneminuta. install.sh deploys globally — new features land in all projects immediately.

## Options Considered
1. Tagged releases — projects pin to a version, update explicitly
2. Graceful degradation — new features skip silently when artifacts don't exist
3. Both — graceful now, tagged releases later

## Decision
Option 2 (with option 3 as backlog). All new features (state.json, review gates, sprint ceremonies) fail silently when their artifacts don't exist. Projects without state.json are unaffected.

## Rationale
Tagged releases require engineering (version pinning, install logic). Graceful degradation ships immediately and protects active projects. The key insight: `tat-state.sh` returns exit 0 with a skip message instead of exit 1 with an error. This unblocked PatchPilot immediately when state.json was added.
