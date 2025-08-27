process SORT{
    label "process_low"
    tag "$sample $stage"

    container params.singularity.samtools

    input:
        tuple val(sample), path(bam)
        val stage

    output:
        tuple val(sample), path("${sample}_${stage}.bam"), emit: bam

    script:
        """
        samtools sort -@ ${task.cpus} -O BAM -o ${sample}_${stage}.bam ${bam} 
        """
}

process INDEX{
    label "process_low"
    tag "$sample $stage"

    container params.singularity.samtools

    input:
        tuple val(sample), path(bam)
        val stage

    output:
        tuple val(sample), path("${sample}_${stage}.bam.bai"), emit: index

    script:
        """
        samtools index -b -@ ${task.cpus} -o ${sample}_${stage}.bam.bai ${bam} 
        """
}

