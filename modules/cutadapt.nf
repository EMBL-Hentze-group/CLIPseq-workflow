process cutadapt {
    label "CUTADAPT"
    label "process_low"
    tag "${sample} ${stage}"

    /*
    see conf/conda/apptainer.config for singularity params and
        conf/conda/conda.config for conda params
    */
    // conda params.conda.trim
    
    input:
    tuple val(sample), val(paired), path(fastqs)
    val cut_params
    val stage

    output:
    tuple val(sample), val(paired), path("${sample}_${stage}*fq.gz"), emit: trimmed
    path("${sample}_${stage}_report.json"), emit: report
    tuple val(sample), val(stage), path("${sample}_${stage}_report.json"), emit: stats

    script:
    def json = "${sample}_${stage}_report.json"
    def outputs
    def inputs
    if (paired) {
        outputs = " -o ${sample}_${stage}_R1.fq.gz -p ${sample}_${stage}_R2.fq.gz"
        inputs = "${fastqs[0]} ${fastqs[1]}"
    } else {
        outputs = " -o ${sample}_${stage}_fq.gz"
        inputs = "${fastqs}"
    }
    """
    cutadapt -j ${task.cpus} ${cut_params} --report full --json ${json} ${outputs} ${inputs}
    """
}
