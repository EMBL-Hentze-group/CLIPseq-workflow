process multiqc {
    label "MULTIQC"
    label "process_single"
    tag "${stage}"

    /*
    see conf/conda/apptainer.config for singularity params and
        conf/conda/conda.config for conda params
    */
    // container params.singularity.qc
    // conda params.conda.qc

    input:
    path zip
    val stage

    output:
    path "${stage}_multiqc_report.html", emit: multiqc

    script:
    def zips = zip.flatten().join(' ')
    """
    multiqc --force --filename ${stage}_multiqc_report.html ${zips}
    """
}
