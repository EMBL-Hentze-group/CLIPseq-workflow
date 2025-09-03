process annotation {
    tag "shoji annotation"
    label "process_low"

    container params.singularity.shoji

    input:
    path gff3
    val tabix
    val split_intron
    val annot_params

    output:
    path ("${gff3.getBaseName()}.bed.gz"), emit: annotation

    script:
    def tabix_param = tabix ? "--tabix" : ""
    def intron_param = split_intron ? "--split-intron" : ""
    """
        shoji annotation ${tabix_param} ${intron_param} ${annot_params} -a ${gff3} -o ${gff3.getBaseName()}.bed.gz
        """
}

process createSlidingWindows {
    tag "shoji createSlidingWindows"
    label "process_medium"

    container params.singularity.shoji

    input:
    path annotation
    val tabix
    val window
    val step

    output:
    path ("${annotation.getBaseName()}_w${window}_s${step}.bed.gz"), emit: sliding_windows

    script:
    def tabix_param = tabix ? "--tabix" : ""
    """
        shoji createSlidingWindows -c ${task.cpus} ${tabix_param} -w ${window} -s ${step} -a ${annotation} -o ${annotation.getBaseName()}_w${window}_s${step}.bed.gz
        """
}

process extract {
    label "process_medium"
    tag "shoji extract ${sample}"

    container params.singularity.shoji

    input:
    tuple val(sample), val(paired), path(bam), path(index)
    val tabix
    val ignore_pcr_duplicates
    val primary
    val mate
    val site
    val offset
    val extract_params

    output:
    tuple val(sample), path("${sample}.bed.gz"), emit: sites

    script:
    def tabix_param = tabix ? "--tabix" : ""
    def ignore_pcr_param = ignore_pcr_duplicates ? "--ignore-pcr-duplicates" : ""
    def primary_param = primary ? "--primary" : ""
    def params = extract_params + " -e ${mate} -s ${site} -g ${offset}"
    """
        shoji extract -c ${task.cpus} ${tabix_param} ${ignore_pcr_param} ${primary_param} ${params} -i ${index} -b ${bam} -o ${sample}.bed.gz
        """
}

process count {
    tag "shoji count ${sample}"
    label "process_medium"

    container params.singularity.shoji

    input:
    tuple val(sample), path(bed)
    path sliding_windows

    output:
    path ("${sample}.parquet"), emit: counts

    script:
    """
        shoji count -c ${task.cpus} -a ${sliding_windows} -n ${sample} -i ${bed} -o ${sample}.parquet
        """
}

process createMatrix {
    tag "shoji createMatrix"
    label "process_medium"

    container params.singularity.shoji

    input:
    path (counts), name: "counts/*"
    val basename
    val suffix

    output:
    path ("${basename}_annotation.csv.gz"), emit: annotation
    path ("${basename}_counts.csv.gz"), emit: countsMat
    path ("${basename}_maxCounts.csv.gz"), emit: maxCountsMat

    script:
    """
        shoji createMatrix -c ${task.cpus} -i counts -s ${suffix} -a ${basename}_annotation.csv.gz -o ${basename}_counts.csv.gz -m ${basename}_maxCounts.csv.gz
        """
}
