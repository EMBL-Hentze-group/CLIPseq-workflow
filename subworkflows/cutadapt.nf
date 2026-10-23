include { fastqc } from '../modules/fastqc.nf'
include { multiqc as multiqc_P } from '../modules/multiqc.nf'
include { cutadapt as cutadapt_P } from '../modules/cutadapt.nf'
include { SOURMASH } from './sourmash.nf'
include { stats } from '../modules/seqkit.nf'

workflow CUTADAPT {
    take:
    ch_data
    cut_params
    sourmash_cfg
    stage

    main:
    cutadapt = cutadapt_P(ch_data, cut_params, stage)
    fqcs = fastqc(cutadapt.trimmed, stage)
    mqc = multiqc_P(fqcs.zip.collect(), stage)
    sourmash = SOURMASH(cutadapt.trimmed, sourmash_cfg, stage)
    stats_read = stats(cutadapt.trimmed, stage)

    emit:
    trimmed = cutadapt.trimmed
    report = cutadapt.report
    sourmash = sourmash.signatures | merge(sourmash.comparison) | merge(sourmash.plot)
    qc = fqcs.zip | merge(fqcs.html) | merge(mqc.multiqc)
    read_stats = stats_read.stats
}
