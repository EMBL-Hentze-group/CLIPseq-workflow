#!/bin/sh

############################################
# 
# Before running this script, make sure to edit all the paths  starting with /path/to/ to the appropriate locations on your system.
#
############################################

REPO=/path/to/clip-seq-nf # path to the workflow repository

# run the workflow with config profile for slurm, using conda for software management, explicity specifying the indices and annotation resources
BASE=/path/to/base/dir
OUT=$BASE/analysis_$(date +'%d-%m-%Y') # output directory
RUN=$BASE/run/run_$(date +'%d-%m-%Y') # logs and reports
WORK=$BASE/work # nextflow work directory

PROFILE=slurm,conda,soniCLIP # profiles to use in this run, as comma separated list. Run using SLURM scheduler, with conda for software management, and the soniCLIP profile which includes protocol specific parameters and resource configurations

SAMPLE_SHEET="/path/to/sample_sheet.csv" # path to the sample sheet csv file

# Below are the paths to the indices and annotation resources that need to be specified in the config file for the workflow run. These can also be specified as environment variables or command line parameters, or can be configured using a separate config file, which is then later included in the main config.

GFF3="/path/to/annotation.gff3" # for Shoji
rRNA_FA="/path/to/rRNA.fa" # for rRNA trimming step
STAR_INDEX="/path/to/star/index" # STAR index for the genome
GENOME_FAI="/path/to/genome.fa.fai" # for generating bw file tracks
# KRAKEN2 files
KRAKEN2_DB="/path/to/kraken2_db" # kraken2 database 
NCBI_NODES="/path/to/nodes.dmp" # NCBI taxonomy nodes.dmp file
NCBI_NAMES="/path/to/names.dmp" # NCBI taxonomy names.dmp file

mkdir -p $OUT $RUN $WORK

nextflow config $REPO -profile $PROFILE > $OUT/run_$(date +'%d-%m-%Y').config # save the config used for the run in the output directory for record keeping

cp "$(readlink -f "$0")" $OUT # copy this script to the output directory for record keeping

cd $RUN

nextflow -bg run $REPO -profile $PROFILE \
    -output-dir $OUT \
    -work-dir $WORK \
    --input $SAMPLE_SHEET \
    --shoji.gff3 $GFF3 \
    --bbduk.ref $rRNA_FA \
    --STAR.genomeDir $STAR_INDEX \
    --tracks.genome $GENOME_FAI \
    --kraken2.db $KRAKEN2_DB \
    --kraken2.nodes $NCBI_NODES \
    --kraken2.names $NCBI_NAMES \
    -with-timeline \
    -with-report \
    -with-trace \
    -resume &> nextflow_run_$(date +'%H-%M-%S').log &