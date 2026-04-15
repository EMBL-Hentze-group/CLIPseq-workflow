process bedGraph{
    label "BIGWIG"
    label "process_low"
    tag "${sample}"

    /*
    see conf/conda/apptainer.config for singularity params and
        conf/conda/conda.config for conda params
    */
    // conda params.conda.genome_ops

    input:
    tuple val(sample), path(sites, arity: 1..2) // expect either the sites file alone or with its index
    path(genome)
    val(bed_params)

    output:
    tuple val(sample), path ("${sample}.bg"), emit: bg

    script:
    """
    bedtools genomecov -i ${sites[0]} -g ${genome} ${bed_params} > ${sample}.bg &&
    bedSort ${sample}.bg ${sample}.bg
    """
}

process bigWig{
    label "BIGWIG"
    label "process_low"
    tag "${sample}"

    /*
    see conf/conda/apptainer.config for singularity params and
        conf/conda/conda.config for conda params
    */
    // conda params.conda.genome_ops

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