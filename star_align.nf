include {samplesheetToList} from 'plugin/nf-schema'

include {STARALIGN} from './workflow/star_align.nf'
include {STARALIGN_2PASS} from './workflow/star_align.nf'
include {UMI_DEDUP} from './workflow/umi_dedup.nf'

nextflow.enable.dsl=2

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
        ch_star = STARALIGN(ch_data, params.STAR.genomeDir, params.STAR.align_params, "firstPass")
        ch_dedup = UMI_DEDUP(ch_star.bam, params.umi_tools.dedup_params, "dedup")
        ch_dedup.bam.view()
        // Channel.merge(ch_bbduk.zip_free.collect(), ch_bbduk.zip_match.collect())
        // ch_2pass = STARALIGN_2PASS(ch_data, params.STAR.genomeDir, ch_star.junctions.collect(), "secondPass", params.STAR.align_params)

}