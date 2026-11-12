-- AERIE 0.1 (draft), developed alongside CLIF 3.0. Six tables: study, specimen, assay_run,
-- analyte_result, assay_matrix, and assay_matrix_specimen. Specimens join to CLIF through
-- patient_id; collect_dttm places each specimen against the patient's hospitalizations.
-- AERIE is federated, as CLIF is: every table and matrix file stays at its site.

-- -----------------------------------------------------
-- Table: study
-- One row per research study or biobank protocol under which a site collected specimens.
-- -----------------------------------------------------
CREATE TABLE study (
  study_id VARCHAR COMMENT '{"description": "Site-assigned identifier for the study.", "permissible": "No restriction"}',
  study_name VARCHAR COMMENT '{"description": "Name of the research study or biobank protocol. May be a short alias, e.g. EARLI.", "permissible": "No restriction"}',
  irb_protocol_id VARCHAR COMMENT '{"description": "Institutional IRB or research ethics board protocol identifier governing the study.", "permissible": "No restriction"}',
  PRIMARY KEY (study_id)
);

-- -----------------------------------------------------
-- Table: specimen
-- One row per collection and specimen type. Aliquots, freezer locations, and chain of
-- custody stay in the site biorepository system.
-- -----------------------------------------------------
CREATE TABLE specimen (
  specimen_id VARCHAR COMMENT '{"description": "Site biobank sample identifier. Format is site-defined.", "permissible": "No restriction"}',
  patient_id VARCHAR COMMENT '{"description": "CLIF patient identifier and the primary join key to CLIF. Sites map biobank participant IDs to patient.patient_id during ETL.", "permissible": "Must match patient.patient_id"}',
  hospitalization_id VARCHAR COMMENT '{"description": "Optional. ID of the encounter during which the specimen was collected. Filled when the biobank record links the specimen to an encounter or when the site derives it from collect_dttm falling inside a CLIF hospitalization; NULL otherwise, since research specimens may be drawn outside a hospitalization. Analysts can assign hospitalizations by comparing collect_dttm with hospitalization.admission_dttm and discharge_dttm.", "permissible": "NULL, or a value of hospitalization.hospitalization_id"}',
  study_id VARCHAR COMMENT '{"description": "Study under which the specimen was collected. The specimen carries the consent for that study, so there is no separate enrollment table.", "permissible": "Must match study.study_id"}',
  collect_dttm DATETIME COMMENT '{"description": "Date and time the specimen was drawn, not processed or received. If the source records only a date, set the time to 00:00:00 in site local time before converting to UTC, so analysts can identify date-only values as local midnight. All datetime variables must be timezone-aware and set to UTC. Required. Anchors each result in time against clinical events in CLIF.", "permissible": "Datetime format should be YYYY-MM-DD HH:MM:SS+00:00 (UTC)"}',
  timepoint_name VARCHAR COMMENT '{"description": "Optional. Study timepoint as recorded in the source, e.g. Day 0 or Day 3.", "permissible": "No restriction"}',
  specimen_name VARCHAR COMMENT '{"description": "Specimen type as recorded in the source biobank, e.g. EDTA plasma.", "permissible": "No restriction"}',
  specimen_category VARCHAR COMMENT '{"description": "Maps specimen_name to a standardized list of specimen compartments.", "permissible": "[blood, hme, bal, tracheal_aspirate, nasal_swab, urine, hair, other](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/specimen/aerie_specimen_categories.csv)"}',
  consent_category VARCHAR COMMENT '{"description": "Type of consent governing use of the specimen under its study. Filter on withdrawn before reading results.", "permissible": "[broad_research, specific_use, opt_out, waiver_of_consent, withdrawn, other](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/specimen/aerie_consent_categories.csv)"}',
  PRIMARY KEY (specimen_id),
  FOREIGN KEY (patient_id) REFERENCES patient(patient_id),
  FOREIGN KEY (hospitalization_id) REFERENCES hospitalization(hospitalization_id),
  FOREIGN KEY (study_id) REFERENCES study(study_id)
);

-- -----------------------------------------------------
-- Table: assay_run
-- One row per assay run. A run stores its results either as rows in analyte_result or as
-- files listed in assay_matrix.
-- -----------------------------------------------------
CREATE TABLE assay_run (
  assay_run_id VARCHAR COMMENT '{"description": "Site-assigned identifier for the assay run.", "permissible": "No restriction"}',
  assay_name VARCHAR COMMENT '{"description": "Assay or platform description from the source, including panel and version, e.g. Olink Explore 3072 or 10x Chromium 3 prime v3.1.", "permissible": "No restriction"}',
  assay_category VARCHAR COMMENT '{"description": "Maps assay_name to a standardized list of assay platforms.", "permissible": "[elisa, luminex, olink, somascan, ms_proteomics, qpcr, snp_genotyping, sanger_sequencing, targeted_sequencing, long_read_sequencing, rna_seq_bulk, rna_seq_single_cell, microarray_expression, gwas_array, wes, wgs, methylation_epic, methylation_450k, lc_ms_metabolomics, gc_ms_metabolomics, nmr_metabolomics, 16s_amplicon, shotgun_metagenomics, flow_cytometry, mass_cytometry, other](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/assay_run/aerie_assay_categories.csv)"}',
  assay_group VARCHAR COMMENT '{"description": "Maps assay_category to a high-level assay group.", "permissible": "[proteomics, transcriptomics, genomics, epigenomics, metabolomics, microbiomics, cytometry, targeted_immunoassay, other](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/assay_run/aerie_assay_groups.csv)"}',
  result_storage_category VARCHAR COMMENT '{"description": "Where the run stores its results: rows in analyte_result, or files in assay_matrix. The result_storage column of the assay mCIDE gives each platform its storage; platforms marked either go by deliverable.", "permissible": "[rows, matrix](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/assay_run/aerie_result_storage_categories.csv)"}',
  assay_dttm DATETIME COMMENT '{"description": "Date and time the assay was performed (optional). All datetime variables must be timezone-aware and set to UTC.", "permissible": "Datetime format should be YYYY-MM-DD HH:MM:SS+00:00 (UTC)"}',
  PRIMARY KEY (assay_run_id)
);

-- -----------------------------------------------------
-- Table: analyte_result
-- One row per specimen, assay run, and analyte for targeted assays: one value for one named analyte.
-- -----------------------------------------------------
CREATE TABLE analyte_result (
  specimen_id VARCHAR COMMENT '{"description": "Specimen the result was measured in.", "permissible": "Must match specimen.specimen_id"}',
  assay_run_id VARCHAR COMMENT '{"description": "Run that produced the result.", "permissible": "Must match assay_run.assay_run_id"}',
  sample_batch_name VARCHAR COMMENT '{"description": "Optional batch identifier within an assay run, e.g. ELISA plate ID. A run may contain several batches. Used for batch-effect modeling.", "permissible": "No restriction"}',
  analyte_name VARCHAR COMMENT '{"description": "Analyte as recorded in the source data, e.g. IL-6.", "permissible": "No restriction"}',
  analyte_category VARCHAR COMMENT '{"description": "Maps analyte_name to a minimum set of standardized analytes. Use other for analytes outside the set; analyte_name then identifies them.", "permissible": "[ang1, ang2, ccl8, cotinine, cx3cl1, cxcl9, d_dimer, e_selectin, gdf15, gm_csf, hydroxycotinine, icam1, ifn_gamma, il1_beta, il1ra, il1r2, il4, il6, il8, il10, il13, il18, il27, ip10, mip1_alpha, mmp8, mmp9, nnal, nnal_free, olfm4, pai1, procalcitonin, protein_c, p_selectin, rage, sp_d, telomere_length, thrombomodulin, tnf_alpha, tnfr1, trem1, triglycerides, vegf, vwf, total_protein, creatinine, aama, cnema, hema, hpma_2, hpma_3, hpmma, mhbma_1_2, mhbma_3, pma, other](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/analyte_result/aerie_analyte_categories.csv)"}',
  result_value VARCHAR COMMENT '{"description": "Result as recorded in the source, kept as a string to preserve non-numeric entries such as <LOD or indeterminate.", "permissible": "No restriction"}',
  result_value_numeric DOUBLE COMMENT '{"description": "Numeric part of result_value. NULL when the result is non-numeric.", "permissible": "Numeric"}',
  result_unit VARCHAR COMMENT '{"description": "Unit of the result. Required when result_value_numeric is non-null.", "permissible": "e.g. pg/mL, ng/mL, mmol/L, percent"}',
  qc_name VARCHAR COMMENT '{"description": "Quality-control note as recorded in the source, e.g. <LOD, Invalid, or Extrapolated. NULL when the source records no note.", "permissible": "No restriction"}',
  qc_category VARCHAR COMMENT '{"description": "Quality-control status of this result.", "permissible": "[pass, fail, flagged, na](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/common/aerie_qc_categories.csv)"}',
  FOREIGN KEY (specimen_id) REFERENCES specimen(specimen_id),
  FOREIGN KEY (assay_run_id) REFERENCES assay_run(assay_run_id)
);

-- -----------------------------------------------------
-- Table: assay_matrix
-- One row per result file from a high-plex run: Olink of any version, SomaScan, sequencing,
-- arrays. Files hold specimens as rows and features as columns and stay in the site AERIE folder.
-- -----------------------------------------------------
CREATE TABLE assay_matrix (
  matrix_id VARCHAR COMMENT '{"description": "Site-assigned identifier for the file.", "permissible": "No restriction"}',
  assay_run_id VARCHAR COMMENT '{"description": "Run that produced the file. A run may have several files, e.g. raw and normalized counts.", "permissible": "Must match assay_run.assay_run_id"}',
  matrix_uri VARCHAR COMMENT '{"description": "Path to the file, relative to the site AERIE folder. Files never leave the site, so the path only has to resolve locally.", "permissible": "No restriction"}',
  file_format_category VARCHAR COMMENT '{"description": "File format of matrix_uri. Use parquet for proteomics and metabolomics and h5ad for transcriptomics where possible.", "permissible": "[csv, tsv, parquet, h5ad, h5, mtx, vcf, bcf, fastq, bam, cram, idat, mzml, na, other](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/assay_matrix/aerie_file_format_categories.csv)"}',
  value_type_category VARCHAR COMMENT '{"description": "What the matrix cells hold.", "permissible": "[concentration, npx, rfu, intensity, log2_intensity, raw_counts, normalized_counts, tpm, other](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/assay_matrix/aerie_value_type_categories.csv)"}',
  feature_id_type_category VARCHAR COMMENT '{"description": "Namespace of the feature identifiers that name the matrix columns.", "permissible": "[uniprot, olink_id, seqid, hgnc, ensembl_gene, ensembl_transcript, chebi, hmdb, kegg, probe_id, ncbi_taxonomy, dbsnp, loinc, other](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/assay_matrix/aerie_feature_id_type_categories.csv)"}',
  annotation_version VARCHAR COMMENT '{"description": "Panel or reference version of the feature identifiers, e.g. Explore 3072 or Ensembl 110.", "permissible": "No restriction"}',
  normalization_method VARCHAR COMMENT '{"description": "Normalization applied, as described by the site. NULL for raw data.", "permissible": "No restriction"}',
  n_specimens INT COMMENT '{"description": "Number of specimen rows in the file, for a check without opening it.", "permissible": "Integer"}',
  n_features INT COMMENT '{"description": "Number of feature columns in the file.", "permissible": "Integer"}',
  feature_annotation_uri VARCHAR COMMENT '{"description": "Optional. Path, relative to the site AERIE folder, to per-feature metadata such as Olink LOD by plate or gene annotations.", "permissible": "No restriction"}',
  file_sha256 VARCHAR COMMENT '{"description": "SHA-256 checksum of the file, so a moved or edited file is caught.", "permissible": "64 hexadecimal characters"}',
  PRIMARY KEY (matrix_id),
  FOREIGN KEY (assay_run_id) REFERENCES assay_run(assay_run_id)
);

-- -----------------------------------------------------
-- Table: assay_matrix_specimen
-- One row per specimen per file. Lets a validator check consent and specimen keys without
-- opening the file. Plate controls and bridging samples may stay in the file without a row here.
-- -----------------------------------------------------
CREATE TABLE assay_matrix_specimen (
  matrix_id VARCHAR COMMENT '{"description": "File that holds the specimen.", "permissible": "Must match assay_matrix.matrix_id"}',
  specimen_id VARCHAR COMMENT '{"description": "Specimen whose row is in the file.", "permissible": "Must match specimen.specimen_id"}',
  result_specimen_key VARCHAR COMMENT '{"description": "Identifier used inside the file for this specimen when it differs from specimen_id, e.g. a VCF sample ID or an AnnData obs index value. NULL when the file uses specimen_id.", "permissible": "No restriction"}',
  sample_batch_name VARCHAR COMMENT '{"description": "Optional batch identifier within an assay run, e.g. Olink plate ID, sequencing flowcell or lane, or library prep batch. Used for batch-effect modeling.", "permissible": "No restriction"}',
  qc_name VARCHAR COMMENT '{"description": "Per-specimen quality-control note as recorded in the source, e.g. an Olink QC warning. NULL when the source records no note.", "permissible": "No restriction"}',
  qc_category VARCHAR COMMENT '{"description": "Quality-control status of this specimen in this file.", "permissible": "[pass, fail, flagged, na](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/common/aerie_qc_categories.csv)"}',
  FOREIGN KEY (matrix_id) REFERENCES assay_matrix(matrix_id),
  FOREIGN KEY (specimen_id) REFERENCES specimen(specimen_id)
);
