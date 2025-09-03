process fastqc {
    label "process_low"
    tag "${sample}"

    container params.singularity.qc

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
