# CLIP workflow

This is a Nextflow workflow for processing CLIP-seq data. This workflow is designed to support multiple CLIP protocols

## Workflow steps:
- [x] Quality Control (FastQC, MultiQC)
- [] UMI pre-processing (optional)
- [x] Adapter and Quality Trimming (fastp, to be fully implemented: cutadapt)
- [x] rRNA filtering (bbduk)
- [x] Alignment (STAR)
- [x] Unmapped reads contamination estimation (Kraken2)
- [x] UMI deduplication (optional)
- [x] Fastq data sketchin and similarity comparison (sourmash)
- [x] Annotation and sliding window processing (shoji)
- [x] crosslink sites extraction and count estimation (shoji)
- [x] creating R-friendly matrices (shoji)
- [x] Tracks from crosslink sites
- [] Final stats report

## Includes builtin profiles for:

### Protocols:

- [x] eCLIP
- [x] soniCLIP
- [] R2-CLIP

### Genomes:
- [x] hsa (hg38)
- [] rno