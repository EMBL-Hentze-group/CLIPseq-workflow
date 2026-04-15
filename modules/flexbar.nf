process demultiplex{
    label "FLEXBAR"
    label "process_high"

    /*
    see conf/conda/apptainer.config for singularity params and
        conf/conda/conda.config for conda params
    */
    // container params.singularity.flexbar
    // conda params.conda.flexbar

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
    flexbar -n ${task.cpus} -r ${fastq} -b ${barcode} -z GZ -O flexbar.log ${params}
    """
}
