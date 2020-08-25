source ../env.sh

# Augustus training based on protocol from Hoff, K. J., & Stanke, M. (2019). Predicting genes in single genomes with AUGUSTUS. Current Protocols in Bioinformatics, 65, e57. doi: 10.1002/cpbi.57

#Recommend 8 cpus
export AUGUSTUS_CONFIG_PATH=${AUGUSTUS}/config
export PATH=$PATH:${AUGUSTUS}/bin/

# The following steps will train the coding and UTR sequence models. The --metapars must point to a valid configuration which you can change if you want.
run_cmd "perl ${AUGUSTUS}/scripts/new_species.pl --species=$SPECIES"

# Run initial training using golden genes
run_cmd "${AUGUSTUS}/bin/etraining --species=$SPECIES final_golden_genes.gff3.nr.golden.train.good.gb"

# Run meta parameter optimization (slow step)
run_cmd "perl ${AUGUSTUS}/scripts/optimize_augustus.pl --species=$SPECIES final_golden_genes.gff3.nr.golden.optimization.good.gb --onlytrain=final_golden_genes.gff3.nr.golden.train.good.gb --metapars=$AUGUSTUS_CONFIG_PATH/species/${SPECIES}/${SPECIES}_metapars.cfg --cpus=${NCPUS} 1> Augustus.opt_cds.stdout 2> Augustus.opt_cds.stderr"

# Run training after meta parameter optimization has finished.
run_cmd "${AUGUSTUS}/bin/etraining --species=$SPECIES final_golden_genes.gff3.nr.golden.train.good.gb"

# Run UTR meta parameter optimization (also slow step). 
run_cmd "perl ${AUGUSTUS}/scripts/optimize_augustus.pl --species=$SPECIES final_golden_genes.gff3.nr.golden.optimization.good.gb --onlytrain=final_golden_genes.gff3.nr.golden.train.good.gb --metapars=$AUGUSTUS_CONFIG_PATH/species/${SPECIES}/${SPECIES}_metapars.utr.cfg --cpus=${NCPUS} --trainOnlyUtr=1 --UTR=on 1> Augustus.opt_utr.stdout 2> Augustus.opt_utr.stderr"

# Run final training after UTR meta parameter optimization has finished.
run_cmd "${AUGUSTUS}/bin/etraining --species=$SPECIES final_golden_genes.gff3.nr.golden.train.good.gb"

