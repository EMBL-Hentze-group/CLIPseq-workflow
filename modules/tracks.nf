process bedGraph{
    label "process_low"
    tag "${sample}"

    container params.singularity.genome_ops

    input:
    tuple val(sample), path(sites)
    path(genome)
    val(bed_params)

    output:
    tuple val(sample), path ("${sample}.bg"), emit: bg

    script:
    """
    bedtools genomecov -i ${sites} -g ${genome} ${bed_params} > ${sample}.bg &&
    bedSort ${sample}.bg ${sample}.bg
    """
}

process bigWig{
    label "process_low"
    tag "${sample}"

    container params.singularity.genome_ops

    input:
    tuple val(sample), path(bedGraph)
    path(genome)

    output:
    path ("${sample}.bw"), emit: bw

    script:
    """
    bedGraphToBigWig ${bedGraph} ${genome} ${sample}.bw
    """
}