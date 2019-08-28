export MEMORY=__TRINITY_MEM__

source ../env.sh
export PATH=${TRINITY}:$PATH
export PATH=${BOWTIE2}:$PATH
export PATH=${JELLYFISH}:$PATH
export PATH=${SALMON}:$PATH
export PATH=${SAMTOOLS}:$PATH

## Align reads using Bowtie2
run_cmd "bowtie2-build ${GENOME_NAME} ${GENOME_NAME}"
run_cmd "bowtie2 --very-sensitive-local --rf -x ${GENOME_NAME} -1 ${TRANSCRIPTOME_READS_1} -2 ${TRANSCRIPTOME_READS_2} -S ${GENOME_NAME}.bowtie2.readsmapped.sam --threads ${NCPUS}"

## Sort sam file using samtools
run_cmd "samtools view -@ ${NCPUS} -b ${GENOME_NAME}.bowtie2.readsmapped.sam | samtools sort -@ ${NCPUS} - > ${GENOME_NAME}.bowtie2.readsmapped.sorted.bam"

## Assemble transcripts using Trinity Genome Guide (GG)
# 
# If your library is not strended remove the '--SS_lib_type' option.
run_cmd "Trinity --SS_lib_type RF --genome_guided_bam ${GENOME_NAME}.bowtie2.readsmapped.sorted.bam --genome_guided_max_intron ${MAX_INTRON_LENGTH} --max_memory ${MEMORY} --CPU ${NCPUS} --output TrinityGG > TrinityGG.log"

# Copy data from output directory
run_cmd "cp TrinityGG/Trinity-GG.fasta ."
run_cmd "cp TrinityGG/Trinity-GG.fasta.gene_trans_map ."

