include { fastqc } from '../modules/fastqc.nf'
include { multiqc as multiqc_P } from '../modules/multiqc.nf'
include { cutadapt as cutadapt_P } from '../modules/cutadapt.nf'
include { SOURMASH } from './sourmash.nf'

workflow CUTADAPT {
    take:
    ch_data
    cut_params
    sketch_params
    abund
    compare_K
    stage

    main:
    cutadapt = cutadapt_P(ch_data, cut_params, stage)
    fqcs = fastqc(cutadapt.trimmed, stage)
    mqc = multiqc_P(fqcs.zip.collect(), stage)
    sourmash = SOURMASH(cutadapt.trimmed, sketch_params, abund, compare_K, stage)

    emit:
    trimmed = cutadapt.trimmed
    report = cutadapt.report
    // sourmash
    sourmash = sourmash.signatures|merge(sourmash.comparison)|merge(sourmash.plot)
    // qc
    qc = fqcs.zip|merge(fqcs.html)|merge(mqc.multiqc)
    // zip = fqcs.zip
    // html = fqcs.html
    // multiqc = mqc.multiqc
}
