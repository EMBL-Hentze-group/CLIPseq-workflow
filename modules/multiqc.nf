process MULTIQC{
    label "process_single"
    tag "$stage"
    
    input:
        path(zip)
        val stage

    output:
        path "${stage}_multiqc_report.html", emit: report
    
    container params.singularity.qc

    script:
    def zips = zip.flatten().join(' ')
    """
    echo zips: ${zip}
    multiqc --force --filename ${stage}_multiqc_report.html ${zips}
    """
    
}