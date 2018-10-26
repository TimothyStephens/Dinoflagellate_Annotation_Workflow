source ../env.sh

n=0
while read cmdline
do
        n=$((n + 1))
        filearray[$n]=$cmdline
done < files2run.txt

run_cmd "${BLAST}/blastp -query ${filearray[$PBS_ARRAY_INDEX]} -db ${BLAST_PROTEIN_DB} -out ${filearray[$PBS_ARRAY_INDEX]}.blastx.outfmt6 -evalue 1e-20 -num_threads ${NCPUS} -outfmt \"6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen\""

