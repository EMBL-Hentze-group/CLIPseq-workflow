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
    - [x] umi-tools (for R2-CLIP protocol)
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

- [x] [eCLIP](conf/protocol/eCLIP.config)
- [x] [iCLIP](conf/protocol/iCLIP.config)
- [x] [R2-CLIP](conf/protocol/R2CLIP.config)
- [x] [soniCLIP](conf/protocol/soniCLIP.config)


### Genomes:
- [x] [hsa (hg38)](https://www.gencodegenes.org/human/release_42.html)
- [ ] [hsa (rRNA genome)](https://doi.org/10.1016/j.jbc.2023.104766)
- [ ] rno


## Workflow

Make sure that Nextflow and Singularity are installed.

Nextflow version(s) tested: 
- [`25.04.6`](https://github.com/nextflow-io/nextflow/releases/tag/v25.04.6)
- [`25.10.1`](https://github.com/nextflow-io/nextflow/releases/tag/v25.10.1)

:warning: on EMBL HPC, make sure that the shell is clean, ie no conda/mamba paths are set, as this can interefere with JRE, giving weird errors.

For example submission scripts to run the pipeline, see repository [Clip-seq Nextflow Submission](https://git.embl.org/grp-hentze/workflows/clip-seq-nextflow-submission) and make sure to browse to the branches in the repository.

### Sample sheet format

This workflow uses [nf-schema](https://nextflow-io.github.io/nf-schema/latest/) plugin and the supported sample sheet format.

#### eCLIP, R2-CLIP and soniCLIP
For `eCLIP`, `R2-CLIP` and `soniCLIP` protocols, the following columns (in csv) is expected:
|sample|fastq_1|fastq_2|
|------|-------|-------|
|sample1|/path/to/sample1_R1.fastq.gz| /path/to/sample1_R2.fastq.gz|

- `eCLIP`: `fastq_2` column **MUST be** provided.
- `R2-CLIP` uses `fastq_1` for acutal reads, and `fastq_2` is expected to contain only UMIs. [umi_tools `extract`](https://umi-tools.readthedocs.io/en/latest/reference/extract.html) is used to extract UMIs from `fastq_2` (based on parameter `bc_pattern` in [config file](conf/protocol/R2CLIP.config)) and add them to `fastq_1` headers and are then processed as regular single-end reads.
- `soniCLIP` only uses `fastq_1`


#### iCLIP
For `iCLIP` protocol, the following columns (in csv) is expected:

|fastq|barcode|
|------|-------|
|/path/to/run1.fastq.gz| /path/to/run1_barcode.fa|

- `fastq` column contains the path to the raw, un-demultiplexed fastq files.
- `barcode` column contains the path to the fasta file with barcodes for demultiplex

`barcode` fasta file format example:
```
>sample_1
NNNNATATATATNN
>sample_2
NNNNCGCGCGCGNN
```
[flexbar](https://github.com/seqan/flexbar) is  used for demultiplexing iCLIP data based on the provided barcodes with corresponding header as sample name. UMIs (`N`s in the sequences) are extracted from the reads during demultiplexing and added to fastq header.

### Running the workflow
Given below are example commands to run the workflow with data from supported CLIP protocols.

#### eCLIP with human genome (hg38) on SLURM
```bash
# -bg to run in background
nextflow -bg run main.nf -profile slurm,eCLIP,hsa \
    --input /path/to/sample_sheet.csv \
    -output-dir /path/to/output \
    -work-dir /path/to/work \
    -with-timeline -with-report -with-trace
```

#### iCLIP with human genome (hg38) on SLURM
```bash
nextflow -bg run main.nf -profile slurm,iCLIP,hsa \
    --input /path/to/sample_sheet.csv \
    -output-dir /path/to/output \
    -work-dir /path/to/work \
    -with-timeline -with-report -with-trace
```

#### R2-CLIP with human genome (hg38) on SLURM without rRNA filtering
```bash
nextflow -bg run main.nf -profile slurm,R2CLIP,hsa \
    --input /path/to/sample_sheet.csv \
    --rRNA_trim false \
    -output-dir /path/to/output \
    -work-dir /path/to/work \
    -with-timeline -with-report -with-trace
```

#### soniCLIP with human genome (hg38) on SLURM with custom Shoji paramters
```bash
nextflow -bg run main.nf -profile slurm,soniCLIP,hsa \
    --input /path/to/sample_sheet.csv \
    --shoji.aln_len 30 --shoji.aln_frac 0.85 --shoji.n_aln 5 \
    -output-dir /path/to/output \
    -work-dir /path/to/work \
    -with-timeline -with-report -with-trace
```