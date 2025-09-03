include {
    FASTP as FASTP_TRIM1
    FASTP as FASTP_TRIM2
    } from './fastp.nf'

// eCLIP specific two step trimming with fastp
workflow FASTP {
    take:
    ch_data
    trim1_params
    trim2_params
    sketch_params
    abund
    compare_K

    main:
    trim1 = FASTP_TRIM1(ch_data, trim1_params, sketch_params, abund, compare_K, "trim1")
    trim2 = FASTP_TRIM2(trim1.trimmed, trim2_params, sketch_params, abund, compare_K, "trim2")
    // collect SOURMASH outputs
    signatures = trim1.signatures.merge(trim2.signatures)
    comparison = trim1.comparison.merge(trim2.comparison)
    plot = trim1.plot.merge(trim2.plot)
    // collect QC outputs
    zip = trim1.zip.merge(trim2.zip)
    html = trim1.html.merge(trim2.html)
    multiqc = trim1.multiqc.merge(trim2.multiqc)
    emit:
    trimmed = trim2.trimmed
    report = trim2.report
    first = trim1.trimmed
    first_report = trim1.report
    signatures = signatures
    comparison = comparison
    plot = plot
    zip = zip
    html = html
    multiqc = multiqc

}