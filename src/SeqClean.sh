source ../env.sh
export PATH=${BLASTALL}:$PATH
export PATH=${PASA}/pasa-plugins/cdbtools/cdbfasta:$PATH
export PATH=${PASA}/pasa-plugins/seqclean/mdust:$PATH
export PATH=${PASA}/pasa-plugins/seqclean/psx:$PATH
export PATH=${PASA}/pasa-plugins/seqclean/trimpoly:$PATH

run_cmd "${PASA}/pasa-plugins/seqclean/seqclean/seqclean transcripts.fasta -v ${UNIVEC}"

