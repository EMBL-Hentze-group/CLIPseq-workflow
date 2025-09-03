include { fastqc } from '../modules/fastqc.nf'
include { multiqc as multiqc_P } from '../modules/multiqc.nf'
include { fastp as fastp_P } from '../modules/fastp.nf'
include { SOURMASH } from './sourmash.nf'

workflow FASTP {
    take:
    ch_data
    cut_params
    sketch_params
    abund
    compare_K
    stage

    main:
    fastp = fastp_P(ch_data, cut_params, stage)
    fqcs = fastqc(fastp.trimmed, stage)
    mqc = multiqc_P(fqcs.zip.collect(), stage)
    sourmash = SOURMASH(fastp.trimmed, sketch_params, abund, compare_K, stage)

    emit:
    trimmed = fastp.trimmed
    report = fastp.report
    zip = fqcs.zip
    html = fqcs.html
    multiqc = mqc.multiqc
    signatures = sourmash.signatures
    comparison = sourmash.comparison
    plot = sourmash.plot
}
