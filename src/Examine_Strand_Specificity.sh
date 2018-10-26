source ../env.sh
export PATH=${BOWTIE2}:$PATH
export PATH=${SAMTOOLS}:$PATH
export TRINITY_ASSEMBLY=__TRINITY_ASSEMBLY__

# Load R v3.5 and the vioplot package
module load R/3.5.0
export R_LIBS_USER=${PROGRAMS}/Rpackages/x86_64-pc-linux-gnu-library/3.5

## Align reads using Bowtie2
run_cmd "bowtie2-build ${TRINITY_ASSEMBLY} ${TRINITY_ASSEMBLY}"
run_cmd "bowtie2 --very-sensitive-local --no-unal -x ${TRINITY_ASSEMBLY} -1 ${TRANSCRIPTOME_READS_1} -2 ${TRANSCRIPTOME_READS_2} -S ${TRINITY_ASSEMBLY}.bowtie2.readsmapped.sam --threads ${NCPUS}"

run_cmd "samtools view -@ ${NCPUS} -b ${TRINITY_ASSEMBLY}.bowtie2.readsmapped.sam | samtools sort -@ ${NCPUS} - > ${TRINITY_ASSEMBLY}.bowtie2.readsmapped.sorted.bam"

run_cmd "perl ${TRINITY}/util/misc/examine_strand_specificity.pl ${TRINITY_ASSEMBLY}.bowtie2.readsmapped.sorted.bam"

