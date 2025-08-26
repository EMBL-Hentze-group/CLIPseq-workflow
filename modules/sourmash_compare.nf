process COMPARE{
    tag "$stage"

    input:
    path(sig)
    val stage
    val K
    
    output:
    tuple path("${stage}_${K}compare.npy"), path("${stage}_${K}compare.npy.labels.txt"), emit: npy

    container params.singularity.sourmash

    script:
    def out = "${stage}_${K}compare.npy"
    """
    sourmash compare -k ${K} -o ${out} ${sig}
    """
}