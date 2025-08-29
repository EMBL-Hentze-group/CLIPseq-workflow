include {samplesheetToList} from 'plugin/nf-schema'
// QCs
include {BBDUK} from './workflow/bbduk.nf'

// for output
nextflow.preview.output = true

// collect qc outputs
def collect_qc_outputs = { qc_channel ->
    qc_channel.zip.concat( qc_channel.html, qc_channel.multiqc)
    .collect()
    .flatten()
}
// collect trim outputs
def collect_trim_outputs = { trim_channel ->
    trim_channel.trimmed.map{it[2]}
    .concat(trim_channel.report.map{it[2]})
    .collect()
}
// collect sourmash outputs
def collect_sourmash_outputs = { sourmash_channel ->
    sourmash_channel.plot
    .concat(sourmash_channel.signatures, sourmash_channel.comparison.flatten())
    .collect()
}

workflow {
    main:
        ch_data = Channel
                .fromList(samplesheetToList(params.input, "./assets/schema_input.json"))
                .map {
                    sample, fastq_1, fastq_2 ->
                        // sample, paired, [fastq paths]
                        if (!fastq_2) {
                            return [ sample, false, [fastq_1]]
                        } else {
                            return [ sample, true, [fastq_1, fastq_2]]
                        }
                }
        ch_bbduk = BBDUK(ch_data, params.bbduk.ref_human, params.bbduk.params)
        multiqc = ch_bbduk.multiqc
        // Channel.merge(ch_bbduk.zip_free.collect(), ch_bbduk.zip_match.collect())
        multiqc.view()

}
