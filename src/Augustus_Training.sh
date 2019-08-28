source ../env.sh

#Recommend 8 cpus
export AUGUSTUS_CONFIG_PATH=${AUGUSTUS}/config
export PATH=$PATH:${AUGUSTUS}/bin/

# the following will train the coding sequence models. The --metapars must point to a valid configuration which you can change if you want.
run_cmd "perl ${AUGUSTUS}/scripts/new_species.pl --species=$SPECIES"
run_cmd "perl ${AUGUSTUS}/scripts/optimize_augustus.pl --species=$SPECIES final_golden_genes.gff3.nr.golden.optimization.good.gb --onlytrain=final_golden_genes.gff3.nr.golden.train.good.gb --metapars=$AUGUSTUS_CONFIG_PATH/species/${SPECIES}/${SPECIES}_metapars.cfg --cpus=${NCPUS} --kfold=${NCPUS} 1> Augustus.opt_cds.stdout 2> Augustus.opt_cds.stderr"

# Once the above finishes, train the UTR model. 
run_cmd "perl ${AUGUSTUS}/scripts/optimize_augustus.pl --species=$SPECIES final_golden_genes.gff3.nr.golden.optimization.good.gb --onlytrain=final_golden_genes.gff3.nr.golden.train.good.gb --metapars=$AUGUSTUS_CONFIG_PATH/species/${SPECIES}/${SPECIES}_metapars.utr.cfg --cpus=${NCPUS} --kfold=${NCPUS} --trainOnlyUtr=1 --UTR=on 1> Augustus.opt_utr.stdout 2> Augustus.opt_utr.stderr"

