source ../env.sh

n=0
while read cmdline
do
        n=$((n + 1))
        filearray[$n]=$cmdline
done < files2run.txt

run_cmd "${BLAST}/blastx -query ${filearray[$PBS_ARRAY_INDEX]} -db ${BLASTX_PROTEIN_DB} -out ${filearray[$PBS_ARRAY_INDEX]}.blastx.outfmt6 -evalue 1e-20 -num_threads ${NCPUS} -max_target_seqs 1 -outfmt 6"

