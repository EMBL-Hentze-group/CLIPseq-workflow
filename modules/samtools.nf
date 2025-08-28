process SORT{
    label "process_low"
    tag "$sample $stage"

    container params.singularity.samtools

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

process INDEX{
    label "process_low"
    tag "$sample"

    container params.singularity.samtools

    input:
        tuple val(sample),val(paired), path(bam)

    output:
        tuple val(sample), path("${bam}.bai"), emit: index

    script:
        """
        samtools index -b -@ ${task.cpus} -o ${bam}.bai ${bam} 
        """
}

