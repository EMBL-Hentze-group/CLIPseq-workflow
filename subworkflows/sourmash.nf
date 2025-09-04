include {
    sketch
    compare
    sourmashPlot
} from '../modules/sourmash.nf'

workflow SOURMASH {
    take:
    ch_data
    sketch_params
    abund
    compare_K
    stage

    main:
    signatures = sketch(ch_data, sketch_params, abund, stage)
    comparisons = compare(signatures.sig.collect(), compare_K, stage)
    plots = sourmashPlot(comparisons.npy, compare_K, stage)

    emit:
    signatures = signatures.sig
    comparison = comparisons.npy
    plot = plots.pdf
}

/*
Wrapper workflow for SOURMASH to merge results at different stages
so that final channels are consistent across different workflows
*/
workflow SOURMASH_WRAPPER {
    take:
    ch_data
    sketch_params
    abund
    compare_K
    stage

    main:
    smw = SOURMASH(ch_data, sketch_params, abund, compare_K, stage)

    emit:
    sourmash = smw.signatures|merge(smw.comparison)|merge(smw.plot)
}
