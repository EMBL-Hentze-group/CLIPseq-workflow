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


PROFILE=slurm,apptainer,iCLIP,hsa 
# profiles to use in this run, as comma separated list. Run using SLURM scheduler, with Apptainer for software management, and the iCLIP profile which includes protocol specific parameters and resource configurations and using hsa (hg38) genome assembly.

SAMPLE_SHEET="/path/to/sample_sheet.csv" # path to the sample sheet csv file

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
    --kraken2.db $KRAKEN2_DB \
    --kraken2.nodes $NCBI_NODES \
    --kraken2.names $NCBI_NAMES \
    -with-timeline \
    -with-report \
    -with-trace \
    -resume &> nextflow_run_$(date +'%H-%M-%S').log &