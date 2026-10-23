process multiqc {
    label "MULTIQC"
    label "process_single"
    tag "${stage}"

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
