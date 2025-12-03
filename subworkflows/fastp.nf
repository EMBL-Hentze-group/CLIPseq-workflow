include { fastqc } from '../modules/fastqc.nf'
include { 
    multiqc as multiqc_F;
    multiqc as multiqc_T;
 } from '../modules/multiqc.nf'
include { fastp as fastp_P } from '../modules/fastp.nf'
include { SOURMASH } from './sourmash.nf'
include { stats } from '../modules/seqkit.nf'

workflow FASTP {
    take:
    ch_data
    adapter_file
    trim_params
    sketch_params
    abund
    compare_K
    stage

    main:
    fastp = fastp_P(ch_data, adapter_file, trim_params, stage)
    fqcs = fastqc(fastp.trimmed, stage)
    mqc_fq = multiqc_F(fqcs.zip.collect(), stage)
    mqc_trim = multiqc_T(fastp.report.collect(), "${stage}_stats")
    sourmash = SOURMASH(fastp.trimmed, sketch_params, abund, compare_K, stage)
    stats_read = stats(fastp.trimmed, stage)

    emit:
    trimmed = fastp.trimmed
    report = fastp.report|merge(mqc_trim.multiqc)
    // sourmash
    sourmash = sourmash.signatures|merge(sourmash.comparison)|merge(sourmash.plot)
    // qc
    qc = fqcs.zip|merge(fqcs.html)|merge(mqc_fq.multiqc)
    // read stats
    read_stats = stats_read.stats
}

workflow FASTP_2STEP {
    take:
    ch_data
    trim1_params
    trim2_params
    sketch_params
    abund
    compare_K

    main:
    trim1 = FASTP(ch_data, trim1_params, sketch_params, abund, compare_K, "trim1")
    trim2 = FASTP(trim1.trimmed, trim2_params, sketch_params, abund, compare_K, "trim2")
    emit:
    // second trim
    trimmed = trim2.trimmed
    report = trim2.report
    // first trim
    first = trim1.trimmed
    first_report = trim1.report
    // sourmash
    sourmash = trim1.sourmash|merge(trim2.sourmash)
    // qc
    qc = trim1.qc|merge(trim2.qc)
    // read stats
    read_stats = trim1.read_stats.concat(trim2.read_stats)

}