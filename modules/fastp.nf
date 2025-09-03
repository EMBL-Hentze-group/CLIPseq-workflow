process fastp {
    label "process_low"
    tag "${sample} ${stage}"

    container params.singularity.trim

    input:
    tuple val(sample), val(paired), path(fastqs)
    val cut_params
    val stage

    output:
    tuple val(sample), val(paired), path("${sample}_${stage}*fq.gz"), emit: trimmed
    tuple val(sample), val(paired), path("${sample}_${stage}_report.json"), emit: report

    script:
    def json = "${sample}_${stage}_report.json"
    def outputs = paired ? " -o ${sample}_${stage}_R1.fq.gz -O ${sample}_${stage}_R2.fq.gz" : " -o ${sample}_${stage}_fq.gz"
    def inputs = paired ? " -i ${fastqs[0]}  -I ${fastqs[1]}" : " -i ${fastqs}"
    """
    fastp --thread ${task.cpus} ${cut_params} -j ${json} ${outputs} ${inputs}
    """
}
