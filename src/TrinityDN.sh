export MEMORY=__TRINITY_MEM__

source ../env.sh
export PATH=${TRINITY}:$PATH
export PATH=${BOWTIE2}:$PATH
export PATH=${JELLYFISH}:$PATH
export PATH=${SALMON}:$PATH

# Assemble transcripts De novo (DN)
run_cmd "Trinity --seqType fq --max_memory ${MEMORY} --SS_lib_type RF --left ${TRANSCRIPTOME_READS_1} --right ${TRANSCRIPTOME_READS_2} --output TrinityDN --CPU ${NCPUS} --trimmomatic --verbose > TrinityDN.log"

# Copy data from output directory
run_cmd "cp TrinityDN/Trinity.fasta Trinity-DN.fasta"
run_cmd "cp TrinityDN/Trinity.fasta.gene_trans_map Trinity-DN.fasta.gene_trans_map"

