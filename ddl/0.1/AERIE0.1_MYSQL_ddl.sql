-- AERIE 0.1 (draft). Tables extend CLIF 2.1: patient_id and hospitalization_id
-- reference the CLIF patient and hospitalization tables.

-- -----------------------------------------------------
-- Table: biomarkers
-- One row per specimen, study, assay run, and analyte. Holds every result that is a
-- single value for a named analyte, including high-plex affinity proteomics (Olink, SomaScan).
-- -----------------------------------------------------
CREATE TABLE biomarkers (
  patient_id VARCHAR COMMENT '{"description": "Unique identifier for each patient. Matches patient.patient_id.", "permissible": "No restriction"}',
  hospitalization_id VARCHAR COMMENT '{"description": "ID variable for the encounter during which the specimen was collected. NULL permitted for outpatient or post-discharge draws that remain part of the AERIE substudy.", "permissible": "Must match hospitalization.hospitalization_id when non-null"}',
  specimen_id VARCHAR COMMENT '{"description": "Site biobank sample identifier. Format is site-defined.", "permissible": "No restriction"}',
  collect_dttm DATETIME COMMENT '{"description": "Date and time of specimen collection. All datetime variables must be timezone-aware and set to UTC. Primary anchor for time-aligning results to clinical events in other CLIF tables.", "permissible": "Datetime format should be YYYY-MM-DD HH:MM:SS+00:00 (UTC)"}',
  specimen_name VARCHAR COMMENT '{"description": "Specimen type as recorded in the source biobank, e.g. EDTA plasma.", "permissible": "No restriction"}',
  specimen_category VARCHAR COMMENT '{"description": "Maps specimen_name to a standardized list of specimen types.", "permissible": "[whole_blood, plasma, serum, pbmc, urine, csf, bal, tracheal_aspirate, sputum, stool, saliva, tissue, nasal_swab, other](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/common/aerie_specimen_categories.csv)"}',
  study_name VARCHAR COMMENT '{"description": "Name of the research study under which this row was generated. May be a short alias, e.g. AERIE_Pilot_2024. The same specimen may appear under multiple study_name values.", "permissible": "No restriction"}',
  irb_protocol_id VARCHAR COMMENT '{"description": "Institutional IRB or research ethics board protocol identifier governing this specimen under the named study.", "permissible": "No restriction"}',
  consent_category VARCHAR COMMENT '{"description": "Type of consent governing use of the specimen under the named study.", "permissible": "[broad_research, specific_use, opt_out, waiver_of_consent, withdrawn, other](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/common/aerie_consent_categories.csv)"}',
  assay_id VARCHAR COMMENT '{"description": "Identifier for the assay run. Repeated across all rows derived from the same run.", "permissible": "No restriction"}',
  sample_batch_name VARCHAR COMMENT '{"description": "Optional batch identifier within an assay run, e.g. ELISA plate or Olink plate ID. An assay run may contain several batches. Used for batch-effect modeling.", "permissible": "No restriction"}',
  assay_dttm DATETIME COMMENT '{"description": "Date and time the assay was performed (optional). All datetime variables must be timezone-aware and set to UTC.", "permissible": "Datetime format should be YYYY-MM-DD HH:MM:SS+00:00 (UTC)"}',
  assay_name VARCHAR COMMENT '{"description": "Assay or platform description from the source, e.g. Olink Explore 3072.", "permissible": "No restriction"}',
  assay_category VARCHAR COMMENT '{"description": "Maps assay_name to a standardized list of assay platforms. Only platforms whose aerie_table is biomarkers or either belong in this table.", "permissible": "[elisa, luminex, olink, somascan, ms_proteomics, qpcr, snp_genotyping, lc_ms_metabolomics, gc_ms_metabolomics, nmr_metabolomics, flow_cytometry, mass_cytometry, other](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/common/aerie_assay_categories.csv)"}',
  assay_group VARCHAR COMMENT '{"description": "Maps assay_category to a high-level assay group.", "permissible": "[proteomics, transcriptomics, genomics, metabolomics, cytometry, targeted_immunoassay, other](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/common/aerie_assay_groups.csv)"}',
  analyte_name VARCHAR COMMENT '{"description": "Analyte as recorded in the source data, e.g. an Olink assay name or SomaScan SeqId.", "permissible": "No restriction"}',
  analyte_id VARCHAR COMMENT '{"description": "Standard ontology identifier for the analyte.", "permissible": "e.g. UniProt P05231, HGNC IL6, ChEBI CHEBI:17234, dbSNP rs7412"}',
  analyte_id_type VARCHAR COMMENT '{"description": "Namespace for analyte_id.", "permissible": "[uniprot, hgnc, ensembl_gene, ensembl_transcript, chebi, hmdb, kegg, ncbi_taxonomy, dbsnp, loinc, other](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/biomarkers/aerie_biomarkers_analyte_id_types.csv)"}',
  result_value VARCHAR COMMENT '{"description": "Result as recorded in the source, kept as a string to preserve non-numeric entries such as <LOD or indeterminate.", "permissible": "No restriction"}',
  result_value_numeric DOUBLE COMMENT '{"description": "Numeric part of result_value. NULL when the result is non-numeric.", "permissible": "Numeric"}',
  result_unit VARCHAR COMMENT '{"description": "Unit of the result. Required when result_value_numeric is non-null.", "permissible": "e.g. pg/mL, NPX, RFU, log2_intensity, mmol/L, percent, count"}',
  qc_category VARCHAR COMMENT '{"description": "Quality-control status of this result.", "permissible": "[pass, fail, flagged, na](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/common/aerie_qc_categories.csv)"}',
  FOREIGN KEY (patient_id) REFERENCES patient(patient_id),
  FOREIGN KEY (hospitalization_id) REFERENCES hospitalization(hospitalization_id)
);

-- -----------------------------------------------------
-- Table: omics
-- One row per specimen, study, assay run, and result file. Points to matrix-style
-- results (reads, arrays, count matrices, spectra) stored outside the table.
-- -----------------------------------------------------
CREATE TABLE omics (
  patient_id VARCHAR COMMENT '{"description": "Unique identifier for each patient. Matches patient.patient_id.", "permissible": "No restriction"}',
  hospitalization_id VARCHAR COMMENT '{"description": "ID variable for the encounter during which the specimen was collected. NULL permitted for outpatient or post-discharge draws that remain part of the AERIE substudy.", "permissible": "Must match hospitalization.hospitalization_id when non-null"}',
  specimen_id VARCHAR COMMENT '{"description": "Site biobank sample identifier. Format is site-defined.", "permissible": "No restriction"}',
  collect_dttm DATETIME COMMENT '{"description": "Date and time of specimen collection. All datetime variables must be timezone-aware and set to UTC. Primary anchor for time-aligning results to clinical events in other CLIF tables.", "permissible": "Datetime format should be YYYY-MM-DD HH:MM:SS+00:00 (UTC)"}',
  specimen_name VARCHAR COMMENT '{"description": "Specimen type as recorded in the source biobank, e.g. PAXgene RNA tube.", "permissible": "No restriction"}',
  specimen_category VARCHAR COMMENT '{"description": "Maps specimen_name to a standardized list of specimen types.", "permissible": "[whole_blood, plasma, serum, pbmc, urine, csf, bal, tracheal_aspirate, sputum, stool, saliva, tissue, nasal_swab, other](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/common/aerie_specimen_categories.csv)"}',
  study_name VARCHAR COMMENT '{"description": "Name of the research study under which this row was generated. May be a short alias, e.g. AERIE_Pilot_2024. The same specimen may appear under multiple study_name values.", "permissible": "No restriction"}',
  irb_protocol_id VARCHAR COMMENT '{"description": "Institutional IRB or research ethics board protocol identifier governing this specimen under the named study.", "permissible": "No restriction"}',
  consent_category VARCHAR COMMENT '{"description": "Type of consent governing use of the specimen under the named study.", "permissible": "[broad_research, specific_use, opt_out, waiver_of_consent, withdrawn, other](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/common/aerie_consent_categories.csv)"}',
  assay_id VARCHAR COMMENT '{"description": "Identifier for the assay run. Repeated across all rows derived from the same run.", "permissible": "No restriction"}',
  sample_batch_name VARCHAR COMMENT '{"description": "Optional batch identifier within an assay run, e.g. sequencing flowcell or lane, library prep batch, or normalization cohort. Used for batch-effect modeling.", "permissible": "No restriction"}',
  assay_dttm DATETIME COMMENT '{"description": "Date and time the assay was performed (optional). All datetime variables must be timezone-aware and set to UTC.", "permissible": "Datetime format should be YYYY-MM-DD HH:MM:SS+00:00 (UTC)"}',
  assay_name VARCHAR COMMENT '{"description": "Assay or platform description from the source, e.g. 10x Chromium 3 prime v3.1.", "permissible": "No restriction"}',
  assay_category VARCHAR COMMENT '{"description": "Maps assay_name to a standardized list of assay platforms. Only platforms whose aerie_table is omics or either belong in this table.", "permissible": "[ms_proteomics, sanger_sequencing, targeted_sequencing, long_read_sequencing, rna_seq_bulk, rna_seq_single_cell, microarray_expression, gwas_array, wes, wgs, methylation_epic, methylation_450k, lc_ms_metabolomics, gc_ms_metabolomics, nmr_metabolomics, 16s_amplicon, shotgun_metagenomics, flow_cytometry, mass_cytometry, other](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/common/aerie_assay_categories.csv)"}',
  assay_group VARCHAR COMMENT '{"description": "Maps assay_category to a high-level assay group.", "permissible": "[proteomics, transcriptomics, genomics, epigenomics, metabolomics, microbiomics, cytometry, other](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/common/aerie_assay_groups.csv)"}',
  result_uri VARCHAR COMMENT '{"description": "Path, URL, or accession for the result file. Any scheme is permitted, e.g. s3://, gs://, /mnt/, GSE12345, PXD012345.", "permissible": "No restriction"}',
  result_specimen_key VARCHAR COMMENT '{"description": "For multi-specimen files, the identifier used inside the file to locate this specimen, e.g. a count-matrix column header, a VCF sample ID, or a value of obs[sample_id] in an AnnData. NULL if the file holds one specimen or uses specimen_id directly.", "permissible": "No restriction"}',
  result_format VARCHAR COMMENT '{"description": "File format of result_uri.", "permissible": "[csv, tsv, parquet, h5ad, h5, mtx, vcf, bcf, fastq, bam, cram, idat, mzml, na, other](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/omics/aerie_omics_result_formats.csv)"}',
  qc_category VARCHAR COMMENT '{"description": "Quality-control status of this result file.", "permissible": "[pass, fail, flagged, na](https://github.com/AartikSarma/AERIE/blob/main/mCIDE/common/aerie_qc_categories.csv)"}',
  FOREIGN KEY (patient_id) REFERENCES patient(patient_id),
  FOREIGN KEY (hospitalization_id) REFERENCES hospitalization(hospitalization_id)
);
