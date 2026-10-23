include { faidx } from '../modules/samtools.nf'
include { dictFa } from '../modules/gatk_preprocess.nf'

workflow GenomeIndex {
    take:
    genome

    main:
    faidx(genome)
    dictFa(faidx.out.indx)

    emit:
    indx = dictFa.out
}
