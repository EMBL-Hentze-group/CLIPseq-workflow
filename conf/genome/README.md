
## Required files

| Param name |      Used by        | Description |
|------------|---------------------|-------------|
| fai        | [bedGraph](modules/tracks.nf)| FASTA index (`.fa.fai`) for the genome, used to set chromosome sizes for track generation (see [`samtools faidx`](https://www.htslib.org/doc/samtools-faidx.html)) |
| rRNA_fa    | [bbduk](modules/bbduk.nf)|  Reference sequences for rRNA filtering |
| gff3       | [shoji annotation](modules/shoji.nf)| Reference annotation to generate sliding windows (e.g. [GENCODE](https://www.gencodegenes.org/))|
| STAR_index | [STAR align](modules/star.nf) | Build using [`STAR --runMode genomeGenerate`](https://github.com/alexdobin/STAR/blob/master/doc/STARmanual.pdf) against your genome FASTA or FASTA + GTF|

### Shoji parameters

> :warning: When using GFF3 files from sources other than GENCODE, shoji paramaters corresponding to gene id, name, type and optionally feature needs to supplied. In [hsa](conf/genome/hsa.config) and [rDNA](conf/genome/hsa.config) configs, for the variable `annotation_params`, the values given to following parameters needs to be changed according to the GFF3 file.

| Param name | Description |
|------------|-------------|
|`--gene_id` | Gene id tag in the GFF3 attribute column (default value: gene_id)|
|`--gene_name` | Gene name tag in the GFF3 attribute column (default value: gene_name)|
|`--gene_type` | Gene type tag in the GFF3 attribute column (default value: gene_type)|