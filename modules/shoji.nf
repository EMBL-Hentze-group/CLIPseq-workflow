process annotation {
    label "SHOJI"
    label "process_low"
    tag "shoji annotation"
    

    /*
    see conf/conda/apptainer.config for singularity params and
        conf/conda/conda.config for conda params
    */
    // conda params.conda.shoji

    input:
    path gff3
    val split_intron
    val annot_params

    output:
    path ("${gff3.getBaseName()}.bed.gz*"), emit: annotation

    script:
    def intron_param = split_intron ? "--split-intron" : ""
    """
    shoji annotation --tabix ${intron_param} ${annot_params} -a ${gff3} -o ${gff3.getBaseName()}.bed.gz
    """
}

process createSlidingWindows {
    label "SHOJI"
    tag "shoji createSlidingWindows"
    label "process_medium"

    /*
    see conf/conda/apptainer.config for singularity params and
        conf/conda/conda.config for conda params
    */
    // conda params.conda.shoji

    input:
    path(annotation, arity: 1..2) // expect either the annotation file alone or with its index
    val window
    val step

    output:
    path ("${annotation[0].getBaseName()}_w${window}_s${step}.bed.gz*"), emit: sliding_windows

    script:
    
    """
    shoji createSlidingWindows -c ${task.cpus} --tabix -w ${window} -s ${step} -a ${annotation[0]} -o ${annotation[0].getBaseName()}_w${window}_s${step}.bed.gz
    """
}

process extract {
    label "SHOJI"
    label "process_medium"
    tag "shoji extract ${sample}"

    /*
    see conf/conda/apptainer.config for singularity params and
        conf/conda/conda.config for conda params
    */
    // conda params.conda.shoji

    input:
    tuple val(sample), val(paired), path(bam), path(index)
    val ignore_pcr_duplicates
    val primary
    val mate
    val site
    val offset
    val extract_params

    output:
    tuple val(sample), path("${sample}.bed.gz*"), emit: sites

    script:
    def ignore_pcr_param = ignore_pcr_duplicates ? "--ignore-pcr-duplicates" : ""
    def primary_param = primary ? "--primary" : ""
    def params = extract_params + " -e ${mate} -s ${site} -g ${offset}"
    """
    shoji extract -c ${task.cpus} --tabix ${ignore_pcr_param} ${primary_param} ${params} -i ${index} -b ${bam} -o ${sample}.bed.gz
    """
}

process count {
    label "SHOJI"
    tag "shoji count ${sample}"
    label "process_medium"

    /*
    see conf/conda/apptainer.config for singularity params and
        conf/conda/conda.config for conda params
    */
    // conda params.conda.shoji

    input:
    tuple val(sample), path(sites, arity: 1..2) // expect either the sites file alone or with its index
    path (sliding_windows, arity: 1..2) // expect either the sliding window file alone or with its index

    output:
    path ("${sample}.parquet"), emit: counts

    script:
    """
    shoji count -c ${task.cpus} -a ${sliding_windows[0]} -n ${sample} -i ${sites[0]} -o ${sample}.parquet
    """
}

process createMatrix {
    label "SHOJI"
    tag "shoji createMatrix"
    label "process_medium"

    /*
    see conf/conda/apptainer.config for singularity params and
        conf/conda/conda.config for conda params
    */
    // conda params.conda.shoji

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
