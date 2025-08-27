process BBDUK{
    label "process_medium"
    tag "$sample"

    container params.singularity.bbmap

    input:
        tuple val(sample), val(paired), path(fastqs)
        path(ref)
        val bbduk_params

    output:
        tuple val(sample), val(paired), path("${sample}*_rRNA_free.fq.gz"), emit: free
        tuple val(sample), val(paired), path("${sample}*_rRNA_match.fq.gz"), emit: match
        path("${sample}*_rRNA_match.stats.txt"), emit: stats
    
    script:
        def stats = "${sample}_rRNA_match.stats.txt"
        def output_free = paired ? "out=${sample}_R1_rRNA_free.fq.gz out2=${sample}_R2_rRNA_free.fq.gz" : "out=${sample}_rRNA_free.fq.gz"
        def output_match = paired ? "outm=${sample}_R1_rRNA_match.fq.gz outm2=${sample}_R2_rRNA_match.fq.gz" : "outm=${sample}_rRNA_match.fq.gz"
        def inputs = paired ? "in=${fastqs[0]} in2=${fastqs[1]}" : "in=${fastqs}"
        """
        bbduk.sh threads=${task.cpus} ref=${ref} stats=${stats} ${bbduk_params} ${output_free} ${output_match} ${inputs}
        """
}