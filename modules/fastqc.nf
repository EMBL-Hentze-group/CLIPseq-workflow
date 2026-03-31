process fastqc {
    label "process_low"
    tag "${sample}"

    container params.singularity.qc
    conda params.conda.qc

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
    label "process_high"

    container params.singularity.qc
    conda params.conda.qc
    // run fastqc before demultiplexing, files can be large

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