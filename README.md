# CLIP-seq Workflow

A [Nextflow](https://nextflow.io) workflow for end-to-end processing of CLIP-seq data, supporting multiple CLIP protocols.

## Overview

Starting from raw FASTQ files (or un-demultiplexed iCLIP data), the workflow processes reads through quality control, adapter trimming, rRNA removal, genome alignment, and UMI deduplication, then runs shoji to extract crosslink sites and produce per-sample and combined count matrices ready for differential binding analysis (see [DEWSeq](https://bioconductor.org/packages/release/bioc/html/DEWSeq.html)).

## Workflow steps

- **Demultiplexing** *(optional, iCLIP only)*
    - [x] [flexbar](https://github.com/seqan/flexbar) (barcode-based demultiplexing) + umi_tools (UMI extraction)
- **Quality Control**
    - [x] [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
    - [x] [MultiQC](https://seqera.io/multiqc/)
- **UMI pre-processing** *(optional, R2-CLIP only)*
    - [x] [umi_tools](https://umi-tools.readthedocs.io/en/latest/QUICK_START.html)
- **Adapter and Quality Trimming**
    - [x] [fastp](https://github.com/opengene/fastp) (default; single-step or two-step depending on protocol)
    - [ ] [cutadapt](https://cutadapt.readthedocs.io/en/stable/) *(partial implementation - used in eCLIP two-step trim)*
- **Fastq data sketching and similarity comparison**
    - [x] [sourmash](https://github.com/sourmash-bio/sourmash) - plots to check sample group similarity
- **rRNA filtering** *(optional)*
    - [x] [bbduk](https://github.com/BioInfoTools/BBMap) - to remove rRNA reads using a reference Fasta
- **Alignment**
    - [x] [STAR](https://github.com/alexdobin/STAR) (single-pass or two-pass)
- **Contamination estimation**
    - [x] [Kraken2](https://github.com/DerrickWood/kraken2) - run on unmapped reads to detect unexpected organisms
- **UMI deduplication** *(optional)*
    - [x] [umi_tools](https://umi-tools.readthedocs.io/en/latest/QUICK_START.html) `dedup`
- **Downstream processing**
    - [x] [shoji](https://github.com/EMBL-Hentze-group/Shoji)
- **Final statistics report**
    - [x] Per-sample read counts at each processing stage (raw → trimmed → rRNA-filtered → aligned → deduplicated), plus Kraken2 classification summary

## Prerequisites

- **Java 11+** (required by Nextflow)
- **[Nextflow](https://www.nextflow.io/docs/latest/install.html)** - tested versions:
  - [`25.04.6`](https://github.com/nextflow-io/nextflow/releases/tag/v25.04.6)
  - [`25.10.1`](https://github.com/nextflow-io/nextflow/releases/tag/v25.10.1)
- One of the following for software environments:
  - **[Apptainer](https://apptainer.org/)** (formerly Singularity) - recommended for HPC, see [apptainer configs](conf/containers/apptainer.config)
  - **[Conda](https://conda.io)** / **[Mamba](https://mamba.readthedocs.io)** - see [conda configs](conf/conda/)

> :warning: If using conda/mamba, ensure no active conda environment is loaded before launching Nextflow, as it can interfere with the JRE.


## Reference files

The genome profiles ([conf/genome/](conf/genome/)) contain organism specific reference configs. 

> :information_source: See [this note](#genomeinfo) about creating genome specific configs

Before running, you will need to prepare and configure paths to:

| File | Used by | Description |
|------|---------|-------------|
| STAR genome index | STAR | Build using [`STAR --runMode genomeGenerate`](https://github.com/alexdobin/STAR/blob/master/doc/STARmanual.pdf) against your genome FASTA or FASTA + GTF |
| GFF3 annotation | shoji | Gene annotation file ([GENCODE](https://www.gencodegenes.org/)). See [this section](#gff3warn) about using annotation files from non GENCODE sources.|
| Genome FAI | tracks | FASTA index (`.fa.fai`) for the genome, used to set chromosome sizes for track generation (see [`samtools faidx`](https://www.htslib.org/doc/samtools-faidx.html)) |
| rRNA FASTA | bbduk | Reference sequences for rRNA filtering |
| Kraken2 database | Kraken2 | Pre-built Kraken2 database (e.g. from [https://benlangmead.github.io/aws-indexes/k2](https://benlangmead.github.io/aws-indexes/k2)). See **[kraken2](#kraken2) section**  |

> :warning: Edit the relevant genome config (e.g. [conf/genome/hsa.config](conf/genome/hsa.config) or [conf/genome/rDNA.config](conf/genome/rDNA.config)) to point to your local copies.

### GFF3

<a id="gff3warn"></a>
> :warning: When using GFF3 files from sources other than GENCODE, shoji paramaters corresponding to gene id, name, type and optionally feature needs to supplied. See [shoji annotation documentation](https://shoji.readthedocs.io/en/latest/documentation.html#id1) for a description of these parameters. In [hsa](conf/genome/hsa.config) and [rDNA](conf/genome/hsa.config) configs, edit the variable `annotation_params` to fit the attribute names in the GFF3 file being used.

<a id="kraken2"></a>
### Kraken2
> :warning: [Kraken2 config](conf/tools/kraken2.config) parameters `db`, `nodes` and `names` are placeholder pathes. Edit these to point to actual files before running the workflow

| Parameter | Required file | Description |
|------|---------|-------------|
|`db`|Kraken2 index file| See [Kraken 2 index](https://benlangmead.github.io/aws-indexes/k2) for a list of downloadable index files|
|`nodes`|NCBI taxonomy db `nodes.dmp` file| See [this readme](https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump_readme.txt)|
|`names`|NCBI taxonomy db `names.dmp` file| See [this readme](https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump_readme.txt)|

> :information_source: See this [shell script](./scripts/soniCLIP_hsa_apptainer_shoji.sh) for an example supplying these files using command line parameters

## Built-in profiles

### Supported protocols

| Profile |Sequencing type| Description |
|---------|:---------:|-------------|
| [`eCLIP`](conf/protocol/eCLIP.config) | paired-end | :warning:  two-step adapter trimming (cutadapt) and UMI deduplication |
| [`iCLIP`](conf/protocol/iCLIP.config) | single-end | barcode demultiplexing + UMI extraction via flexbar |
| [`R2CLIP`](conf/protocol/R2CLIP.config) | paired-end | Read 2 is expected to contain only UMIs,and after UMI extraction Read 1 is processed as single-end |
| [`soniCLIP`](conf/protocol/soniCLIP.config) | single-end | no demultiplexing or deduplication |

> :warning: The current version of [eCLIP](./conf/protocol/eCLIP.config) profile is designed to handle UMI-extracted reads available from [the ENCODE portal](https://www.encodeproject.org/search/?type=Experiment&searchTerm=eCLIP)

### Genomes

| Profile | Description |
|---------|-------------|
| `hsa` | Human GRCh38 / GENCODE v42 primary assembly |
| `rDNA` | Human hg38 with rDNA-masked genome (for rRNA binding RBPs); rRNA trimming disabled by default. rDNA genomes for human and mouse are available from [this reference](https://doi.org/10.1016/j.jbc.2023.104766) |

<a id="genomeinfo"></a>
> :information_source: it is also possible to skip creating/using genome configs altogether and supply these reference files using parameters. See [this soniCLIP shell script template](./scripts/soniCLIP_run.sh) for an example

### Run environments

| Profile | Description |
|---------|-------------|
| `apptainer` | Runs processes inside Apptainer containers (paths should be configured separately - see [conf/containers/README.md](conf/containers/README.md)) |
| `conda` | Creates and caches conda environments per process (see [conf/conda/](conf/conda/) and [conda config](conf/conda/conda.config)) |
| `slurm` | SLURM executor settings (see [conf/run/embl_hd.config](conf/run/embl_hd.config)); adapt queue names and resource limits for your cluster |

### Using profiles

Profiles are combined with commas. See [nextflow.config](./nextflow.config) for the full list.

```
nextflow run ... -profile slurm,apptainer,eCLIP,hsa
```

This runs the workflow on a SLURM cluster using Apptainer containers, the eCLIP protocol, and hg38 genome alignment.

> :information_source: The `slurm` profile is pre-configured for the EMBL Heidelberg HPC. For other SLURM clusters, copy [conf/run/embl_hd.config](conf/run/embl_hd.config), adjust queue names and resource parameters, and reference your copy in [nextflow.config](./nextflow.config).

## Workflow


### Sample sheet format

This workflow uses [nf-schema](https://nextflow-io.github.io/nf-schema/latest/) plugin and the supported sample sheet format.

For `eCLIP`, `R2-CLIP` and `soniCLIP` protocols, the following columns (in csv) is expected:

<a id="default"></a>
#### eCLIP

`eCLIP`: `fastq_2` column **MUST be** provided.

|sample|fastq_1|fastq_2|
|------|-------|-------|
|sample1|/path/to/sample1_R1.fastq.gz| /path/to/sample1_R2.fastq.gz|

#### R2-CLIP

`R2-CLIP`: `fastq_1` for acutal reads, and `fastq_2` is expected to contain only UMIs. 

[umi_tools `extract`](https://umi-tools.readthedocs.io/en/latest/reference/extract.html) is used to extract UMIs from `fastq_2` (based on parameter `bc_pattern` in [config file](conf/protocol/R2CLIP.config)) and add them to `fastq_1` headers and are then processed as regular single-end reads.

|sample|fastq_1|fastq_2|
|------|-------|-------|
|sample1|/path/to/sample1_R1.fastq.gz| /path/to/sample1_R2.fastq.gz|

#### soniCLIP
`soniCLIP`:  only uses `fastq_1`

|sample|fastq_1|
|------|-------|
|sample1|/path/to/sample1.fastq.gz|


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
:information_source: [flexbar](https://github.com/seqan/flexbar) is  used for demultiplexing iCLIP data based on the provided barcodes with corresponding header as sample name. UMIs (`N`s in the sequences) are extracted from the reads during demultiplexing and added to fastq header.

:information_source: iCLIP fastq files that are already processed (demultiplexed and UMI extracted) can also be provided, using the same sample sheet format as for eCLIP/R2-CLIP/soniCLIP (with `sample`, `fastq_1` columns) ([see section eCLIP, R2-CLIP and soniCLIP](#default)).

### Running the workflow

> :warning: most of the example workflows below assumes that there is a genome assembly config with appropriate paths and parameters in the [genome](./conf/genome/) folder and that this assembly is included in the [nextflow config](./nextflow.config) file

> ℹ️ see [this shell script](#cmdparam) for supplying these files as command-line arguments

#### eCLIP with human genome (hg38) on SLURM using conda

See [this shell script](./scripts/eCLIP_hsa_conda.sh)

#### iCLIP with human genome (hg38) on SLURM using apptainer

See [this shell script](./scripts/iCLIP_hsa_apptainer.sh)

#### soniCLIP with human genome (hg38) on SLURM using apptainer with custom shoji parameters

See [this shell script](./scripts/soniCLIP_hsa_apptainer_shoji.sh)

<a id="cmdparam"></a>
#### soniCLIP without using a genome config  on SLURM and conda

See [this shell script](./scripts/soniCLIP_custom_conda.sh)

> :information_source: The shell script above shows how to use custom genome files without adding a genome config.

## Output
Given below is an example output directory structure from this pipeline.

> :information_source: the output directory is defined by nextflow `-output-dir` parameter, and the files in this directory will be symbolic links to the files in the work directory, defined by nextflow parameter `-work-dir`

|Directory|Sub-directory|File|Description
|------|-------|------|-------|
|Annotation| | |Shoji annotation files|
|Fastq| | |Fastq files after trimming|
| | rRNA_trim| |after rRNA read removal|
| | trim| |after rRNA read removal|
|Genome_align| | |Genome alignments|
| | alignment| |bam files, alignment statistics,...|
| | mapped_fq| |mapped reads in fq format|
| | multimapped_fq| |multimapped reads in fq format|
| | unmapped_fq| |un-mapped reads in fq format|
|Kraken2| | |Kraken 2 output directory|
| | contamination_check| |Kraken2 classification files and contamination reports|
|QC| | |QC files: fastqc and multiqc files|
| | raw| |raw data QC|
| | rRNA_trim| |QC after rRNA read removal|
| | trim| |QC after adapter trimming|
|Shoji| | |Shoji and related outputs|
| | counts| |count files from `shoji count`|
| | matrix| |Final output matrices for DEWSeq analysis|
| | sites| |bed formatted output files from `shoji extract`|
| | tracks| |`.bw` files for visualization|
|Sourmash| | |Sourmash files and plots|
| | align| |for aligned reads|
| | kraken2| |after Kraken2 contamination estimation|
| | raw| |for raw reads|
| | rRNA_trim| |after rRNA read trimming|
| | trim| |after adapter trimming|
|Stats| | |Read count statistics|
| | | all_samples_combined_stats.csv|read count statistics for all samples from raw reads to alignment, deduplication (optional) and contamination estimation|
| | |`<sample>`_all_stats.json|per sample read count statistics in json format|


Developed at: [Hentze Group](https://www.embl.org/groups/hentze/), EMBL Heidelberg
