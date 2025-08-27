include {FASTQC} from '../modules/fastqc.nf'
include {MULTIQC} from '../modules/multiqc.nf'
include {FASTP as FASTP_P} from '../modules/fastp.nf'

workflow FASTP{
    take:
        ch_data
        stage
        cut_params
    main:
        fastp = FASTP_P(ch_data, stage, cut_params)
        fqcs = FASTQC(fastp.trimmed, stage)
        mqc = MULTIQC(fqcs.zip.collect(),stage)
    emit:
        trimmed = fastp.trimmed
        report = fastp.report
        zip = fqcs.zip
        html = fqcs.html
        multiqc = mqc.multiqc
}