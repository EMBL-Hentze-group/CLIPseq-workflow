process STARALIGN{
    label "process_high"
    tag "$sample $stage"

    container params.singularity.star
    
    input:
        tuple val(sample), val(paired), path(reads)
        path(genomeDir)
        val stage
        val star_params
    
    output:
        tuple val(sample), path("${sample}_${stage}.bam"), emit: bam
        path("${sample}_${stage}Log.final.out"), emit: stats
        path("${sample}_${stage}SJ.out.tab"), emit: junctions
    
    script:
        def inputs = paired ? "--readFilesIn ${reads[0]} ${reads[1]}" : "--readFilesIn ${reads}"
        """
        STAR --runMode alignReads --runThreadN ${task.cpus} --genomeDir ${genomeDir} ${star_params} ${inputs} \\
         --outFileNamePrefix ${sample}_${stage} > ${sample}_${stage}.bam
        """
}

process STARALIGN_2PASS{
    label "process_high"
    tag "$sample $stage"

    container params.singularity.star
    
    input:
        tuple val(sample), val(paired), path(reads)
        path(genomeDir)
        path(sjFiles)
        val stage
        val star_params
    
    output:
        tuple val(sample), path("${sample}_${stage}.bam"), emit: bam
        path("${sample}_${stage}Log.final.out"), emit: stats
        path("${sample}_${stage}SJ.out.tab"), emit: junctions
    
    script:
        def inputs = paired ? "--readFilesIn ${reads[0]} ${reads[1]}" : "--readFilesIn ${reads}"
        def sjInput = "--sjdbFileChrStartEnd ${sjFiles.join(' ')} --sjdbOverhang 100"
        """
        STAR --runMode alignReads --runThreadN ${task.cpus} --genomeDir ${genomeDir} ${star_params} ${inputs} \\
         ${sjInput} --outFileNamePrefix ${sample}_${stage} > ${sample}_${stage}.bam
        """
}