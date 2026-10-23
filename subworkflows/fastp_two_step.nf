include {
    FASTP as FASTP_TRIM1 ;
    FASTP as FASTP_TRIM2
} from './fastp.nf'

// eCLIP specific two step trimming with fastp
workflow FASTP {
    take:
    ch_data
    adapter_file
    trim1_params
    trim2_params
    sourmash_cfg

    main:
    trim1 = FASTP_TRIM1(ch_data, adapter_file, trim1_params, sourmash_cfg, "trim1")
    trim2 = FASTP_TRIM2(trim1.trimmed, adapter_file, trim2_params, sourmash_cfg, "trim2")

    emit:
    trimmed = trim2.trimmed
    report = trim2.report
    first = trim1.trimmed
    first_report = trim1.report
    sourmash = trim1.sourmash | merge(trim2.sourmash)
    qc = trim1.qc | merge(trim2.qc)
    read_stats = trim1.read_stats.concat(trim2.read_stats)
}
