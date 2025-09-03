include { dedup } from '../modules/umi_tools.nf'
include { index } from '../modules/samtools.nf'

workflow UMI_DEDUP {
    take:
    ch_data
    dedup_params
    stage

    main:
    ch_umi_dedup = dedup(ch_data, dedup_params, stage)
    ch_index = index(ch_umi_dedup.bam)
    ch_bam = ch_umi_dedup.bam.join(ch_index.index, by: 0)

    emit:
    bam = ch_bam
}
