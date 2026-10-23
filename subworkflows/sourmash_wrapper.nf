include { SOURMASH } from './sourmash.nf'
/*
Wrapper workflow for SOURMASH to merge results at different stages
so that final channels are consistent across different workflows
*/
workflow SOURMASH_WRAPPER {
    take:
    ch_data
    sourmash_cfg
    stage

    main:
    smw = SOURMASH(ch_data, sourmash_cfg, stage)

    emit:
    sourmash = smw.signatures | concat(smw.comparison) | concat(smw.plot)
}
