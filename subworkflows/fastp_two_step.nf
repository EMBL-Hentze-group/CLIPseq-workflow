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