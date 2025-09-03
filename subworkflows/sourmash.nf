include {
    sketch
    compare
    sourmashPlot
} from '../modules/sourmash.nf'
// include {COMPARE} from '../modules/sourmash.nf'
// include {SOURMASH_PLOT} from '../modules/sourmash.nf'

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
