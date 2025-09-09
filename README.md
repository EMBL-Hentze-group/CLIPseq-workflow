# CLIP workflow

This is a Nextflow workflow for processing CLIP-seq data. This workflow is designed to support multiple CLIP protocols

## Workflow steps:
- Quality Control
    - [x] FastQC
    - [x] MultiQC
- UMI pre-processing *optional*
    - [x] umi-tools
- Adapter and Quality Trimming
    - [x] fastp
    - [ ] cutadapt (to be fully implemented)
- Fastq data sketching and similarity comparison
    - [x] sourmash
- rRNA filtering
    - [x] bbduk
- Alignment
    - [x] STAR
-  Contamination estimation
    - [x] Kraken2 (on unmapped reads)
- UMI deduplication *optional*
    - [x] umi-tools
- Downstream processing
    - [x] Annotation and sliding window processing (shoji) 
    - [x] crosslink sites extraction and count estimation (shoji)
    - [x] create R-friendly matrices (shoji)
    - [x] Tracks from crosslink sites
- Final stats report
    - [ ] to be implemented

## Includes builtin profiles for:

### Protocols:

- [x] eCLIP
- [x] soniCLIP
- [ ] R2-CLIP

### Genomes:
- [x] hsa (hg38)
- [ ] rno