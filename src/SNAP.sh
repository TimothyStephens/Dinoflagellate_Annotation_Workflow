source ../env.sh

export PATH=$PATH:${CDBFASTA}
export ZOE=${SNAP}/Zoe

run_cmd "grep '>' final_golden_genes.gff3.nr.golden.zff | sed 's/>\(.*\)/\1/' | xargs ${SAMTOOLS}/samtools faidx ${GENOME_NAME}.softmasked > snap.fasta"

run_cmd "${SNAP}/fathom final_golden_genes.gff3.nr.golden.zff snap.fasta -gene-stats"
run_cmd "${SNAP}/fathom final_golden_genes.gff3.nr.golden.zff snap.fasta -validate"
run_cmd "${SNAP}/fathom final_golden_genes.gff3.nr.golden.zff snap.fasta -categorize 1000"

# Join uni (single gene per sequence) and wrn (genes with warnings) togther. Done to increase the number of genes used for training.
cat uni.ann wrn.ann > com.ann
cat uni.dna wrn.dna > com.dna

run_cmd "${SNAP}/fathom -export 1000 -plus com.ann com.dna"
run_cmd "${SNAP}/forge export.ann export.dna"
run_cmd "${SNAP}/hmm-assembler.pl -c 0.000 ${GENOME_NAME} . > ${GENOME_NAME}.snap.hmm" # model to use to predict

#predict
mkdir PREDICT; cd PREDICT/
ln -s ../${GENOME_NAME}.softmasked .

# create a directory with softmasked genome split for parallel run. use --n-parts <N> OR --part-size <N>
run_cmd "perl $SCRIPTS/fasta-splitter.pl --n-parts 2000 ${GENOME_NAME}.softmasked --out-dir ${GENOME_NAME}.softmasked_dir"

# prepare command for each genome sequence
for SEQ in ${GENOME_NAME}.softmasked_dir/*;
do
	echo "${SNAP}/snap ../${GENOME_NAME}.snap.hmm ${SEQ} -lcmask -quiet 1> ${SEQ}.snap 2> ${SEQ}.snap.stderr; perl ${SCRIPTS}/SNAP_output_to_gff3.pl ${SEQ}.snap ${SEQ} 1> ${SEQ}.snap.gff3 2>${SEQ}.snap.gff3.stderr" >> snap.commands
done

# Run commands in parallel.
run_cmd "${TRINITY}/trinity-plugins/BIN/ParaFly -c snap.commands -CPU ${NCPUS} -v -shuffle > parafly.log"

# Combine predictions for each scaffold. If number scaffolds >100,000 need to use find as cat fails with too many files. 
run_cmd "cat ${GENOME_NAME}.softmasked_dir/*.snap.gff3 > snap.gff3"

