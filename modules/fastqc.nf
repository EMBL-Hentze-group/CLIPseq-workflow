process FASTQC {
    tag "$sample"
    
    input:
        tuple val(sample), val(paired), path(fastqs)
        val stage

    output:
        path("${sample}_${stage}/*.zip"), emit: zip // for multiqc
        path("${sample}_${stage}/*.html"), emit: html
    
    container params.singularity.qc

    script:
    """
    mkdir -p ${sample}_${stage} && \
    fastqc $fastqs --outdir ${sample}_${stage}
    """
}