source ../env.sh

run_cmd "${CDHIT}/cd-hit -i ${GENOME_NAME}_pasadb.sqlite.assemblies.fasta.transdecoder.pep.filtered_final -o ${GENOME_NAME}_pasadb.sqlite.assemblies.fasta.transdecoder.pep.filtered_final.cdhit75 -c 0.75 -n 5 -T ${NCPUS} -M @CDHITS_MEM@"

