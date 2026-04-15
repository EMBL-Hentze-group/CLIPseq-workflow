process stats {
    label "SEQKIT"
    label "process_low"
    tag "${sample} ${stage}"

    /*
    see conf/conda/apptainer.config for singularity params and
        conf/conda/conda.config for conda params
    */
    // conda params.conda.seqkit

    input:
    tuple val(sample), val(paired), path(fastqs)
    val stage

    output:
    tuple val(sample), val(stage), path("${sample}_${stage}_fq_stats.txt"), emit: stats

    script:
    def stats = "${sample}_${stage}_fq_stats.txt"
    def inputs
    if (paired) {
        inputs = "${fastqs[0]} ${fastqs[1]}"
    } else {
        inputs = "${fastqs}"
    }
    """
    seqkit stats -j ${task.cpus} -aT ${inputs} > ${stats}
    """
}