# mCIDE: minimum Common ICU Data Elements for AERIE

Each CSV defines the permissible values of one category variable in the AERIE tables. The format follows the [CLIF mCIDE](https://github.com/Common-Longitudinal-ICU-data-Format/CLIF/tree/main/mCIDE): the first column is the category itself, the second is a short description, and an optional third column gives example raw `*_name` values that map to it.

| File | Variable | Used by |
|---|---|---|
| `common/aerie_specimen_categories.csv` | `specimen_category` | biomarkers, omics |
| `common/aerie_consent_categories.csv` | `consent_category` | biomarkers, omics |
| `common/aerie_assay_categories.csv` | `assay_category` | biomarkers, omics |
| `common/aerie_assay_groups.csv` | `assay_group` | biomarkers, omics |
| `common/aerie_qc_categories.csv` | `qc_category` | biomarkers, omics |
| `biomarkers/aerie_biomarkers_analyte_categories.csv` | `analyte_category` | biomarkers |
| `biomarkers/aerie_biomarkers_analyte_id_types.csv` | `analyte_id_type` | biomarkers |

The analyte and specimen vocabularies are drafts built from the UCSF EARLI biobank inventory. They hold what that biobank contains, plus the respiratory specimens `bal`, `tracheal_aspirate`, and `nasal_swab` and an `other` catch-all; categories for other sites' specimens and analytes are added as those sites join. `specimen_category` records compartment, not component, so plasma, serum, and whole blood are all `blood`. High-plex panels such as Olink map to `other` and rely on `analyte_id` rather than a category per protein. Derived measures such as ratios have no category; calculate them at analysis.
| `omics/aerie_omics_result_formats.csv` | `result_format` | omics |

`aerie_assay_categories.csv` has two extra columns. `assay_group` maps each platform to its group. `aerie_table` says which table the platform's results belong in: `biomarkers`, `omics`, or `either`.

After changing a CSV, update the matching permissible lists in the DDL and in `schemas/`, then run `uv run scripts/check_consistency.py` from the repository root.
