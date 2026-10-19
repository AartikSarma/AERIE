# AERIE: Augmenting EHR Research with ICU biospEcimens

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
![Maturity](https://img.shields.io/badge/maturity-draft-lightgrey)

AERIE is a biospecimen data standard for the [CLIF Consortium](https://clif-icu.com/). Several CLIF sites hold research biobanks. AERIE puts the assay results from those specimens in two tables that join by patient to the [Common Longitudinal ICU data Format (CLIF)](https://github.com/Common-Longitudinal-ICU-data-Format/CLIF) EHR tables, and it is being developed alongside CLIF 3.0. Investigators can then align a cytokine level or a transcriptome with the ventilator settings, medications, and outcomes CLIF already records.

AERIE is a nested study within the CLIF cohort, and the repository follows CLIF's layout: a data dictionary in `ddl/` and controlled vocabularies (mCIDE, the minimum Common ICU Data Elements) in `mCIDE/`.

## Tables

AERIE 0.1 defines two tables, split by the shape of the result.

**`biomarkers`** holds results that are one value for one named analyte: one row per specimen, study, assay run, and analyte. Each row carries the analyte as recorded (`analyte_name`), its mapping to a minimum set of standardized analytes (`analyte_category`), a standard identifier (`analyte_id`, `analyte_id_type`), and the result as both a string and a number (`result_value`, `result_value_numeric`, `result_unit`). The string column keeps entries such as `<LOD`. ELISA, Luminex, qPCR, and targeted genotyping belong here. So does high-plex affinity proteomics: Olink and SomaScan results go here in long format, one row per protein, even when the vendor delivers them as a matrix.

**`omics`** holds results that live in files: one row per specimen, study, assay run, and file. Each row points to the file (`result_uri`), names its format (`result_format`), and, for files that hold many specimens, gives the key that finds this specimen inside it (`result_specimen_key`). Sequencing, expression and methylation arrays, and metagenomics belong here.

Both tables carry the same specimen and assay columns. `patient_id` is the join key to CLIF; each site maps its biobank participant IDs to CLIF patient IDs during ETL. Most research repositories do not link a specimen to an encounter, so `hospitalization_id` is optional and filled only when the biobank record carries that link. `collect_dttm` is required: it anchors each result against the clinical record, and analysts use it to place a specimen within a hospitalization by comparing it with `admission_dttm` and `discharge_dttm`. `study_name`, `irb_protocol_id`, and `consent_category` record the governance for each pair of specimen and study, so one specimen can appear under several studies. `assay_id` and `sample_batch_name` identify the run and batch for batch-effect modeling.

The full definitions are in [`ddl/0.1/AERIE0.1_MYSQL_ddl.sql`](ddl/0.1/AERIE0.1_MYSQL_ddl.sql). As in CLIF, each column's `COMMENT` holds a JSON description and its permissible values.

### Choosing a table

The `aerie_table` column of [`aerie_assay_categories.csv`](mCIDE/common/aerie_assay_categories.csv) assigns each assay platform to `biomarkers`, `omics`, or `either`. For a platform marked `either`, such as mass-spectrometry proteomics, metabolomics, or cytometry, the deliverable decides. A quantified value for an analyte with a standard identifier goes in `biomarkers`; for cytometry, that means a gated population such as monocyte HLA-DR. A raw or feature-level file goes in `omics`: spectra, untargeted feature tables, FCS files.

## Conventions

AERIE follows CLIF 3.0 conventions. Raw source strings go in `*_name` columns, and each maps to a controlled vocabulary in the paired `*_category` column (`assay_name` → `assay_category` → `assay_group`). Every datetime is timezone-aware and in UTC, formatted `YYYY-MM-DD HH:MM:SS+00:00`. Sites load values as recorded, without clipping or filtering outliers.

## Repository layout

| Path | Contents |
|---|---|
| `ddl/<version>/` | Data dictionary as MySQL DDL |
| `mCIDE/common/` | Vocabularies shared by both tables: specimen, consent, assay platform, assay group, QC status |
| `mCIDE/biomarkers/`, `mCIDE/omics/` | Vocabularies used by one table only |
| `schemas/<version>/` | YAML schemas in [clifpy](https://github.com/Common-Longitudinal-ICU-data-Format/clifpy)'s format, for validating a site's tables |
| `docs/` | Superseded single-table draft, kept for reference |
| `data/` | Synthetic, name-scrambled analyte lists that show the scale of a biomarker panel (77 analytes) and an Olink panel (1,463 assays); they contain no results |
| `scripts/check_consistency.py` | Confirms that the DDL, the mCIDE CSVs, and the YAML schemas agree |

Run the consistency check after editing the DDL, a vocabulary, or a schema:

```bash
uv run scripts/check_consistency.py
```

## Validating a site's tables with clifpy

clifpy loads its built-in schemas by CLIF table name, so it does not find AERIE's on its own. Pass an AERIE schema to clifpy's validator directly:

```python
import yaml
from clifpy.utils.validator import validate_dataframe

schema = yaml.safe_load(open("schemas/0.1/biomarkers_schema.yaml"))
validation_issues = validate_dataframe(biomarkers_df, schema)
```

The validator checks required columns, data types, UTC datetimes, permissible values, and the mapping from `assay_category` to `assay_group`. It also reports each vocabulary value absent from the table as an "mCIDE coverage gap"; a site with blood and urine only will see the other specimen types listed there, which is expected.

## Open questions

- Both tables repeat the specimen and assay columns. A parent `specimen` table and an `assay` table would remove the repetition, at the cost of more joins for sites and analysts.
- `result_unit` has no controlled vocabulary yet.

## License

Apache 2.0, matching CLIF.
