
process FASTP {
    label "process_low"
    tag "$sample $stage"

    input:
    tuple val(sample), val(paired), path(fastqs)
    val stage
    val cut_params

    output:
    tuple val(sample), val(paired), path("${sample}_${stage}*fq.gz"), emit: trimmed
    tuple val(sample), val(paired), path("${sample}_${stage}_report.json"), emit: report

    container params.singularity.trim

    script:
    def json = "${sample}_${stage}_report.json"
    if (paired) {
        def mate1 = fastqs[0]
        def mate2 = fastqs[1]
        def R1 ="${sample}_${stage}_R1.fq.gz"
        def R2 ="${sample}_${stage}_R2.fq.gz"
        """
        fastp --thread ${task.cpus} ${cut_params} -i ${mate1} -o ${R1} -I ${mate2} -O ${R2} --j ${json}  
        """
    } else {
        def out ="${sample}_${stage}_fq.gz"
        """
        fastp --thread ${task.cpus}  ${cut_params} -i ${fastqs} -o ${out} --j ${json} 
        """
    }
}