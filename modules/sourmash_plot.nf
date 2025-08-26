process SOURMASH_PLOT {
    label "process_single"
    tag "$stage"

    input:
    tuple path(npy), path(labels)
    val stage
    val K

    output:
    path("${npy}.matrix.pdf"), emit: pdf

    container params.singularity.sourmash

    script:
    def outdir = "${stage}_${K}"
    """
    mkdir -p ${outdir} &&
    sourmash plot -f --pdf --output-dir ${outdir} --labeltext ${labels} ${npy} &&
    mv ${outdir}/*.matrix.pdf ${npy}.matrix.pdf
    """
}