process fastp {
    label "process_low"
    tag "${sample} ${stage}"

    container params.singularity.trim

    input:
    tuple val(sample), val(paired), path(fastqs)
    path adapter_file
    val trim_params
    val stage

    output:
    tuple val(sample), val(paired), path("${sample}_${stage}*fq.gz"), emit: trimmed
    path("${sample}_${stage}_report.json"), emit: report
    tuple val(sample), val(stage), path("${sample}_${stage}_report.json"), emit: stats

    script:
    def json = "${sample}_${stage}_report.json"
    def outputs
    def inputs
    if (paired) {
        outputs = " -o ${sample}_${stage}_R1.fq.gz -O ${sample}_${stage}_R2.fq.gz"
        inputs = " -i ${fastqs[0]}  -I ${fastqs[1]}"
    } else {
        outputs = " -o ${sample}_${stage}.fq.gz"
        inputs = " -i ${fastqs}"
    }
    if (adapter_file == null || adapter_file == "") {
        trim_params = " -A "+ trim_params
    }else{
        trim_params = " --adapter_fasta "+ adapter_file + " " + trim_params
    }
    """
    fastp --thread ${task.cpus} --adapter_fasta ${adapter_file} ${trim_params} -j ${json} ${outputs} ${inputs}
    """
}

process trim_demultiplex{
    label "process_high"
    /*
    trim reads before demultiplexing using umi_tools
    umi_tools will fail if the reads are shorter than the barcode pattern
    */
    container params.singularity.trim
    
    input:
    tuple path(fastq), path(barcode)
    val min_read_length

    output:
    tuple path("${fastq.getBaseName(fastq.name.endsWith('.gz') ? 2 : 1)}_trimmed.fastq.gz"), path(barcode), emit: fastq
    path("${fastq.getBaseName(fastq.name.endsWith('.gz') ? 2 : 1)}_demultiplex_report.json"), emit: report

    script:
    def base = fastq.getBaseName(fastq.name.endsWith('.gz') ? 2 : 1)
    def output = base+"_trimmed.fastq.gz"
    def json = base+"_demultiplex_report.json"
    """
    fastp --thread ${task.cpus} -l ${min_read_length} -G -Q -A -n 50 -o ${output} -j ${json} -i ${fastq}
    """
}