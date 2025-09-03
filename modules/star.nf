process starAlign {
    label "process_high"
    tag "${sample} ${stage}"

    container params.singularity.star

    input:
    tuple val(sample), val(paired), path(reads)
    path genomeDir
    val star_params
    val stage

    output:
    tuple val(sample), val(paired), path("${sample}_${stage}.bam"), path("${sample}_${stage}.bam.bai"), emit: bam
    path ("${sample}_${stage}Log.final.out"), emit: stats
    path ("${sample}_${stage}SJ.out.tab"), emit: junctions

    script:
    def inputs = paired ? "--readFilesIn ${reads[0]} ${reads[1]}" : "--readFilesIn ${reads}"
    """
    STAR --runMode alignReads --runThreadN ${task.cpus} --genomeDir ${genomeDir} ${star_params} ${inputs} \\
        --outFileNamePrefix ${sample}_${stage} > ${sample}_${stage}.bam &&
    samtools sort -@ ${task.cpus} -O BAM -o ${sample}_${stage}_sorted.bam ${sample}_${stage}.bam &&
    mv ${sample}_${stage}_sorted.bam ${sample}_${stage}.bam &&
    samtools index -b -@ ${task.cpus} -o ${sample}_${stage}.bam.bai ${sample}_${stage}.bam
    """
}

process starAlign2Pass {
    label "process_high"
    tag "${sample} ${stage}"

    container params.singularity.star

    input:
    tuple val(sample), val(paired), path(reads)
    path genomeDir
    val star_params
    path sjFiles
    val stage

    output:
    tuple val(sample), val(paired), path("${sample}_${stage}.bam"), path("${sample}_${stage}.bam.bai"), emit: bam
    path ("${sample}_${stage}Log.final.out"), emit: stats
    path ("${sample}_${stage}SJ.out.tab"), emit: junctions

    script:
    def inputs = paired ? "--readFilesIn ${reads[0]} ${reads[1]}" : "--readFilesIn ${reads}"
    def sjInput = "--sjdbFileChrStartEnd ${sjFiles.join(' ')} --sjdbOverhang 100"
    """
    STAR --runMode alignReads --runThreadN ${task.cpus} --genomeDir ${genomeDir} ${star_params} ${inputs} \\
        ${sjInput} --outFileNamePrefix ${sample}_${stage} > ${sample}_${stage}.bam &&
    samtools sort -@ ${task.cpus} -O BAM -o ${sample}_${stage}_sorted.bam ${sample}_${stage}.bam &&
    mv ${sample}_${stage}_sorted.bam ${sample}_${stage}.bam &&
    samtools index -b -@ ${task.cpus} -o ${sample}_${stage}.bam.bai ${sample}_${stage}.bam
    """
}
