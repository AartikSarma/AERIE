# Draft: unified `research_biospecimens` table (superseded)

This is the earlier single-table draft, kept verbatim as the source for the split into separate biomarker and omics tables. Do not implement it as one table.

| Column | Type | Description | Permissible values |
|---|---|---|---|
| patient_id | VARCHAR | Unique identifier for each patient. Matches patient.patient_id. | No restriction |
| hospitalization_id | VARCHAR | ID variable for the encounter during which the specimen was collected. NULL permitted for outpatient or post-discharge draws that remain part of the AERIE substudy. | Must match hospitalization.hospitalization_id when non-null |
| specimen_id | VARCHAR | Site biobank sample identifier. Format is site-defined. | No restriction |
| collect_dttm | DATETIME | Date and time of specimen collection. All datetime variables must be timezone-aware and set to UTC. Primary anchor for time-aligning results to clinical events in other CLIF tables. | YYYY-MM-DD HH:MM:SS+00:00 (UTC) |
| study_name | VARCHAR | Name of the research study under which this row's result was generated. May be a short alias (e.g., "AERIE_Pilot_2024") rather than a full title. The same specimen may appear under multiple study_name values across rows. | No restriction |
| irb_protocol_id | VARCHAR | Institutional IRB or research ethics board protocol identifier governing this specimen's use under the named study. | No restriction |
| consent_category | VARCHAR | Type of consent governing the specimen's use under the named study. | broad_research, specific_use, opt_out, waiver_of_consent, withdrawn, other |
| specimen_category | VARCHAR | Maps the specimen type to a standardized list. | whole_blood, plasma, serum, pbmc, urine, csf, bal, tracheal_aspirate, sputum, stool, saliva, tissue, nasal_swab, other |
| assay_id | VARCHAR | Identifier for the assay run/batch. Repeated across all rows derived from the same run. Enables future linkage to a normalized assay-metadata table. | No restriction |
| sample_batch_name | VARCHAR | Optional batch identifier for grouping specimens within an assay run (e.g., ELISA plate ID, sequencing flowcell or lane, library prep batch, normalization cohort). Distinct from assay_id: an assay run may contain multiple batches, and batches may be shared across assays. Useful for batch-effect modeling. | No restriction |
| assay_dttm | DATETIME | Date and time the assay was performed. Optional. All datetime variables must be timezone-aware and set to UTC. | YYYY-MM-DD HH:MM:SS+00:00 (UTC) |
| assay_name | VARCHAR | Raw assay/platform description from the source (e.g., "Olink Explore 3072 Inflammation panel"). | No restriction |
| assay_category | VARCHAR | Maps assay_name to a standardized list of assay platforms. | elisa, luminex, olink, somascan, ms_proteomics, qpcr, snp_genotyping, sanger_sequencing, targeted_sequencing, long_read_sequencing, rna_seq_bulk, rna_seq_single_cell, microarray_expression, gwas_array, wes, wgs, methylation_epic, methylation_450k, lc_ms_metabolomics, gc_ms_metabolomics, nmr_metabolomics, 16s_amplicon, shotgun_metagenomics, flow_cytometry, mass_cytometry, other |
| assay_group | VARCHAR | High-level grouping of assay platforms. | proteomics, transcriptomics, genomics, epigenomics, metabolomics, microbiomics, cytometry, targeted_immunoassay, other |
| analyte_name | VARCHAR | Raw analyte string from the source data. NULL for file-pointer rows. | No restriction |
| analyte_id | VARCHAR | Standard ontology identifier for the analyte. NULL for file-pointer rows. | E.g., UniProt P05231, HGNC IL6, Ensembl ENSG00000136244, ChEBI CHEBI:17234, dbSNP rs7412 |
| analyte_id_type | VARCHAR | Namespace for analyte_id. | uniprot, hgnc, ensembl_gene, ensembl_transcript, chebi, hmdb, kegg, ncbi_taxonomy, dbsnp, loinc, other |
| result_value | VARCHAR | Raw scalar result as a string. Preserves non-numeric entries (e.g., "<LOD", "indeterminate"). NULL for file-pointer rows. | No restriction |
| result_value_numeric | DOUBLE | Parsed numeric scalar result. NULL for file-pointer or non-numeric rows. | Numeric |
| result_unit | VARCHAR | Reference unit for the scalar result. Required when result_value_numeric is non-null. NULL for file-pointer rows. | E.g., pg/mL, NPX, log2_intensity, mmol/L, count |
| result_uri | VARCHAR | Path, URL, or accession for matrix-style results. Any scheme is permitted (e.g., s3://, gs://, /mnt/..., GSE12345, PXD012345). NULL for scalar rows. | No restriction |
| result_specimen_key | VARCHAR | For multi-specimen files: the identifier used inside the file to locate this specimen's data (e.g., a column header in a count matrix, a sample ID in a VCF, a value in obs['sample_id'] of an AnnData). NULL if the file is single-specimen or uses specimen_id directly. | No restriction |
| result_format | VARCHAR | File format for result_uri. | csv, tsv, parquet, h5ad, h5, mtx, vcf, bcf, fastq, bam, cram, idat, mzml, na, other |
| qc_category | VARCHAR | QC status for this result. | pass, fail, flagged, na |
