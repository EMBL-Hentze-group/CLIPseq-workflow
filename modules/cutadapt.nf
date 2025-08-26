
process CUTADAPT {
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
        // run_cutadapt_paired(fastqs, sample)
        def mate1 = fastqs[0]
        def mate2 = fastqs[1]
        def R1 ="${sample}_${stage}_R1.fq.gz"
        def R2 ="${sample}_${stage}_R2.fq.gz"
        """
        echo "Paired-end reads detected. ${mate1}, ${mate2}, ${R1}, ${R2}"
        cutadapt  ${cut_params} -o ${R1} -p ${R2} --report full --json ${json} ${mate1} ${mate2}
        """
    } else {
        def out ="${sample}_${stage}_fq.gz"
        """
        echo "single reads detected. ${fastqs}, ${out}"
        cutadapt  ${cut_params} -o ${out} --report full --json ${json} ${fastqs}
        """
    }
}