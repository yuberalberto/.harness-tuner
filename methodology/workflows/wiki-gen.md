---
description: Auto-generate and maintain a project wiki from code, specs, and documentation
---

# Wiki Gen — Self-Documenting Wiki

This workflow generates and maintains a project wiki from code, specs, and documentation.

## Trigger

Invoke this workflow after completing a feature, before releases, or when onboarding new team members. Usage: `/wiki-gen [scope: full | module-name]`

## Steps

### Step 1: Scan Project Artifacts

- Scan specs/ for completed specifications
- Scan source code for docstrings and type annotations
- Scan tests/ for test descriptions and coverage
- Scan rules/ for standards documentation
- Scan existing docs/ for supplementary documentation
- **Output**: Inventory of all documentable artifacts

### Step 2: Generate Wiki Structure

Create wiki outline based on findings:
```
docs/wiki/
├── index.md           — Project overview and navigation
├── architecture.md    — System architecture
├── api-reference.md   — API endpoints and contracts
├── data-models.md     — Data model documentation
├── features/          — Per-feature documentation
│   └── [feature].md   — Generated from specs
├── standards.md       — Team standards summary
└── getting-started.md — Setup and onboarding
```
- **Output**: Wiki structure definition

### Step 3: Generate Each Page

For each page in the structure:
- Pull information from relevant source artifacts
- Cross-reference between pages (linked navigation)
- Include code examples where relevant
- Keep language clear and concise
- **Output**: Generated wiki pages

### Step 4: Validate Completeness

- Every public API endpoint is documented
- Every data model is documented
- Every completed spec has a feature page
- All cross-references resolve
- No placeholder text remaining
- **Output**: Validation report

### Step 5: Output to docs/wiki/

- Write all generated pages to `docs/wiki/`
- Generate index.md with table of contents
- Include last-updated timestamps
- **Output**: Complete wiki in docs/wiki/

## Output

At completion:
- Complete project wiki in `docs/wiki/`
- Auto-generated from source code, specs, and standards
- Cross-referenced and navigable
- Ready for team consumption
