# mCIDE: minimum Common ICU Data Elements for AERIE

Each CSV defines the permissible values of one category variable in the AERIE tables. The format follows the [CLIF mCIDE](https://github.com/Common-Longitudinal-ICU-data-Format/CLIF/tree/main/mCIDE): the first column is the category itself, the second is a short description, and an optional third column gives example raw `*_name` values or identifiers that map to it.

| File | Variable | Used by |
|---|---|---|
| `specimen/aerie_specimen_categories.csv` | `specimen_category` | specimen |
| `specimen/aerie_consent_categories.csv` | `consent_category` | specimen |
| `assay_run/aerie_assay_categories.csv` | `assay_category` | assay_run |
| `assay_run/aerie_assay_groups.csv` | `assay_group` | assay_run |
| `assay_run/aerie_result_storage_categories.csv` | `result_storage_category` | assay_run |
| `analyte_result/aerie_analyte_categories.csv` | `analyte_category` | analyte_result |
| `assay_matrix/aerie_file_format_categories.csv` | `file_format_category` | assay_matrix |
| `assay_matrix/aerie_value_type_categories.csv` | `value_type_category` | assay_matrix |
| `assay_matrix/aerie_feature_id_type_categories.csv` | `feature_id_type_category` | assay_matrix |
| `common/aerie_qc_categories.csv` | `qc_category` | analyte_result, assay_matrix_specimen |

`aerie_assay_categories.csv` has two extra columns. `assay_group` maps each platform to its group. `result_storage` says where the platform's results go: `rows` in `analyte_result`, `matrix` files in `assay_matrix`, or `either`, decided by the deliverable.

The analyte and specimen vocabularies are drafts built from the UCSF EARLI biobank inventory. They hold what that biobank contains, plus the respiratory specimens `bal`, `tracheal_aspirate`, and `nasal_swab` and an `other` catch-all; categories for other sites' specimens and analytes are added as those sites join. `specimen_category` records compartment, not component, so plasma, serum, and whole blood are all `blood`; `specimen_name` keeps the detail. The analyte list covers targeted assays only: high-plex results live in matrix files whose columns are named by `feature_id_type_category`. Analytes outside the list map to `other` and are identified by `analyte_name`. Derived measures such as ratios have no category; calculate them at analysis.

After changing a CSV, update the matching permissible lists in the DDL and in `schemas/`, then run `uv run scripts/check_consistency.py` from the repository root. The check also fails if a CSV is not linked from any DDL column.
