process demultiplex {
    label "FLEXBAR"
    label "process_high"

    input:
    tuple path(fastq), path(barcode)
    val prefix
    val min_read_length
    val flexbar_params

    output:
    path ("*.fastq.gz"), emit: fastq

    script:
    def params = flexbar_params + " -t ${prefix} -m ${min_read_length}"
    """
    ngs-statter flexbar -n ${task.cpus} -r ${fastq} -b ${barcode} -z GZ -O flexbar.log ${params}
    """
}
