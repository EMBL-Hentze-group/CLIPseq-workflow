process faidx {
    label "SAMTOOLS"
    label "process_low"
    tag "genome indexing"

    input:
    path genome

    output:
    tuple path(genome), path("${genome}.*", arity: '1..2'), emit: indx

    script:
    """
    samtools faidx ${genome}
    """
}

process sort {
    label "SAMTOOLS"
    label "process_low"
    tag "${sample} ${stage}"

    input:
    tuple val(sample), val(paired), path(bam)
    val stage

    output:
    tuple val(sample), val(paired), path(bam), emit: bam

    script:
    """
    samtools sort -@ ${task.cpus} -O BAM -o ${bam} ${bam} 
    """
}

process index {
    label "SAMTOOLS"
    label "process_low"
    tag "${sample}"

    input:
    tuple val(sample), val(paired), path(bam)

    output:
    tuple val(sample), path("${bam}.bai"), emit: index

    script:
    """
    samtools index -b -@ ${task.cpus} -o ${bam}.bai ${bam} 
    """
}

process fastq {
    label "SAMTOOLS"
    label "process_low"
    tag "${sample} ${stage}"

    input:
    tuple val(sample), val(paired), path(bam), path(bai)
    val stage

    output:
    tuple val(sample), val(paired), path("${sample}_${stage}*fq.gz"), emit: fastq

    script:
    def outputs = paired ? " -1 ${sample}_${stage}_R1.fq.gz -2 ${sample}_${stage}_R2.fq.gz" : " -0 ${sample}_${stage}.fq.gz"
    def params = " "
    if (stage == "mapped" || stage == "dedup") {
        params = paired ? "-F 12" : "-F 4"
    }
    else if (stage == "unmapped") {
        params = "-d uT:0 -d uT:1 -d uT:2 -d uT:4"
    }
    else if (stage == "multimapped") {
        params = "-d uT:3"
    }
    else {
        error("Error: stage must be one of mapped, unmapped or multimapped, got ${stage}!")
    }
    """
    samtools fastq -@ ${task.cpus} ${params} ${bam} ${outputs}
    """
}
