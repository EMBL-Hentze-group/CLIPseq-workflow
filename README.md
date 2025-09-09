# CLIP workflow

This is a Nextflow workflow for processing CLIP-seq data. This workflow is designed to support multiple CLIP protocols

## Workflow steps:
- [x] Quality Control (FastQC, MultiQC)
- [ ] UMI pre-processing (umi-tools) *optional*
- Adapter and Quality Trimming
    - [x] fastp
    - [ ] cutadapt (to be fully implemented)
- [x] Fastq data sketching and similarity comparison (sourmash)
- [x] rRNA filtering (bbduk)
- [x] Alignment (STAR)
- [x] Unmapped reads contamination estimation (Kraken2)
- [x] UMI deduplication (umi-tools) *optional*
- [x] Annotation and sliding window processing (shoji)
- [x] crosslink sites extraction and count estimation (shoji)
- [x] create R-friendly matrices (shoji)
- [x] Tracks from crosslink sites
- [ ] Final stats report

## Includes builtin profiles for:

### Protocols:

- [x] eCLIP
- [x] soniCLIP
- [ ] R2-CLIP

### Genomes:
- [x] hsa (hg38)
- [ ] rno