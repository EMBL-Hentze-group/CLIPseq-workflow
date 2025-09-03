include {
    fastq as fastqMapped ;
    fastq as fastqUnmapped ;
    fastq as fastqMultimapped
} from '../modules/samtools.nf'

workflow TOFASTQ {
    take:
    ch_bam

    main:
    ch_fastq_map = fastqMapped(ch_bam, "mapped")
    ch_fastq_unmap = fastqUnmapped(ch_bam, "unmapped")
    ch_fastq_multimap = fastqMultimapped(ch_bam, "multimapped")

    emit:
    mapped = ch_fastq_map.fastq
    unmapped = ch_fastq_unmap.fastq
    multimapped = ch_fastq_multimap.fastq
}
