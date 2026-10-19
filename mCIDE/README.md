# mCIDE: minimum Common ICU Data Elements for AERIE

Each CSV defines the permissible values of one category variable in the AERIE tables. The format follows the [CLIF mCIDE](https://github.com/Common-Longitudinal-ICU-data-Format/CLIF/tree/main/mCIDE): the first column is the category itself, the second is a short description, and an optional third column gives example raw `*_name` values that map to it.

| File | Variable | Used by |
|---|---|---|
| `common/aerie_specimen_categories.csv` | `specimen_category` | biomarkers, omics |
| `common/aerie_consent_categories.csv` | `consent_category` | biomarkers, omics |
| `common/aerie_assay_categories.csv` | `assay_category` | biomarkers, omics |
| `common/aerie_assay_groups.csv` | `assay_group` | biomarkers, omics |
| `common/aerie_qc_categories.csv` | `qc_category` | biomarkers, omics |
| `biomarkers/aerie_biomarkers_analyte_id_types.csv` | `analyte_id_type` | biomarkers |
| `omics/aerie_omics_result_formats.csv` | `result_format` | omics |

`aerie_assay_categories.csv` has two extra columns. `assay_group` maps each platform to its group. `aerie_table` says which table the platform's results belong in: `biomarkers`, `omics`, or `either`.

After changing a CSV, update the matching permissible list in the DDL and run `uv run scripts/check_ddl_mcide.py` from the repository root.
