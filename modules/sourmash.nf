// all sourmash processes
// order of execution: SKETCH -> COMPARE -> PLOT

process sketch {
    label "SOURMASH"
    label "process_low"
    tag "${sample} ${stage}"

    /*
    see conf/conda/apptainer.config for singularity params and
        conf/conda/conda.config for conda params
    */
    // container params.singularity.sourmash
    // conda params.conda.sourmash

    input:
    tuple val(sample), val(paired), path(fastqs)
    val sketch_params
    val abund
    val stage

    output:
    path ("${sample}_${stage}.sig.zip"), emit: sig

    script:
    def out = "${sample}_${stage}.sig.zip"
    sketch_params = abund ? sketch_params + ",abund" : sketch_params
    """
    sourmash sketch dna -f -p ${sketch_params} --name '${sample} ${stage}' -o ${out} ${fastqs}
    """
}

process compare {
    label "SOURMASH"
    label "process_medium"
    tag "${stage}"

    /*
    see conf/conda/apptainer.config for singularity params and
        conf/conda/conda.config for conda params
    */
    // container params.singularity.sourmash
    // conda params.conda.sourmash

    input:
    path sig
    val K
    val stage

    output:
    tuple path("${stage}_k${K}_compare.npy"), path("${stage}_k${K}_compare.npy.labels.txt"), emit: npy

    script:
    def out = "${stage}_k${K}_compare.npy"
    """
    sourmash compare -f -p ${task.cpus} -k ${K} -o ${out} ${sig}
    """
}

process sourmashPlot {
    label "SOURMASH"
    label "process_single"
    tag "${stage}"

    /*
    see conf/conda/apptainer.config for singularity params and
        conf/conda/conda.config for conda params
    */
    // container params.singularity.sourmash
    // conda params.conda.sourmash

    input:
    tuple path(npy), path(labels)
    val K
    val stage

    output:
    path ("${npy}.matrix.pdf"), emit: pdf

    script:
    def outdir = "${stage}_k${K}"
    """
    mkdir -p ${outdir} &&
    sourmash plot -f --pdf --output-dir ${outdir} --labeltext ${labels} ${npy} &&
    mv ${outdir}/*.matrix.pdf ${npy}.matrix.pdf
    """
}
