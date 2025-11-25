/*
Contains processes that doesn't really fit anywhere else
*/
process fix_header{
    label "process_single"

    container params.singularity.stats

    input:
    path fastq

    output:
    path "header_fixed_${fastq.getBaseName(fastq.name.endsWith('.gz') ? 2 : 1)}.fastq.gz", emit: fastq

    script:
    """
    fix_header -i ${fastq} -o header_fixed_${fastq.getBaseName(fastq.name.endsWith('.gz') ? 2 : 1)}.fastq.gz
    """
}