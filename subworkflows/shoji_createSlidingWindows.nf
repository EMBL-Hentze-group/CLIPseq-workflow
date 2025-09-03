include {
    annotation ;
    createSlidingWindows as createSlidingWindows_P
} from '../modules/shoji.nf'

workflow CREATE_SLIDING_WINDOWS {
    take:
    gff3
    tabix
    split_intron
    annot_params
    window
    step

    main:
    ch_annotation = annotation(gff3, tabix, split_intron, annot_params)
    ch_sliding_windows = createSlidingWindows_P(ch_annotation.annotation, tabix, window, step)

    emit:
    annotation = ch_annotation.annotation
    sliding_windows = ch_sliding_windows.sliding_windows
}
