include {
    SKETCH
    COMPARE
    SOURMASH_PLOT
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
        signatures = SKETCH(ch_data, sketch_params, abund, stage)
        compare = COMPARE(signatures.sig.collect(), compare_K, stage)
        plots = SOURMASH_PLOT(compare.npy, compare_K, stage)
    emit:
        signatures = signatures.sig
        comparison = compare.npy
        plot = plots.pdf
}