include { 
    kraken2
    kraken2Mpa
    combineMpa
    mergeReports
 } from '../modules/kraken2.nf'

include {
    SOURMASH as SOURMASH_CLASSIFIED
    SOURMASH as SOURMASH_UNCLASSIFIED
} from './sourmash.nf'
include {
    fastqc as fastqc_CLASSIFIED
    fastqc as fastqc_UNCLASSIFIED
} from '../modules/fastqc.nf'
include { 
    multiqc as multiqc_F;
    multiqc as multiqc_R;
 } from '../modules/multiqc.nf'

workflow KRAKEN2{
    take:
    fastqs
    db
    kraken2_params
    report2mpa_params
    nodes
    names
    sketch_params
    abund
    compare_K
    stage

    main:
    kraken2_out = kraken2(fastqs, db, kraken2_params, stage)
    mpa_out = kraken2Mpa(kraken2_out.report, report2mpa_params, stage)
    combined_mpa = combineMpa(mpa_out.mpa.collect(), stage)
    merged_reports = mergeReports(kraken2_out.report.map{it[1]}.collect(), nodes, names, stage)
    // SOURMASH
    sourmash_classified = SOURMASH_CLASSIFIED(kraken2_out.classified, sketch_params, abund, compare_K, "contamination_known")
    sourmash_unclassified = SOURMASH_UNCLASSIFIED(kraken2_out.unclassified, sketch_params, abund, compare_K, "contamination_unknown")
    // QC and QC reports
    fqcs_classified = fastqc_CLASSIFIED(kraken2_out.classified, "contamination_known")
    fqcs_unclassified = fastqc_UNCLASSIFIED(kraken2_out.unclassified, "contamination_unknown")
    zip = fqcs_classified.zip.merge(fqcs_unclassified.zip)
    mqc_fq = multiqc_F(zip.collect(), "contamination_known_vs_unknown")
    mqc_report = multiqc_R(kraken2_out.report.map{it[1]}.collect(), "${stage}_kraken2_contamination")
    emit:
    classified = kraken2_out.classified
    unclassified = kraken2_out.unclassified
    report = kraken2_out.report.map{it[1]}.collect()|
                merge(mpa_out.mpa.collect())|
                merge(combined_mpa.mpa_report.collect())|
                merge(mqc_report.multiqc)|
                merge(merged_reports.merged)
    read_stats =  kraken2_out.report.map{
        sample, report -> [sample, "kraken2", report]
    }

    // sourmash
    sourmash = sourmash_classified.signatures|merge(sourmash_unclassified.signatures)|
                merge(sourmash_classified.comparison)|merge(sourmash_unclassified.comparison)|
                merge(sourmash_classified.plot)|merge(sourmash_unclassified.plot)
    // qc
    qc = fqcs_classified.zip|merge(fqcs_unclassified.zip)|
            merge(fqcs_classified.html)|merge(fqcs_unclassified.html)|
            merge(mqc_fq.multiqc)
}
