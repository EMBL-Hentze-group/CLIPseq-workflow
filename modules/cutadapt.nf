
process CUTADAPT {
    label "process_low"
    tag "$sample $stage"

    container params.singularity.trim

    input:
        tuple val(sample), val(paired), path(fastqs)
        val stage
        val cut_params

    output:
        tuple val(sample), val(paired), path("${sample}_${stage}*fq.gz"), emit: trimmed
        tuple val(sample), val(paired), path("${sample}_${stage}_report.json"), emit: report

    script:
    def json = "${sample}_${stage}_report.json"
    def outputs = paired ? " -o ${sample}_${stage}_R1.fq.gz -p ${sample}_${stage}_R2.fq.gz" : " -o ${sample}_${stage}_fq.gz"
    def inputs = paired ? "${fastqs[0]} ${fastqs[1]}" : "${fastqs}"
    """
    cutadapt -j ${task.cpus} ${cut_params} --report full --json ${json} ${outputs} ${inputs}
    """
}