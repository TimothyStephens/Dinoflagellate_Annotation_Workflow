source ../env.sh

mkdir FASTA_SPLIT
run_cmd "perl $SCRIPTS/fasta-splitter.pl --part-size 1 --measure seq --out-dir FASTA_SPLIT ${GENOME_NAME}_pasadb.sqlite.assemblies.fasta.transdecoder.pep.complete_only.filtered.top_coverage.faa"

## Run hhblits using a transposon database
# 
# -p [0,100]     minimum probability in summary and alignment list (default=20)
# -e     [0,1]   E-value cutoff for inclusion in result alignment (def=0.001)
# -E [0,inf[     maximum E-value in summary and alignment list (default=1E+06)
# -z <int>       minimum number of lines in summary hit list (default=10)
# -b <int>       minimum number of alignments in alignment list (default=10)
# -B <int>       maximum number of alignments in alignment list (default=500)
# -Z <int>       maximum number of lines in summary hit list (default=500)
# 
for var in FASTA_SPLIT/*.faa;
do 
	echo "${HHSUITE}/hhblits -cpu 1 -p 80 -e 1E-5 -E 1E-5 -z 0 -b 0 -B 3 -Z 3 -i ${var} -d ${TRANSPOSON_DB_HHBLITS} -o ${var}.hhr -n 1 1> ${var}.stdout 2> ${var}.stderr"; 
done > hhblits.commands

run_cmd "${TRINITY}/trinity-plugins/BIN/ParaFly -c hhblits.commands -failed_cmds hhblits.commands.failed -CPU ${NCPUS} -v -shuffle > parafly.log"


