
include {
    CUTADAPT as CUTADAPT1
    CUTADAPT as CUTADAPT2
} from './cutadapt.nf'

workflow CUTADAPT_2STEP {
    take:
    ch_data
    trim1_params
    trim2_params
    sketch_params
    abund
    compare_K

    main:
    trim1 = CUTADAPT1(ch_data, trim1_params, sketch_params, abund, compare_K, "trim1")
    trim2 = CUTADAPT2(trim1.trimmed, trim2_params, sketch_params, abund, compare_K, "trim2")
    emit:
    // second cutadapt
    trimmed = trim2.trimmed
    report = trim2.report
    // first cutadapt
    first = trim1.trimmed
    first_report = trim1.report
    // sourmash
    sourmash = trim1.sourmash.concat(trim2.sourmash)
    // qc
    qc = trim1.qc.concat(trim2.qc)
    // read stats
    read_stats = trim1.read_stats.concat(trim2.read_stats)

}
