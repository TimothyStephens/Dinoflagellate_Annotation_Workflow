
set -o errexit
source ../env.sh
export NCPUS=4
export NPARTS=100 ## e.g. 400
export NAME="${PREFIX}_maker_protein" ## Job name prefix.

M_BOPTS=MAKER_PROTEIN_maker_bopts.ctl
M_EXE=MAKER_PROTEIN_maker_exe.ctl
M_OPTS=MAKER_PROTEIN_maker_opts.ctl
M_RUN=MAKER_PROTEIN_run_MAKER.sh
BATCH_DIR=CONTIGS_SPLIT
REPEAT_LIB=${PWD}/../REPEAT_ANALYSIS/${GENOME_NAME}_CombinedRepeatLib.lib # Full path to custom RepLib. If no custom Lib leave BLANK!!

perl $SCRIPTS/fasta-splitter.pl --n-parts ${NPARTS} --out-dir ${BATCH_DIR} ${GENOME_NAME} 

for PART in ${BATCH_DIR}/*;
	do
	mkdir ${PART}_dir
	mv ${PART} ${PART}_dir
	
	cp ${M_BOPTS} ${PART}_dir/maker_bopts.ctl
	cp ${M_EXE} ${PART}_dir/maker_exe.ctl
	cp ${M_OPTS} ${PART}_dir/maker_opts.ctl
	cp ${M_RUN} ${PART}_dir/run_MAKER.sh
	
	echo ${PART}
	GENOME=${PART##*/}
	TMP=tmp/
        C=$(echo ${GENOME} | sed -e 's/.*.part-\(.*\).fa.*/\1/')
	#echo $C
	
	sed -i -e "s@__SEQS2RUN__@${GENOME}@" -e "s@__MPI_DB__@${PWD}@" -e "s@__NAME__@${NAME}_${C}@" -e "s@__NCPUS__@${NCPUS}@" ${PART}_dir/run_MAKER.sh
	sed -i -e "s@__PROTDB__@${PROTEINS_4_PREDICTION}@" -e "s@__NCPUS__@${NCPUS}@" -e "s@__MAX_INTRON_LENGTH__@${MAX_INTRON_LENGTH}@" -e "s@__REPEATLIB__@${REPEAT_LIB}@" ${PART}_dir/maker_opts.ctl
	sed -i -e "s@__BLAST__@${BLAST}@" -e "s@__REPEAT_MASKER__@${REPEATMASKER}@" -e "s@__EXONERATE__@${JAMG_PATH}/3rd_party/exonerate-2.2.0-x86_64/bin@" ${PART}_dir/maker_exe.ctl
	
	done

echo 'for var in CONTIGS_SPLIT/*; do cd ${var}; pwd; qsub run_MAKER.sh; cd ../..; done'




## Run certain parts. Usefull for managing your job submission/resource usage. 
# %03g for 3 digit NPARTS. 


#for var in $(seq -f "%03g" 1 100); do cd CONTIGS_SPLIT/*.part-${var}*_dir; pwd; qsub run_MAKER.sh; cd ../..; done
#for var in $(seq -f "%03g" 101 200); do cd CONTIGS_SPLIT/*.part-${var}*_dir; pwd; qsub run_MAKER.sh; cd ../..; done
#for var in $(seq -f "%03g" 201 300); do cd CONTIGS_SPLIT/*.part-${var}*_dir; pwd; qsub run_MAKER.sh; cd ../..; done
#for var in $(seq -f "%03g" 301 400); do cd CONTIGS_SPLIT/*.part-${var}*_dir; pwd; qsub run_MAKER.sh; cd ../..; done


