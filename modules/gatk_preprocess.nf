/*
    GATK Preprocessing processes
*/
process dictFa {

    label "GATK"
    label "process_low"
    tag "Creating genome dictionary"

    input:
    tuple path(fa), path(indx, arity: '1..2')

    output:
    tuple path(fa), path(indx, arity: '1..2'), path("${fa.baseName}.dict"), emit: genome

    script:

    def mem = task.memory ? "${task.memory.toGiga() - 1}g" : "4g"
    """
    gatk --java-options "-Xmx${mem} -XX:ParallelGCThreads=${task.cpus}" \
        CreateSequenceDictionary \
        -R ${fa} \
        -O ${fa.baseName}.dict
    """
}

process indexVcf {

    label "GATK"
    label "process_low"
    tag "Indexing VCF"

    input:
    path vcf

    output:
    tuple path(vcf), path("*.{tbi,idx}", arity: '1'), emit: vcf

    script:

    def mem = task.memory ? "${task.memory.toGiga() - 1}g" : "4g"
    """
    gatk --java-options "-Xmx${mem} -XX:ParallelGCThreads=${task.cpus}" \
    IndexFeatureFile -I ${vcf}
    """
}

process addRG {
    label "GATK"
    label "process_medium"
    tag "${sample}"

    input:
    tuple val(sample), val(paired), path(bam), path(bai)
    // val(paired) is here only for consistency, it is not used in this process
    val rg_params

    output:
    tuple val(sample), path("${sample}_rg.bam"), path("${sample}_rg.bai"), emit: bam

    script:
    def mem = task.memory ? "${task.memory.toGiga() - 1}g" : "4g"
    """
    gatk --java-options "-Xmx${mem} -XX:ParallelGCThreads=${task.cpus}" \
    AddOrReplaceReadGroups \
        -I ${bam} \
        -O ${sample}_rg.bam \
        -RGSM ${sample} \
        ${rg_params} \
        -SO coordinate \
        --CREATE_INDEX true
    """
}

process splitNcigar {

    label "GATK"
    label "process_medium"
    tag "${sample}"

    input:
    tuple val(sample), path(bam), path(bai)
    tuple path(genome), path(index, arity: '1..2'), path(dict)
    val split_params

    output:
    tuple val(sample), path("${sample}_split.bam"), path("${sample}_split.bai"), emit: bam

    script:

    def mem = task.memory ? "${task.memory.toGiga() - 1}g" : "4g"
    """
    gatk --java-options "-Xmx${mem} -XX:ParallelGCThreads=${task.cpus}" \
    SplitNCigarReads \
        -I ${bam} \
        -O ${sample}_split.bam \
        -R ${genome} \
        --sequence-dictionary ${dict} \
        ${split_params} \
        --create-output-bam-index true
    """
}

process baseRecalibrator {

    label "GATK"
    label "process_high"
    tag "${sample}"

    input:
    tuple val(sample), path(bam), path(bai)
    tuple path(genome), path(index, arity: '1..2'), path(dict)
    tuple path(VCF), path(VCF_idx)
    val recal_params

    output:
    tuple val(sample), path("${sample}_recal.tbl"), emit: recal

    script:

    def mem = task.memory ? "${task.memory.toGiga() - 1}g" : "4g"
    """
    gatk --java-options "-Xmx${mem} -XX:ParallelGCThreads=${task.cpus}" \
    BaseRecalibrator \
        -I ${bam} \
        -O ${sample}_recal.tbl \
        -R ${genome} \
        --known-sites ${VCF} \
        ${recal_params}
    """
}

process applyBQSR {

    label "GATK"
    label "process_high"
    tag "${sample}"

    input:
    tuple val(sample), path(bam), path(bai)
    tuple path(genome), path(index, arity: '1..2'), path(dict)
    tuple val(ssample), path(recal_table)
    val bqsr_params

    output:
    tuple val(sample), path("${sample}_bqsr.bam"), path("${sample}_bqsr.bai"), emit: bam

    script:

    def mem = task.memory ? "${task.memory.toGiga() - 1}g" : "8g"
    """
    gatk --java-options "-Xmx${mem} -XX:ParallelGCThreads=${task.cpus}" \
    ApplyBQSR \
        -I ${bam} \
        -O ${sample}_bqsr.bam \
        -R ${genome} \
        --sequence-dictionary ${dict} \
        --bqsr-recal-file ${recal_table} \
        ${bqsr_params} \
        --create-output-bam-index true
    """
}
