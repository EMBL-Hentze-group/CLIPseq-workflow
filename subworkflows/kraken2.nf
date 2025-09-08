include { 
    kraken2
    kraken2Mpa
    combineMpa
 } from '../modules/kraken2.nf'

workflow KRAKEN2{

    take:
    fastqs
    db
    kraken2_params
    report2mpa_params
    stage

    main:
    kraken2_out = kraken2(fastqs, db, kraken2_params, stage)
    mpa_out = kraken2Mpa(kraken2_out.report, report2mpa_params, stage)
    combined_mpa = combineMpa(mpa_out.mpa.collect(), stage)

    emit:
    classified = kraken2_out.classified
    unclassified = kraken2_out.unclassified
    
    report = kraken2_out.report.map{it[1]}.collect()|
                merge(mpa_out.mpa.collect())|
                merge(combined_mpa.mpa_report.collect())
}
