# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

AERIE (Augmenting EHR Research with ICU biospEcimens) is a biospecimen data standard that complements the Common Longitudinal ICU data Format (CLIF) EHR tables. It is a nested study within the CLIF Consortium cohort: several CLIF sites hold biobanks, and AERIE links their assay results to the patients and hospitalizations already in CLIF. GitHub: `AartikSarma/AERIE`.

The repository mirrors the CLIF repo (`Common-Longitudinal-ICU-data-Format/CLIF`): the data dictionary lives in `ddl/<version>/AERIE<version>_MYSQL_ddl.sql`, and controlled vocabularies (mCIDE) live as CSVs under `mCIDE/`. `schemas/<version>/` holds YAML schemas in clifpy's format. There is no application code.

## Commands

```bash
uv run scripts/check_consistency.py   # DDL, mCIDE CSVs, and YAML schemas must agree; exits 1 on mismatch
```

Run it after any edit to the DDL, an mCIDE CSV, or a YAML schema. A change to a column or vocabulary touches all three.

Dependencies are managed with uv (`pyproject.toml`, `uv.lock`); the consistency script also declares its own inline.

## How the DDL, mCIDE, and YAML schemas fit together

Each DDL column has a `COMMENT` holding JSON with `description` and `permissible`, as in CLIF. When a column has a controlled vocabulary, `permissible` is a bracketed list followed by a link to the mCIDE CSV, e.g. `[pass, fail, flagged, na](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/common/aerie_qc_categories.csv)`. The check script parses those links, so the list and the CSV must change together. Comments must stay valid JSON inside single-quoted SQL: avoid both quote characters in descriptions.

mCIDE CSVs follow the CLIF format: `<variable>_category`, `description`, optional `<variable>_name_examples`. Vocabularies used by both tables go in `mCIDE/common/`; table-specific ones in `mCIDE/biomarkers/` or `mCIDE/omics/`.

The YAML schemas follow clifpy's CLIF 3.0 schema files (`clifpy/schemas/3.0/*_schema.yaml`): per-column `data_type`, `required`, `is_category_column`, `is_group_column`, `permissible_values`, then `required_columns`, `category_columns`, `group_columns`, and `assay_category_to_group_mapping`, which clifpy's validator discovers by its `*_category_to_group_mapping` suffix. `version` is the CLIF version, because clifpy stamps it on validation results; `aerie_version` is AERIE's own. clifpy cannot load these by table name, so sites pass the parsed YAML to `clifpy.utils.validator.validate_dataframe`. Which columns are required is recorded only in the YAML, not the DDL.

`mCIDE/common/aerie_assay_categories.csv` is the hub. Its `assay_group` column maps platform to group, and its `aerie_table` column (`biomarkers`, `omics`, `either`) decides which platforms each table's `assay_category` and `assay_group` lists may contain. The check script derives each table's expected lists from it, so add a platform there first.

## Data model decisions

- Two tables, split by result shape, not platform. `biomarkers`: one scalar per (specimen, study, assay run, analyte), with `analyte_*` and `result_value*`/`result_unit`. `omics`: one file pointer per (specimen, study, assay run, file), with `result_uri`, `result_specimen_key`, `result_format`. The single-table draft in `docs/` was rejected as unwieldy; do not reintroduce it.
- Olink and SomaScan go in `biomarkers` in long format, even when delivered as a matrix.
- Vocabularies grow from evidence, not upfront completeness. `analyte_category` (paired with `analyte_name`, like CLIF's `lab_category`) and `specimen_category` start from what the UCSF EARLI biobank inventory contains, plus `other`; the project lead added `bal`, `tracheal_aspirate`, and `nasal_swab`. Add categories when a site's inventory or the project lead calls for them; do not pad lists speculatively. High-plex panels and analytes of unclear meaning map to `other` and are identified by `analyte_id`.
- `specimen_category` records compartment, not component: plasma, serum, and whole blood are all `blood`, as in CLIF's `lab_specimen_category`. Do not split it.
- Derived measures, such as an NNAL-to-creatinine ratio, get no category; analysts calculate them. Measured normalizers (urine creatinine, HME total protein) do get categories.
- Platforms marked `either` (MS proteomics, metabolomics, cytometry) go by deliverable: a quantified value for a standard-ID analyte goes to `biomarkers`, a raw or feature-level file to `omics`.
- `specimen_name` was added beside `specimen_category` to keep CLIF's raw-name/category pairing; the draft lacked it.
- CLIF 3.0 has no tables that overlap with AERIE (confirmed by the project lead, who sits on the CLIF Steering Committee). Do not reopen this.
- Open: whether to factor the repeated specimen and assay columns into parent `specimen`/`assay` tables, and whether `result_unit` needs a vocabulary. Raise these rather than resolve them silently.

## CLIF conventions every AERIE table follows

AERIE is designed in parallel with CLIF 3.0 and follows its conventions. `patient_id` is the join key to CLIF `patient`. `hospitalization_id` is optional, because most research repositories do not link specimens to encounters; analysts assign a hospitalization by comparing the required `collect_dttm` with `hospitalization.admission_dttm`/`discharge_dttm`. Do not write ETL or analysis code that assumes `hospitalization_id` is populated. Every datetime is timezone-aware UTC, `YYYY-MM-DD HH:MM:SS+00:00`. Category values are lowercase snake_case. Consent and IRB scope attach to a (specimen, study) pair.
