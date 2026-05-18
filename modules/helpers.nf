/*
Contains processes that doesn't really fit anywhere else
*/
process fix_header{
    label "STATTER"
    label "process_single"

    /*
    see conf/conda/apptainer.config for singularity params and
        conf/conda/conda.config for conda params
    */
    
    input:
    path fastq

    output:
    path "header_fixed_${fastq.getBaseName(fastq.name.endsWith('.gz') ? 2 : 1)}.fastq.gz", emit: fastq

    script:
    """
    statter fix-header -i ${fastq} -o header_fixed_${fastq.getBaseName(fastq.name.endsWith('.gz') ? 2 : 1)}.fastq.gz
    """
}