include { fastqc } from '../modules/fastqc.nf'
include { multiqc as multiqc_P } from '../modules/multiqc.nf'
include { fastp as fastp_P } from '../modules/fastp.nf'
include { SOURMASH } from './sourmash.nf'
include { stats } from '../modules/seqkit.nf'

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
    stats_read = stats(fastp.trimmed, stage)

    emit:
    trimmed = fastp.trimmed
    report = fastp.report
    // sourmash
    sourmash = sourmash.signatures|merge(sourmash.comparison)|merge(sourmash.plot)
    // qc
    qc = fqcs.zip|merge(fqcs.html)|merge(mqc.multiqc)
    // read stats
    read_stats = stats_read.stats
}
