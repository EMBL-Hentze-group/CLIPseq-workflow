include { sketch ; compare ; sourmashPlot } from '../modules/sourmash.nf'

workflow SOURMASH {
    take:
    ch_data
    sourmash_cfg
    stage

    main:
    signatures = sketch(ch_data, sourmash_cfg.sketch, sourmash_cfg.abund, stage)
    comparisons = compare(signatures.sig.collect(), sourmash_cfg.comparison_K, stage)
    plots = sourmashPlot(comparisons.npy, sourmash_cfg.comparison_K, stage)

    emit:
    signatures = signatures.sig
    comparison = comparisons.npy
    plot = plots.pdf
}
