include {
    CUTADAPT as CUTADAPT1 ;
    CUTADAPT as CUTADAPT2
} from './cutadapt.nf'

workflow CUTADAPT_2STEP {
    take:
    ch_data
    trim1_params
    trim2_params
    sourmash_cfg

    main:
    trim1 = CUTADAPT1(ch_data, trim1_params, sourmash_cfg, "trim1")
    trim2 = CUTADAPT2(trim1.trimmed, trim2_params, sourmash_cfg, "trim2")

    emit:
    trimmed = trim2.trimmed
    report = trim2.report
    first = trim1.trimmed
    first_report = trim1.report
    sourmash = trim1.sourmash.concat(trim2.sourmash)
    qc = trim1.qc.concat(trim2.qc)
    read_stats = trim1.read_stats.concat(trim2.read_stats)
}
