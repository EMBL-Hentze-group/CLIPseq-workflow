
process kraken2 {
    label "process_highmem"
    tag "${sample} ${stage}"

    container params.singularity.kraken2

    input:
    tuple val(sample), val(paired), path(fastqs)
    path(db)
    val kraken2_params
    val stage

    output:
    tuple val(sample), val(paired), path("${sample}_${stage}_kraken2_classified*.fq.gz", arity:1..2), emit: classified
    tuple val(sample), val(paired), path("${sample}_${stage}_kraken2_unclassified*.fq.gz", arity:1..2), emit: unclassified
    tuple val(sample), path("${sample}_${stage}_kraken2_report.txt"), emit: report

    script:
    def out_report = "${sample}_${stage}_kraken2_report.txt"
    def class_fq, unclass_fq, inputs
    if (paired) {
        class_fq = "--classified-out ${sample}_${stage}_kraken2_classified#.fq"
        unclass_fq = "--unclassified-out ${sample}_${stage}_kraken2_unclassified#.fq"
        inputs = "--paired ${fastqs[0]} ${fastqs[1]}"
    } else {
        class_fq = "--classified-out ${sample}_${stage}_kraken2_classified.fq"
        unclass_fq = "--unclassified-out ${sample}_${stage}_kraken2_unclassified.fq"
        inputs = " ${fastqs}"
    }
    """
    kraken2 --threads ${task.cpus} --gzip-compressed --db ${db} --report ${out_report} ${kraken2_params} ${class_fq} ${unclass_fq} ${inputs} &&
    gzip *.fq
    """

}

process kraken2Mpa{
    label "process_low"
    tag "${sample} ${stage}"

    container params.singularity.kraken2

    input:
    tuple val(sample), path(report)
    val report2mpa_params
    val stage

    output:
    path("${sample}_${stage}_kraken2_mpa.txt"), emit: mpa

    script:
    """
    kreport2mpa.py ${report2mpa_params} -r ${report} -o ${sample}_${stage}_kraken2_mpa.txt
    """
}

process combineMpa{
    label "process_low"
    tag "${stage}"

    container params.singularity.kraken2

    input:
    path(mpas)
    val stage

    output:
    path("${stage}_combined_kraken2_mpa.txt"), emit: mpa_report

    script:
    def inputs = mpas.join(" ")
    """
    combine_mpa.py -i ${inputs} -o ${stage}_combined_kraken2_mpa.txt
    """
}