include {BBDUK as BBDUK_P} from '../modules/bbduk.nf'
include {FASTQC as FASTQC_F} from '../modules/fastqc.nf'
include {FASTQC as FASTQC_M} from '../modules/fastqc.nf'
include {MULTIQC} from '../modules/multiqc.nf'


workflow BBDUK{
    take:
        ch_data
        ref
        bbduk_params
        sketch_params
        abund
    main:
        bbduk = BBDUK_P(ch_data, ref, bbduk_params)
        // QC on rRNA free reads
        fqcs_free = FASTQC_F(bbduk.free, "rRNA_free")
        // QC on rRNA matched reads
        fqcs_match = FASTQC_M(bbduk.match, "rRNA_match")
        // collect FASTQC outputs
        zip = fqcs_free.zip.merge(fqcs_match.zip)
        html = fqcs_free.html.merge(fqcs_match.html)
        multiqc = MULTIQC(zip.collect(), "rRNA_free_vs_match")
    emit:
        free = bbduk.free
        match = bbduk.match
        stats = bbduk.stats
        zip = zip
        html = html
        multiqc = multiqc.multiqc
}