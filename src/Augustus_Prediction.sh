
source ../../env.sh
export AUGUSTUS_PATH=${AUGUSTUS}
export AUGUSTUS_CONFIG_PATH=${AUGUSTUS}/config
export PATH=$PATH:${AUGUSTUS}/bin/

n=0
while read cmdline
do
        n=$((n + 1))
        filearray[$n]=$cmdline
done < files2run.txt

run_cmd "augustus --/IntronModel/allow_dss_consensus_gc=true --/IntronModel/allow_dss_consensus_ga=true --/IntronModel/non_gt_dss_prob=1 --softmasking=1 --gff3=on --UTR=on --exonnames=on --species=${SPECIES} ${filearray[$PBS_ARRAY_INDEX]} > ${filearray[$PBS_ARRAY_INDEX]}.augustus.out"


