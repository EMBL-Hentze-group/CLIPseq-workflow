include { bbduk as bbduk_P } from '../modules/bbduk.nf'
include {
    SOURMASH as SOURMASH_FREE
    SOURMASH as SOURMASH_MATCH
} from './sourmash.nf'
include {
        compare
        sourmashPlot
} from '../modules/sourmash.nf'
include {
    fastqc as fastqc_FREE
    fastqc as fastqc_MATCH
} from '../modules/fastqc.nf'
include { multiqc as multiqc_P } from '../modules/multiqc.nf'
include {
    stats as stats_match
    stats as stats_free    
    } from '../modules/seqkit.nf'

workflow BBDUK {
    take:
    ch_data
    ref
    bbduk_params
    sketch_params
    abund
    compare_K

    main:
    bbduk = bbduk_P(ch_data, ref, bbduk_params)
    // SOURMASH
    sourmash_free = SOURMASH_FREE(bbduk.free, sketch_params, abund, compare_K, "rRNA_free")
    sourmash_match = SOURMASH_MATCH(bbduk.match, sketch_params, abund, compare_K, "rRNA_match")
    sourmash_combined = compare(sourmash_free.signatures.collect()|merge(sourmash_match.signatures.collect()), compare_K, "rRNA_free_vs_match")
    sourmash_combined_plot = sourmashPlot(sourmash_combined.npy, compare_K, "rRNA_free_vs_match")
    // QC and QC reports
    fqcs_free = fastqc_FREE(bbduk.free, "rRNA_free")
    fqcs_match = fastqc_MATCH(bbduk.match, "rRNA_match")
    zip = fqcs_free.zip.merge(fqcs_match.zip)
    multiqc = multiqc_P(zip.collect(), "rRNA_free_vs_match")
    // seqkit stats
    reads_stats_match = stats_match(bbduk.match, "rRNA_match")
    reads_stats_free = stats_free(bbduk.free, "rRNA_free")
    emit:
    free = bbduk.free
    match = bbduk.match
    stats = bbduk.stats
    // sourmash 
    sourmash = sourmash_free.signatures|merge(sourmash_match.signatures)|
                merge(sourmash_free.comparison)|merge(sourmash_match.comparison)|
                merge(sourmash_free.plot)|merge(sourmash_match.plot)|
                merge(sourmash_combined.npy)|merge(sourmash_combined_plot.pdf)
    // qc
    qc = fqcs_free.zip|merge(fqcs_match.zip)|
            merge(fqcs_free.html)|merge(fqcs_match.html)|
            merge(multiqc.multiqc)
    // read stats
    read_stats = reads_stats_free.stats.concat(reads_stats_match.stats)
}
