process cutadapt {
    label "process_low"
    tag "${sample} ${stage}"

    container params.singularity.trim

    input:
    tuple val(sample), val(paired), path(fastqs)
    val cut_params
    val stage

    output:
    tuple val(sample), val(paired), path("${sample}_${stage}*fq.gz"), emit: trimmed
    path("${sample}_${stage}_report.json"), emit: report

    script:
    def json = "${sample}_${stage}_report.json"
    def outputs, inputs
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
