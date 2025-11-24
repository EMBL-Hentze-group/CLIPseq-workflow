# CLIP workflow

This is a Nextflow workflow for processing CLIP-seq data. This workflow is designed to support multiple CLIP protocols

## Shoji branch
run shoji for downstream processing and crosslink site extraction on aligned BAM files.

## Workflow steps:

- Demultiplexing *optional*
    - [x] mix of umi_tools and flexbar (only for iCLIP protocol currently)
- Quality Control
    - [x] FastQC
    - [x] MultiQC
- UMI pre-processing *optional*
    - [ ] umi-tools
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
    - [x] from raw data to aligned/deduplicated and kraken report

## Includes builtin profiles for:

### Protocols:

- [x] eCLIP
- [x] iCLIP
- [x] soniCLIP
- [ ] R2-CLIP

### Genomes:
- [x] hsa (hg38)
- [ ] hsa (rRNA genome)
- [ ] rno


## Running the workflow

Make sure that Nextflow and Singularity are installed.

Nextflow version tested: [`25.04.6`](https://github.com/nextflow-io/nextflow/releases/tag/v25.04.6)

:warning: on EMBL HPC, make sure that the shell is clean, ie no conda/mamba paths are set, as this can interefere with JRE, giving weird errors.

For example submission scripts to run the pipeline, see repository [Clip-seq Nextflow Submission](https://git.embl.org/grp-hentze/workflows/clip-seq-nextflow-submission) and make sure to browse to the branches in the repository.