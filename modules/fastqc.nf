process fastqc {
    label "FASTQC"
    label "process_low"
    tag "${sample}"

    /*
    see conf/conda/apptainer.config for singularity params and
        conf/conda/conda.config for conda params
    */
    // conda params.conda.qc

    input:
    tuple val(sample), val(paired), path(fastqs)
    val stage

    output:
    path ("${sample}_${stage}/*.zip"), emit: zip
    // for multiqc
    path ("${sample}_${stage}/*.html"), emit: html

    script:
    """
    mkdir -p ${sample}_${stage} && \
    fastqc -t ${task.cpus} ${fastqs} --outdir ${sample}_${stage}
    """
}


process fastqc_demux{
    label "FASTQC"
    label "process_high"

    /*
    run fastqc before demultiplexing, files can be large

    see conf/conda/apptainer.config for singularity params and
        conf/conda/conda.config for conda params
    */
    // conda params.conda.qc
    
    input:
    tuple path(fastq), path(barcode)

    output:
    path("${fastq.getBaseName(fastq.name.endsWith('.gz') ? 2 : 1)}/*.zip"), emit: zip
    path("${fastq.getBaseName(fastq.name.endsWith('.gz') ? 2 : 1)}/*.html"), emit: html

    script:
    def base = fastq.getBaseName(fastq.name.endsWith('.gz') ? 2 : 1)
    """
    mkdir -p ${base} && \
    fastqc -t ${task.cpus} ${fastq} --outdir ${base}
    """
}