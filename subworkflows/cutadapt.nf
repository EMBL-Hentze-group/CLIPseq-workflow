include { fastqc } from '../modules/fastqc.nf'
include { multiqc as multiqc_P } from '../modules/multiqc.nf'
include { cutadapt as cutadapt_P } from '../modules/cutadapt.nf'

workflow CUTADAPT {
    take:
    ch_data
    cut_params
    stage

    main:
    cutadapt = cutadapt_P(ch_data, cut_params, stage)
    fqcs = fastqc(cutadapt.trimmed, stage)
    mqc = multiqc_P(fqcs.zip.collect(), stage)

    emit:
    trimmed = cutadapt.trimmed
    report = cutadapt.report
    zip = fqcs.zip
    html = fqcs.html
    multiqc = mqc.multiqc
}
