process demultiplex{
    label "process_medium"

    container params.singularity.flexbar

    input:
    tuple path(fastq), path(barcode)
    val prefix
    val min_read_length
    val flexbar_params

    output:
    path("*.fastq.gz"), emit: fastq

    script:
    def params = flexbar_params + " -t ${prefix} -m ${min_read_length}"
    """
    flexbar -r ${fastq} -b ${barcode} -z GZ -O flexbar.log ${params}
    """
}
