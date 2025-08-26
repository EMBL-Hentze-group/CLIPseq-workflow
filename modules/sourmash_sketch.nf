process SKETCH {
    label "process_medium"
    tag "$sample $stage"

    input:
    tuple val(sample), val(paired), path(fastqs)
    val stage
    val sketch_params
    val abund

    output:
    path("${sample}_${stage}.sig.zip"), emit: sig

    container params.singularity.sourmash

    script:
    def out = "${sample}_${stage}.sig.zip"
    if (abund) {
        def sketch_params = sketch_params + ",abund"
        """
        echo "Abundance sketching for ${fastqs}, ${stage}"
        """
    } else {
        """
        echo "Non-abundance sketching for ${fastqs}, ${stage}"
        """
    }
    """
    sourmash sketch dna -f -p ${sketch_params} --name ${sample} -o ${out} ${fastqs}
    """
}