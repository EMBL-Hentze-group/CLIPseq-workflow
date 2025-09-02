include {
    FASTQC
    MULTIQC
    } from '../modules/fastqc.nf'
// include {MULTIQC} from '../modules/multiqc.nf'
include {CUTADAPT as CUTADAPT_P} from '../modules/cutadapt.nf'

workflow CUTADAPT{
    take:
        ch_data
        cut_params
        stage
    main:
        cutadapt = CUTADAPT_P(ch_data, cut_params, stage)
        fqcs = FASTQC(cutadapt.trimmed, stage)
        mqc = MULTIQC(fqcs.zip.collect(),stage)
    emit:
        trimmed = cutadapt.trimmed
        report = cutadapt.report
        zip = fqcs.zip
        html = fqcs.html
        multiqc = mqc.multiqc
}