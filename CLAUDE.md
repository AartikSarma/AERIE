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

Each DDL column has a `COMMENT` holding JSON with `description` and `permissible`, as in CLIF. When a column has a controlled vocabulary, `permissible` is a bracketed list followed by a link to the mCIDE CSV, e.g. `[pass, fail, flagged, na](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/common/aerie_qc_categories.csv)`. The check script parses those links, so the list and the CSV must change together. It also fails on an mCIDE CSV that no column links to, and on a FOREIGN KEY to a table or column the DDL does not define (CLIF `patient` and `hospitalization` excepted). Comments must stay valid JSON inside single-quoted SQL: avoid both quote characters in descriptions.

mCIDE CSVs follow the CLIF format: `<variable>_category`, `description`, optional `<variable>_name_examples`. Each vocabulary lives in `mCIDE/<table>/` for the table that uses it; one used by several tables (QC status) goes in `mCIDE/common/`.

The YAML schemas follow clifpy's CLIF 3.0 schema files (`clifpy/schemas/3.0/*_schema.yaml`): per-column `data_type`, `required`, `is_category_column`, `is_group_column`, `permissible_values`, then `required_columns`, `category_columns`, `group_columns`, and, in `assay_run` only, `assay_category_to_group_mapping`, which clifpy's validator discovers by its `*_category_to_group_mapping` suffix. There is one schema per table. `version` is the CLIF version, because clifpy stamps it on validation results; `aerie_version` is AERIE's own. clifpy cannot load these by table name, so sites pass the parsed YAML to `clifpy.utils.validator.validate_dataframe`. Which columns are required is recorded only in the YAML, not the DDL.

`mCIDE/assay_run/aerie_assay_categories.csv` is the hub. Its `assay_group` column maps platform to group, and its `result_storage` column (`rows`, `matrix`, `either`) says whether a platform's results go to `analyte_result` or to `assay_matrix` files. Add a platform there first.

## Data model decisions

- Six tables, agreed with the sites in #aerie-nested-biobanks (Nov 2026): Katie Lebold's split into `specimen`, `assay_run`, and `analyte_result`, plus `study`, plus `assay_matrix` and `assay_matrix_specimen` for high-plex files. This replaced the earlier two-table `biomarkers`/`omics` model, which repeated the specimen and assay columns in both. The single-table draft in `docs/` was rejected as unwieldy; do not reintroduce it.
- Federated, as in CLIF: nothing is pooled. Matrix files stay at the site; `matrix_uri` is relative to the site AERIE folder.
- AERIE is an easily exported subset, not a rebuild of a site biorepository: one specimen row per collection and specimen type. Aliquots, freezer locations, and chain of custody stay out.
- Targeted assays write rows to `analyte_result`; high-plex assays write specimen-by-feature files listed in `assay_matrix`. Every Olink version (Target 48/96, Explore, Explore HT) uses the matrix approach, as does SomaScan (project lead, Nov 2026). Platforms marked `either` (metabolomics, cytometry) go by deliverable.
- Gene and protein identifiers are not part of the analyte vocabulary or `analyte_result` (project lead, Nov 2026); an analysis that needs them builds the mapping itself. Identifier namespaces survive only as `feature_id_type_category`, which names a matrix's columns.
- Central-lab results belong in CLIF `labs`; AERIE holds research-assay results.
- Consent and `study_id` sit on `specimen`; there is no enrollment table (project lead, Nov 2026).
- Vocabularies grow from evidence, not upfront completeness. `analyte_category` (paired with `analyte_name`, like CLIF's `lab_category`) and `specimen_category` start from what the UCSF EARLI biobank inventory contains, plus `other`; the project lead added `bal`, `tracheal_aspirate`, and `nasal_swab`. Add categories when a site's inventory or the project lead calls for them; do not pad lists speculatively.
- `specimen_category` records compartment, not component: plasma, serum, and whole blood are all `blood`, as in CLIF's `lab_specimen_category`. Do not split it.
- Derived measures, such as an NNAL-to-creatinine ratio, get no category; analysts calculate them. Measured normalizers (urine creatinine, HME total protein) do get categories.
- `specimen_name` was added beside `specimen_category` to keep CLIF's raw-name/category pairing; the draft lacked it.
- CLIF 3.0 has no tables that overlap with AERIE (confirmed by the project lead, who sits on the CLIF Steering Committee). Do not reopen this.
- Open: whether `result_unit` needs a vocabulary, whether raw files (FASTQ, BAM, IDAT, mzML) belong in `assay_matrix`, and whether `specimen` needs `(specimen_id, study_id)` as its key for specimens used under a second study. Raise these rather than resolve them silently.

## CLIF conventions every AERIE table follows

AERIE is designed in parallel with CLIF 3.0 and follows its conventions. `specimen.patient_id` is the join key to CLIF `patient`. `hospitalization_id` is optional, because most research repositories do not link specimens to encounters; analysts assign a hospitalization by comparing the required `collect_dttm` with `hospitalization.admission_dttm`/`discharge_dttm`. Do not write ETL or analysis code that assumes `hospitalization_id` is populated. Every datetime is timezone-aware UTC, `YYYY-MM-DD HH:MM:SS+00:00`. Category values are lowercase snake_case. Consent attaches to the specimen, under the study it was collected under; the IRB protocol is on `study`.
