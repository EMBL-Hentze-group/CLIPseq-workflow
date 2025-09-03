include { fastqc } from '../modules/fastqc.nf'
include { multiqc as multiqc_P } from '../modules/multiqc.nf'

workflow QC {
    take:
    ch_data
    stage

    main:
    fqcs = fastqc(ch_data, stage)
    mqc = multiqc_P(fqcs.zip.collect(), stage)

    emit:
    zip = fqcs.zip
    html = fqcs.html
    multiqc = mqc.multiqc
}
