process dedup {
    label "UMITOOLS"
    label "process_low"
    // TODO fix this later
    tag "${sample} ${stage}"

    /*
    see conf/conda/apptainer.config for singularity params and
        conf/conda/conda.config for conda params
    */
    // container params.singularity.umi_tools
    // conda params.conda.umi_tools

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

process UMI_extract{
    label "UMITOOLS"
    label "process_single"

    /*
    see conf/conda/apptainer.config for singularity params and
        conf/conda/conda.config for conda params
    */
    // container params.singularity.umi_tools
    // conda params.conda.umi_tools

    input:
    tuple path(fastq), path(barcode)
    val pattern
    
    output:
    tuple path("${fastq.getBaseName(fastq.name.endsWith('.gz') ? 2 : 1)}_demux.fastq.gz"), path(barcode), emit: fastq
    path("${fastq.getBaseName(fastq.name.endsWith('.gz') ? 2 : 1)}.log"), emit: log

    script:
    def base = fastq.getBaseName(fastq.name.endsWith('.gz') ? 2 : 1)
    def output = base+"_demux.fastq.gz"
    """
    umi_tools extract -p ${pattern} -I ${fastq} -E ${base}.log -S ${output}
    """
}

process R2CLIP_extract{
    label "UMITOOLS"
    label "process_single"
    tag "${sample}"

    /*
    see conf/conda/apptainer.config for singularity params and
        conf/conda/conda.config for conda params
    */
    // container params.singularity.umi_tools
    // conda params.conda.umi_tools

    input:
    tuple val(sample), path(fastq_1), path(fastq_2)
    val pattern

    output:
    tuple val(sample), path("${sample}.fq.gz"), emit: fastq
    path("${sample}.log"), emit: log


    script:
    """
    umi_tools extract  --bc-pattern2 ${pattern} --extract-method "string" -I ${fastq_1} --read2-in ${fastq_2} -E ${sample}.log -S ${sample}.fq.gz
    """
}