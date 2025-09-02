
include {
    FASTQC
    MULTIQC
    } from '../modules/fastqc.nf'

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
        multiqc = mqc.multiqc
}