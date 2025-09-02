include {BBDUK as BBDUK_P} from '../modules/bbduk.nf'
include {
    SOURMASH as SOURMASH_FREE
    SOURMASH as SOURMASH_MATCH
    } from './sourmash.nf'
include {
    FASTQC as FASTQC_F
    FASTQC as FASTQC_M
    } from '../modules/fastqc.nf'
// include {FASTQC as FASTQC_M} from '../modules/fastqc.nf'
include {MULTIQC} from '../modules/multiqc.nf'


workflow BBDUK{
    take:
        ch_data
        ref
        bbduk_params
        sketch_params
        abund
        compare_K
    main:
        bbduk = BBDUK_P(ch_data, ref, bbduk_params)
        // SOURMASH
        sourmash_free = SOURMASH_FREE(bbduk.free, sketch_params, abund, compare_K, "rRNA_free")
        sourmash_match = SOURMASH_MATCH(bbduk.match, sketch_params, abund, compare_K, "rRNA_match")
        // collect SOURMASH outputs
        signatures = sourmash_free.signatures.merge(sourmash_match.signatures)
        comparison = sourmash_free.comparison.merge(sourmash_match.comparison)
        plot = sourmash_free.plot.merge(sourmash_match.plot)
        // QC and QC reports
        fqcs_free = FASTQC_F(bbduk.free, "rRNA_free")
        fqcs_match = FASTQC_M(bbduk.match, "rRNA_match")
        zip = fqcs_free.zip.merge(fqcs_match.zip)
        html = fqcs_free.html.merge(fqcs_match.html)
        multiqc = MULTIQC(zip.collect(), "rRNA_free_vs_match")
    emit:
        // bbduk outputs
        free = bbduk.free
        match = bbduk.match
        stats = bbduk.stats
        // sourmash outputs
        signatures = signatures
        comparison = comparison
        plot = plot
        // QC outputs
        zip = zip
        html = html
        multiqc = multiqc.multiqc
}