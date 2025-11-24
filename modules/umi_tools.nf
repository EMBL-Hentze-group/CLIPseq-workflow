process dedup {
    label "process_low"
    // TODO fix this later
    tag "${sample} ${stage}"

    container params.singularity.umi_tools

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

process extract{
    label "process_single"

    container params.singularity.umi_tools

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