
include {FASTQC} from '../modules/fastqc.nf'
include {MULTIQC} from '../modules/multiqc.nf'

workflow QC{
    take:
        ch_data
        stage
    main:
        fqcs = FASTQC(ch_data, stage)
        mqc = MULTIQC(fqcs.zip.collect(),stage)
    emit:
        zip = fqcs.zip
        html = fqcs.html
        report = mqc.report
}