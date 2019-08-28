source ../env.sh
export PATH=${BLAT}:$PATH
export PATH=${SAMTOOLS}:$PATH

# Set SQLite database path to $TMPDIR (need to fully resolve path)
sed -i -e "s@DATABASE=.*@DATABASE=${TMPDIR}/${GENOME_NAME}_pasadb.sqlite@" alignAssembly.config

run_cmd "${PASA}/Launch_PASA_pipeline.pl -c alignAssembly.config -C -R -g ${GENOME_NAME} --MAX_INTRON_LENGTH ${MAX_INTRON_LENGTH} --ALIGNERS blat --CPU ${NCPUS} -T -t transcripts.fasta.clean -u transcripts.fasta > pasa.log 2>&1"

run_cmd "${PASA}/scripts/pasa_asmbls_to_training_set.dbi --pasa_transcripts_fasta ${GENOME_NAME}_pasadb.sqlite.assemblies.fasta --pasa_transcripts_gff3 ${GENOME_NAME}_pasadb.sqlite.pasa_assemblies.gff3"

