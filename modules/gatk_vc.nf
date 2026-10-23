/*
    GATK Variant Calling processes
*/
/*
    GATK Variant Calling Modules
    Includes:
    - haplotypeCaller: Call variants using HaplotypeCaller
    - mutect2: Call somatic variants using Mutect2
*/
process haplotypeCaller {

    label "GATK"
    label "process_high"
    tag "${sample}"

    input:
    tuple val(sample), path(bam), path(bai)
    tuple path(genome), path(index), path(dict)
    val hc_params

    output:
    tuple val(sample), path("${sample}.vcf"), path("${sample}.vcf.idx"), emit: vcf

    script:

    def mem = task.memory ? "${task.memory.toGiga() - 1}g" : "8g"
    """
    gatk --java-options "-Xmx${mem} -XX:ParallelGCThreads=${task.cpus}" \
    HaplotypeCaller \
        -I ${bam} \
        -O ${sample}.vcf \
        -R ${genome} \
        --sequence-dictionary ${dict} \
        ${hc_params}
    """
}

process mutect2 {

    label "GATK"
    label "process_high"
    tag "${sample}"

    input:
    tuple val(sample), path(bam), path(bai)
    tuple path(genome), path(index), path(dict)
    val mutect2_params

    output:
    tuple val(sample), path("${sample}.mutect2_raw.vcf.gz"), path("${sample}.mutect2_raw.vcf{,.gz}.{idx,tbi}", arity: '1'), path("${sample}.mutect2_raw.vcf{,.gz}.stats", arity: '1'), emit: vcf
    path ("${sample}.f1r2.tar.gz"), emit: f1r2

    script:

    def mem = task.memory ? "${task.memory.toGiga() - 1}g" : "8g"
    """
    gatk --java-options "-Xmx${mem} -XX:ParallelGCThreads=${task.cpus}" \
    Mutect2 \
        -I ${bam} \
        -O ${sample}.mutect2_raw.vcf.gz \
        --f1r2-tar-gz ${sample}.f1r2.tar.gz \
        -R ${genome} \
        --sequence-dictionary ${dict} \
        ${mutect2_params}
    """
}

process learnReadOrientation {

    label "GATK"
    label "process_high"
    tag "Learn Read Orientation"

    input:
    path f1r2
    val orientation_params

    output:
    path ("read-orientation-model.tar.gz"), emit: orientation

    script:

    def mem = task.memory ? "${task.memory.toGiga() - 1}g" : "8g"
    def inputs = "-I ${f1r2.join(' -I ')}"
    """
    gatk --java-options "-Xmx${mem} -XX:ParallelGCThreads=${task.cpus}" \
    LearnReadOrientationModel \
        ${inputs} \
        -O read-orientation-model.tar.gz \
        ${orientation_params}
    """
}

process filterMutect {
    label "GATK"
    label "process_high"
    tag "${sample}"

    input:
    tuple val(sample), path(vcf), path(idx), path(stats)
    tuple path(genome), path(index), path(dict)
    path orientation_model
    val filter_params

    output:
    tuple val(sample), path("${sample}.mutect2_filtered.vcf.gz"), path("${sample}.mutect2_filtered.vcf{,.gz}.{idx,tbi}", arity: '1'), emit: vcf

    script:

    def mem = task.memory ? "${task.memory.toGiga() - 1}g" : "8g"
    """
    gatk --java-options "-Xmx${mem} -XX:ParallelGCThreads=${task.cpus}" \
    FilterMutectCalls \
        -V ${vcf} \
        -O ${sample}.mutect2_filtered.vcf.gz \
        --reference ${genome} \
        --sequence-dictionary ${dict} \
        --orientation-bias-artifact-priors ${orientation_model} \
        ${filter_params}
    """
}
