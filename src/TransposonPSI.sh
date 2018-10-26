source ../env.sh
export PATH=${BLAST}:$PATH

run_cmd "${TRANSPOSON_PSI}/transposonPSI_mod.pl ${GENOME_NAME}_pasadb.sqlite.assemblies.fasta.transdecoder.pep.top_bins.faa prot"

