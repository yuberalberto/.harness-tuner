# add-cascade-adapter Issues

## Dependency Graph

```
02 ✅─┐
     ├─→ 04 ✅─→ 05 ✅─┐
03 ✅─┘    │          ├─→ 07 ✅
          └──────────┘

01 ✅   (no blockers)
06 ✅*  (no blockers)
```

## Status Table

| Issue | Title | Type | Status | Blocked By |
|-------|-------|------|--------|------------|
| 01 | Remove context7 + apply verb-first naming | AFK | done | — |
| 02 | Create templates-cascade/rules/ | AFK | done | — |
| 03 | Create templates-cascade/hooks/ | AFK | done | — |
| 04 | Implement `ht init -Agent cascade` | AFK | done | 02, 03 |
| 05 | Implement `ht update -Agent cascade` | AFK | done | 04 |
| 06 | Fix `ht update` batch confirmation | AFK | done | — |
| 07 | Update README for Cascade support | AFK | done | 04, 05 |
