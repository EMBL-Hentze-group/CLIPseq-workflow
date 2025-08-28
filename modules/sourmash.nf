// all sourmash processes
// order of execution: SKETCH -> COMPARE -> PLOT

process SKETCH {
    label "process_low"
    tag "$sample $stage"

    container params.singularity.sourmash

    input:
        tuple val(sample), val(paired), path(fastqs)
        val sketch_params
        val abund
        val stage

    output:
        path("${sample}_${stage}.sig.zip"), emit: sig

    script:
    def out = "${sample}_${stage}.sig.zip"
    sketch_params = abund ? sketch_params + ",abund" : sketch_params
    """
    sourmash sketch dna -f -p ${sketch_params} --name ${sample} -o ${out} ${fastqs}
    """
}

process COMPARE{
    label "process_low"
    tag "$stage"

    input:
    path(sig)
    val K
    val stage
    
    output:
    tuple path("${stage}_${K}compare.npy"), path("${stage}_${K}compare.npy.labels.txt"), emit: npy

    container params.singularity.sourmash

    script:
    def out = "${stage}_${K}compare.npy"
    """
    sourmash compare -f -p ${task.cpus} -k ${K} -o ${out} ${sig}
    """
}

process SOURMASH_PLOT {
    label "process_single"
    tag "$stage"

    input:
    tuple path(npy), path(labels)
    val K
    val stage

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