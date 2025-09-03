process dedup {
    label "process_low"
    // TODO fix this later
    tag "${sample} ${stage}"

    container params.singularity.umi_tools

    input:
    tuple val(sample), val(paired), path(bam), path(index)
    val dedup_params
    val stage

    output:
    tuple val(sample), val(paired), path("${sample}_${stage}.bam"), emit: bam

    script:
    dedup_params = paired ? dedup_params + " --paired" : dedup_params
    """
    umi_tools dedup ${dedup_params} -I ${bam} -S ${sample}_${stage}.bam
    """
}
