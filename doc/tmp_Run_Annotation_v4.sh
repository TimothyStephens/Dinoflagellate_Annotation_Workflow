## 
## 		Dinoflagellate Annotation Pipeline
## 
## 
## NOTE:
##      - Transcriptome reads need to be cleaned (free of adapters) before being feed into this workflow
##      - Files obviously can't have special characters
## 
## 
## TODO:
## 	- Modify Genemark to accept donor sites other than GT. It is writen mainly in perl (and some C++) but the 
## 		GT donor site is hard coded in to all scripts. Not exactly sure how you would go about fixing this/if  
## 		it is even possible (too hard coded in). 
## 	- Modify SNAP to accept donor sites other than GT. Coded in C++ so it will take a better coder than me to do it. 
## 	- TrinityDN does not easily take unpaired reads. (Can not take unpaired data if the data is strand specific)
## 	- Make an alternative to analyze_blastPlus_topHit_coverage.pl which does not require passing the while protein database
##		Can just run blast with custom output format which gives all the infor the script would need. 
## 
## 
## 
## 1a. RepeatMasker/Modeler
## 1b. TrinityGG
## 1c. TrinityDN
## 2. SeqClean
## 3. BLASTX
## 4. 
## 
## 
##        Genome Sequence                               RNA-Seq
##               |                                         |
##               |                                   +-----+-----------+
##               |                                   |                 |    
##       Repeat Masker/Modeler                   TrinityGG         TrinityDN
##               |                                   |                 |
##               |                                   +-----------------+
##               |                                           |
##               |                                        SeqClean
##               |                                           |
##               |                                           |
##               |                                          PASA
##               |                                           |
##               |                                           |
##               |                                        BLASTX
##               |                                           |
##               |                                    +------+-------+
##               |                                    |              |
##               |                                HHBLITS      Transposon_PSI
##               |                                    |              |
##   +--------+--+--------------+                     +------+-------+
##   |        |                 |                            |
##  gff     Hard              Soft                        CD-HITS
##   |        |                 |                            |
##   |        |                 |                            |
##   |        |                 |                       Golden Genes
##   |        |                 |                            |                  Protein DB
##   |        |             +----------+-------+-------------+                       |
##   |        |             |   |      |       |                                     |
##   |   GeneMark-ES      SNAP--+--AUGUSTUS    |                            Maker protein2genome
##   |        |             |          |       |                                     |
##   |        |             |          |       |                                     | 
##   +--------+-------------+---------EVM -----+-------------------------------------+
##                                     |
##                                   Filter
## 
## 
## 
## 
## 





#############################################
## Set up annotation workflow
#############################################
## 
## 
## NOTE:
##      - Can not have | chanracters in genome sequence names (will break downstream analysis i.e. GoldenSet and EVM)
##      - Genome names >50 characters my also result in errors
##	- ATGCN characters only in genome.
##      - Scaffolds <1000 bp will not be worth annotation plus they will slow down the process
## 
## 
## Create a new directory to do the annotation. Copy over the env.sh and softlink the wotkflow_setup.sh
## files from the src directory distributed with this document. To setup the workflow run "workflow_setup.sh all"
## or run the workflow_setup.sh script with other options to create each job as you need them.
source env.sh





## NOTE:
## 1) Trinity does not support mixing library types (e.g. stranded and non-stranded).
## 	So each lib type will have to be run seperately for both Trinity GG & DN.
## 2) Trinity does not like unpaired reads. These reads can only be given if the 
## 	lib is not stranded and they have to be concatenated to the end of the left 
## 	read file. These unpaired reads also need that have the /1 sufix added to them. 
## 	See (https://github.com/trinityrnaseq/trinityrnaseq/wiki/Running-Trinity) for a
## 	better description of how this works. 
## 
#############################################
## Trinity Genome Guided
#############################################
## 
## Make sure the correct strandedness '--SS_lib_type' is set for your library.
## You will also need to adjust the --rf flag for bowtie2 depending on your library.
## If your library is not strended remove this options completely. 
./workflow_setup.sh trinitygg
qsub run_TrinityGG.sh

## Clean Up.
rm -r TrinityGG/ ${GENOME_NAME}.*





#############################################
## Trinity De Novo
#############################################
## 
## Make sure the correct strandedness '--SS_lib_type' is set for your library.
## If your library is not strended remove this options completely. 
./workflow_setup.sh trinitydn
qsub run_TrinityDN.sh

## Clean Up.
rm -r TrinityDN/





#############################################
## SeqClean
#############################################
## 
## This stage removes any vector sequences or poly-A tails from transcripts. 
## 
./workflow_setup.sh seqclean

## At this stage you combine all of your assembled transcripts (from TrinityGG + 
## TrinityDN + 454 seqs etc.) together. A sample command is below.
cat Trinity-GG.fasta TrinityDN.Trinity.fasta > transcripts.fasta

## Once all seqs are together. 
qsub run_SeqClean.sh


#############################################
### Repeat Analysis
#############################################
## 
## This step first runs Repeat Modeler over your genome creating a 
## custome repeat database which is combined with the defails Repeat Masker DB.
## Repeat Masker is then run using this custom repeat database.
## 
## If you plan to run Repeat Masker without a custom repeat database you will need to 
## comment out the Repeat Modeler stage (see run_RepeatAnalysis.sh) and remove  
## "-lib ${GENOME_NAME}_CombinedRepeatLib.lib" from Repeat Masker.
./workflow_setup.sh repeats
qsub run_RepeatAnalysis.sh

## For more information about the output of Repeat Masker see http://www.repeatmasker.org/webrepeatmaskerhelp.html#reading


#### Recommend CladeC1
## cpus=24
## mem=30.7 GB
## Walltime=13:38:50+14:31:30
#### Recommend CladeF
## cpus=24
## mem=36.11GB
## Walltime=14:15:46+12:05:43
	
	
## Clean Up.
rm -r RM_*/





#############################################
## PASA
#############################################
## 
## 
## PASA has a habit of hanging after about 24hrs, this is ususally due to
## lack of vmem (qdel job and rerun with more vmem). 
## 
./workflow_setup.sh pasa


## Get accession numbers from Trinity De Novo transcripts for PASA pipeline.
## A sample command is below.
cat ../TRINITY_DN/TrinityDN.Trinity.fasta | ${PASA}/misc_utilities/accession_extractor.pl > TrinityDN.accs


qsub run_PASA.sh


#### Recommend CladeC1
## cpus=8
## mem=12.9GB
## Walltime=04:12:03
#### Recommend CladeF
## cpus=8
## mem=13GB
## Walltime=02:21:49


#############################################
## BLASTX_Prot DB + analyze_blastPlus_topHit_coverage.pl
#############################################

#Get protein sequences which have similarity to a Protein DB. 

## Allocate appropriate resources.
## NCPUS=<..> # e.g. 8
## PARTS=<..> # e.g. 50
bash run_BLASTX_Batch.sh


# if you change the number of parts need to change it in the pbs script
mkdir CONTIGS_SPLIT
perl $SCRIPTS/fasta-splitter.pl --n-parts 50 --out-dir CONTIGS_SPLIT ${GENOME_NAME}_pasadb.sqlite.assemblies.fasta.transdecoder.cds
ls -1 CONTIGS_SPLIT/*.cds > files2run.txt



	
#### Recommend CladeC1
## No.Jobs=200
## cpus=8 each job.
## mem=<20GB each job.
## Walltime=01:40:52-07:51:14 each job.
#### Recommend CladeF
## No.Jobs=200
## cpus=8 each job.
## mem=<20GB each job.
## Walltime=00:20:46-01:48:03 each job.

## Get Hit coverage for each PASA CDS processed. 
## Script will take a while (>1hr) to run. 
cat CONTIGS_SPLIT/*.blastx.outfmt6 > blastx.outfmt6
##                                        
${TRINITY}/util/analyze_blastPlus_topHit_coverage.pl blastx.outfmt6 ${GENOME_NAME}_pasadb.sqlite.assemblies.fasta.transdecoder.cds ${BLASTX_PROTEIN_DB}

## Gets the peptide sequences which have >70% similarity to SwissProt + Sym proteins.
## i.e. Bin_80, Bin_90 and Bin_100
ln -s ../PASA/${GENOME_NAME}_pasadb.sqlite.assemblies.fasta.transdecoder.pep .
cat blastx.outfmt6.hist.list | awk '{ if($1 == "Bin_100" || $1 == "Bin_90" || $1 == "Bin_80") print $2 }' > blastx.outfmt6.hist.list.top_bins.ids
cat blastx.outfmt6.hist.list.top_bins.ids | xargs ${SAMTOOLS}/samtools faidx ${GENOME_NAME}_pasadb.sqlite.assemblies.fasta.transdecoder.pep > ${GENOME_NAME}_pasadb.sqlite.assemblies.fasta.transdecoder.pep.top_bins.faa


#############################################
## HHBLITS
#############################################
## 
## 
## 
./workflow_setup.sh hhblits
qsub run_HHBLITS.sh

#### Recommend CladeC1
## cpus=24
## mem=2GB
## Walltime=00:42:41
#### Recommend CladeF
## cpus=24
## mem=56.8GB
## Walltime=00:06:52


# Check what errors occured.
# Expect: "WARNING: ignoring invalid symbol '*' at pos."
cat SEQS_SPLIT/*.stderr
cat SEQS_SPLIT/*.stderr | sed '/^$/d' |  wc -l
cat SEQS_SPLIT/*.stderr | sed '/^$/d' |  grep -c 'WARNING: ignoring invalid symbol'

# Get sequence ids which have at least 1 transposon hit. 
# Looks for 'No. 1' which is in front of first alignment. i.e. seq has transposon hit. 
for f in `grep -l "No 1" SEQS_SPLIT/*.part-*.hhr`; do cat $f | awk 'NR==1{print $2}'; done > HHBLITS.hit.seq.ids
	
# 'HHBLITS.hit.seq.ids' has seq names which have transposon hits. 
	
## Clean Up. 
rm -r SEQS_SPLIT/


#############################################
## TransposonPSI
#############################################
## 
## 
## 

# Run TransposonPSI
export SEQ=(*.pep.bin_*.faa)
export PATH=$PATH:/Users/timothy.stephens/Programs/blast-2.2.26/bin
/Users/timothy.stephens/Programs/TransposonPSI_08222010/transposonPSI.pl ${SEQ} prot > transposonPSI.log 2>&1

#### Run Locally CladeC1
## cpus=1
## Walltime=6:38:00
#### Run Locally CladeF
## cpus=1
## Walltime=2:11:00

# Get sequence ids which have transposon hits. 
cat *.TPSI.allHits | awk '{ print $5 }' | sort | uniq > TransposonPSI.hit.seq.ids

# 'TransposonPSI.hit.seq.ids' has seq names which have transposon hits. 


#############################################
## CD-HITS
#############################################
## 
## 
## 

ln -s ../PASA/${GENOME_NAME}_pasadb.sqlite.assemblies.fasta.transdecoder.pep .
ln -s ../BLASTX/blastx.outfmt6.hist.list.top_bins.ids .

# Get all seq IDs that have only  one CDS. 
awk '$3=="CDS"{print $0}' ../PASA/${GENOME_NAME}_pasadb.sqlite.assemblies.fasta.transdecoder.genome.gff3 | awk '{ print $9 }' | sed -e 's/.*Parent=\(.*\)/\1/' | sort | uniq -c | awk '{ if($1==1) print $2 }' > Single_CDS_Genes.ids

# Get seq IDs which have coords on the genome. 
awk '$3=="mRNA"{print $0}' ../PASA/${GENOME_NAME}_pasadb.sqlite.assemblies.fasta.transdecoder.genome.gff3 | awk '{ print $9 }' | sed -e 's/ID=\(.*\);Parent.*/\1/' > Genes_with_genome_coords.ids

#Filter IDs

# Get seq IDs that do NOT HAVE Transposon_PSI, HHBLITS Hits and are NOT Single Exon. 
# This script removes IDs which are in the HHBLITs, Transposon-PSI and Single Exon files. 
python $SCRIPTS/filter_ids.py -i blastx.outfmt6.hist.list.top_bins.ids -o blastx.outfmt6.hist.list.top_bins.ids.filtered_final -k Genes_with_genome_coords.ids -r Single_CDS_Genes.ids,../HHBLITS/HHBLITS.hit.seq.ids,../TRANSPOSON_PSI/TransposonPSI.hit.seq.ids

#Cluster Proteins at 75%
# Get peptide sequences which do not have transposon hits. 
cat blastx.outfmt6.hist.list.top_bins.ids.filtered_final | xargs ${SAMTOOLS}/samtools faidx ${GENOME_NAME}_pasadb.sqlite.assemblies.fasta.transdecoder.pep > ${GENOME_NAME}_pasadb.sqlite.assemblies.fasta.transdecoder.pep.filtered_final

#### Recommend C1
## cpus=24
## mem=1GB
## Walltime=00:00:05
#### Recommend F
## cpus=24
## mem=1GB
## Walltime=00:00:04

# File containing protein seqs which are representative of each cluster. 
*.filtered_final.cdhit75

# Get Seq headers for representative proteins. 
grep '>' ${GENOME_NAME}_pasadb.sqlite.assemblies.fasta.transdecoder.pep.filtered_final.cdhit75 > ${GENOME_NAME}_pasadb.sqlite.assemblies.fasta.transdecoder.pep.filtered_final.cdhit75.ids


#############################################
## *prepare_golden_genes_for_predictors_GA_DonorSite.pl*
#############################################

## Get PASA output for GoldenSet.
## 
## This script should get just the IDs given in the CD-HIT.ids.txt file in
## the same format as you would expect from PASA. This seems to be required by the 
## prepare_golden_genes script for some reason.
## This script might not work with different versions of PASA if the seq names are in a different format.
python $SCRIPTS/get_PASA_for__prepare_golden_genes.py --ids CD-HIT.ids.txt --pasa_assembly ../PASA/*.assemblies.fasta --pasa_cds ../PASA/*.assemblies.fasta.transdecoder.cds --pasa_peptides ../PASA/*.assemblies.fasta.transdecoder.pep --pasa_gff ../PASA/*.assemblies.fasta.transdecoder.gff3 --pasa_genome ../PASA/*.assemblies.fasta.transdecoder.genome.gff3


qsub run_GoldenGenes.sh

## Recommend C1
## cpus=24
## mem=11.75GB
## Walltime=00:28:44
#### Recommend F
## cpus=24
## mem=20.5GB
## Walltime=00:43:11

grep 'CDS' final_golden_genes.gff3.nr.golden.gff3 | awk '{ print $9 }' | sed -e 's/.*Parent=\(.*\)/\1/' | sort | uniq -c | awk '{ print $1 }' | sort -h | uniq -c



## Clean Up.
rm -r PASA.assemblies.fasta.transdecoder.gff3.contigs_queries/ ${GENOME_NAME}.masked_dir/ ${GENOME_NAME}.softmasked_dir/ PASA.assemblies.fasta.transdecoder.cds.gmap/ ${GENOME_NAME}.softmasked.gmap/ 


#############################################
## GeneMark-ES
#############################################

# Add "#!/usr/bin/env perl" to the top of the gmes_petap.pl script.
Time::HiRes


ln -s ../REPEAT_MASKING/${GENOME_NAME}.masked .

cat ../../PBS_head.sh ../../Genemark-ES.sh > run_GeneMark-ES.sh 
vi run_GeneMark-ES.sh 
## Allocate appropriate resources.
export NCPUS=<..> # e.g. 8
qsub run_GeneMark-ES.sh 

#### Recommend C1
## cpus=24
## mem=2.3GB
## Walltime=2:20:53
#### Recommend F
## cpus=24
## mem=5.5GB
## Walltime=2:53:23

## Clean Up.
rm -r data/ run/ info/ output/data output/gmhmm


#############################################
## SNAP
#############################################

mkdir SNAP
cd SNAP/

ln -s ../${GENOME_NAME} .
ln -s ../REPEAT_MASKING/${GENOME_NAME}.softmasked .
ln -s ../GOLDEN_GENES/final_golden_genes.gff3.nr.golden.zff .
grep '>' final_golden_genes.gff3.nr.golden.zff | sed 's/>\(.*\)/\1/' | xargs ${SAMTOOLS}/samtools faidx ${GENOME_NAME}.softmasked > snap.fasta

cat ../../PBS_head.sh ../../SNAP.sh > run_SNAP.sh
vi run_SNAP.sh
qsub run_SNAP.sh

## 
## Check stderr.
cat PREDICT/${GENOME_NAME}.softmasked_dir/*.softmasked.snap.stderr ## Expect: ...... contains fewer/more than .... unmasked nucleotides
cat PREDICT/${GENOME_NAME}.softmasked_dir/*.softmasked.snap.gff3.stderr ## Expect X entries from file .........


#### Recommend C1
## cpus=24
## mem=1.8GB
## Walltime=14:05
#### Recommend F
## cpus=24
## mem=7.5GB
## Walltime=23:06

## Clean Up.
rm -r ${GENOME_NAME}.softmasked_dir/


#############################################
## AUGUSTUS
#############################################

mkdir AUGUSTUS
cd AUGUSTUS/


ln -s ../GOLDEN_GENES/final_golden_genes.gff3.nr.golden.optimization.good.gb .
ln -s ../GOLDEN_GENES/final_golden_genes.gff3.nr.golden.train.good.gb .

cat ../../PBS_head.sh ../../Augustus.sh > run_AUGUSTUS.sh
vi run_AUGUSTUS.sh
qsub run_AUGUSTUS.sh

#### Recommend C1
## cpus=8 # Keep as 8 cpus.
## mem=1.14GB
## Walltime=21:13:03
#### Recommend F
## cpus=8 # Keep as 8 cpus.
## mem=3GB
## Walltime=06:53:46





## Update ${AUGUSTUS}/config/species/${SPECIES}/${SPECIES}_parameters.cfg
codingseq on
print_utr on

cp ../../Augustus_Prediction.sh AUGUSTUS_PRED.sh
vi run_AUGUSTUS_PRED.sh
bash run_AUGUSTUS_PRED.sh

cat PREDICTION/*.augustus.out | ${AUGUSTUS}/scripts/join_aug_pred.pl > augustus.gff3 
perl ${AUGUSTUS}/scripts/getAnnoFasta.pl augustus.gff3
## If you want the prot and nucl sequence predicted by augustus. 

## Recommend C1
## No.Jobs=100
## cpus=1 each job. #augustus runs single CPU only
## vmem=4GB each job.
## Walltime=00:34:21-1:28:47
#### Recommend F
## No.Jobs=100
## cpus=1 each job. #augustus runs single CPU only
## vmem=4GB each job.
## Walltime=00:38:13-08:11:44


grep 'ExitStatus' Aug_*.e* | egrep ': [^0]'

## Clean Up.
rm -r PREDICTION/ tmp_opt_*/



#############################################
## MAKER_PROTEIN
#############################################

mkdir MAKER_PROTEIN
cd MAKER_PROTEIN/

ln -s ../${GENOME_NAME} .
ln -s ../../MAKER_PROTEIN_maker_bopts.ctl .
ln -s ../../MAKER_PROTEIN_maker_exe.ctl .
ln -s ../../MAKER_PROTEIN_maker_opts.ctl .
ln -s ../../MAKER_PROTEIN_run_MAKER.sh .
cp ../../MAKER_PROTEIN_setup_maker_Batch.sh .

bash MAKER_PROTEIN_setup_maker_Batch.sh
for var in SPLIT_MAKER_BATCH/*; do cd ${var}; pwd; qsub run_MAKER.sh; cd ../..; sleep 1; done

## Combine output. 
for var in SPLIT_MAKER_BATCH/*_dir; do cd ${var}; echo ${var}; ${MAKER}/gff3_merge -d *.maker.output/*_master_datastore_index.log; cd ../..; done
for var in SPLIT_MAKER_BATCH/*_dir; do cd ${var}; echo ${var}; ${MAKER}/fasta_merge -d *.maker.output/*_master_datastore_index.log; cd ../..; done
ls SPLIT_MAKER_BATCH/*_dir/*.all.gff | xargs ${MAKER}/gff3_merge
cat SPLIT_MAKER_BATCH/*_dir/*.all.maker.proteins.fasta > genome.all.maker.proteins.fasta
cat SPLIT_MAKER_BATCH/*_dir/*.all.maker.transcripts.fasta > genome.all.maker.transcripts.fasta


# Get only MAKER predictions, ignore all other intermediate info. e.g. Repeatmasker gff.
awk '{ if($2=="maker")print $0 }' genome.all.gff > genome.all.maker.gff



#### Recommend C1
## No.Jobs=400
## cpus=4 each job.
## mem=10GB each job.
## Walltime_C=01:12:48-31:55:13
#### Recommend F
## No.Jobs=400
## cpus=4 each job.
## mem=10GB each job.
## Walltime_C=01:59:09-39:54:46


# Get any non-zero Exitstatus. If this gives results we have a problem. 
grep 'ExitStatus' MAKER_PROTEIN_*.e* | egrep ': [^0]'

# Count finished MAKER jobs. Just to check. 
grep 'Maker is now finished!!!' SPLIT_MAKER_BATCH/*/maker.stderr | wc -l

grep -i 'error' SPLIT_MAKER_BATCH/*_dir/maker.stderr | less ## Only if there is a problem. 
grep -i 'warning' SPLIT_MAKER_BATCH/*_dir/maker.stderr | less ## Expect some warnings. 
grep -i 'warning' SPLIT_MAKER_BATCH/*_dir/maker.stderr | grep -v 'Karlin-Altschul parameters' ## Can ignore these errors. 


# Print entries in MAKER datastore which are non-normal. 
awk '!/FINISHED/ && !/STARTED/' SPLIT_MAKER_BATCH/*_dir/*.maker.output/*_master_datastore_index.log

cat SPLIT_MAKER_BATCH/*_dir/*.maker.output/*_master_datastore_index.log | grep -c 'STARTED'
cat SPLIT_MAKER_BATCH/*_dir/*.maker.output/*_master_datastore_index.log | grep -c 'FINISHED'
cat SPLIT_MAKER_BATCH/*_dir/*.maker.output/*_master_datastore_index.log | wc -l




#############################################
## EvidenceModeler
#############################################

ln -s ../${GENOME_NAME} .
cp ../../evm_weights.txt .

#############################
#### ABINITIO_PREDICTION ####
ln -s ../GENEMARK-ES/genemark.gff3 .
ln -s ../SNAP/PREDICT/snap.gff3 .
ln -s ../AUGUSTUS/augustus.gff3 .
ln -s ../MAKER_PROTEIN/genome.all.maker.gff .
ln -s ../PASA/*.transdecoder.genome.gff3 .


# Remove Hash tag from GeneMark-ES gff file. 
grep "^[^#]" genemark.gff3 > abinitio_gene_predictions.gff3 

# Remove Hash tags, blank line and update 2nd column 'SNAP'
grep "^[^#]" snap.gff3 | sed '/^$/d' | awk '{print $1 "\tSNAP\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8 "\t" $9}' >> abinitio_gene_predictions.gff3

# Convert AUGUSTUS gff3 to EVM compatible format. 
${EVM_HOME}/EvmUtils/misc/augustus_GFF3_to_EVM_GFF3.pl augustus.gff3 | sed '/^$/d' >> abinitio_gene_predictions.gff3

# Add on MAKER gff features. 
cat genome.all.maker.gff >> abinitio_gene_predictions.gff3

# Remove Hash tag lines and blank lines. 
grep "^[^#]" *.transdecoder.genome.gff3 | sed '/^$/d' >> abinitio_gene_predictions.gff3


# If it passes Validation without anything printed your .gff3 should be fine. 
${EVM_HOME}/EvmUtils/gff3_gene_prediction_file_validator.pl abinitio_gene_predictions.gff3

	
#################
#### REPEATS ####
ln -s ../REPEAT_MASKING/${GENOME_NAME}.out.gff .
grep "^[^#]" ${GENOME_NAME}.out.gff > repeats.gff3
${EVM_HOME}/EvmUtils/gff3_gene_prediction_file_validator.pl repeats.gff3


## Set up weights.
vi evm_weights.txt 
ABINITIO_PREDICTION	GeneMark.hmm	2
ABINITIO_PREDICTION	SNAP	2
ABINITIO_PREDICTION	Augustus	6
ABINITIO_PREDICTION	maker	8
OTHER_PREDICTION	transdecoder	10


cat ../../PBS_head.sh ../../EVidenceModeler.sh > run_EVidenceModeler.sh
vi run_EVidenceModeler.sh
qsub run_EVidenceModeler.sh

#### Recommend 
## cpus=24
## vmem=23.1GB
## Walltime_C=09:56:18



# Combine all evm.out.log files from each scaffold.  
cat PARTITIONS_EVM/*/evm.out.log > evm.out.combined.log


#### Count 'error' lines. 'Error with prediction:' lines are OK to ignore. Is caused when genes overlap and EVM tries to calculate intergenic regions, i.e. cant have space in between genes if genes overlap. 
grep -i 'error' evm.out.combined.log | wc -l
#### Count how many errors are OK to ignore.
grep -i 'error' evm.out.combined.log | grep 'Error with prediction:' | wc -l

#### Check for more known error. If anything turns up it needs to be fixed!!
grep -i 'alignment gap has misordered coords' evm.out.combined.log # gff format issues
grep -i 'VAR' evm.out.combined.log # Possible problem sorting gff features









