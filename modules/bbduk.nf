process bbduk {
    label "process_high"
    tag "${sample}"

    container params.singularity.bbmap

    input:
    tuple val(sample), val(paired), path(fastqs)
    path ref
    val bbduk_params

    output:
    tuple val(sample), val(paired), path("${sample}*_rRNA_free.fq.gz"), emit: free, optional: true
    tuple val(sample), val(paired), path("${sample}*_rRNA_match.fq.gz"), emit: match, optional: true
    path ("${sample}*_rRNA_match.stats.txt"), emit: stats, optional: true

    script:
    def stats = "${sample}_rRNA_match.stats.txt"
    def output_free
    def output_match
    def inputs
    if (paired) {
        output_free = "out=${sample}_R1_rRNA_free.fq.gz out2=${sample}_R2_rRNA_free.fq.gz"
        output_match = "outm=${sample}_R1_rRNA_match.fq.gz outm2=${sample}_R2_rRNA_match.fq.gz"
        inputs = "in=${fastqs[0]} in2=${fastqs[1]}"
    } else {
        output_free = "out=${sample}_rRNA_free.fq.gz"
        output_match = "outm=${sample}_rRNA_match.fq.gz"
        inputs = "in=${fastqs}"
    }
    """
    bbduk.sh threads=${task.cpus} ref=${ref} stats=${stats} ${bbduk_params} ${output_free} ${output_match} ${inputs}
    """
}
