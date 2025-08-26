include {SKETCH} from '../modules/sourmash_sketch.nf'
include {COMPARE} from '../modules/sourmash_compare.nf'
include {SOURMASH_PLOT} from '../modules/sourmash_plot.nf'

workflow SOURMASH {
    take:
        ch_data
        stage
        sketch_params
        abund
        compare_K
    main:
        signatures = SKETCH(ch_data, stage, sketch_params, abund)
        compare = COMPARE(signatures.sig.collect(), stage, compare_K)
        plots = SOURMASH_PLOT(compare.npy, stage, compare_K)
    emit:
        signatures = signatures.sig
        comparison = compare.npy
        plot = plots.pdf
}