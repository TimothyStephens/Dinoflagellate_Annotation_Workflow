
## This is an attemp to document the steps required to install all programs used in the Dino annotation workflow

## Any modifications done to the programs will also be documented and the modified code will often be provided.

Programs used:
	Augustus v3.3.1
	Bamtools v2.4.1 (any version should be fine)
	BBmap v38.08 (any version should be fine)
	Bedtools v2.24.0 (any version usually avalible on all systems already)
	Blastall v2.2.26
	BLAT v36x2
	Bowtie2 v2.3.4.1
	CD-HIT v4.6.8
	cdbfasta v1
	Genemark-ES/ET v4.32
	hhsuite v3.0-beta.3
	JAMg release 01Jul2018
	Jellyfish v2.2.10
	NSEG
	PASA v2.3.3 (SQLite compatable)
	RECON v1.08
	RepeatMasker v4-0-7
	RepeatModeler v1.0.11
	rmblast v2.2.28
	RepeatScout v1.0.5
	Salmon v0.9.1
	Samtools (any version >1.0 usually avalible on all systems already)
	Tandem Repeats Finder v4.09
	TransposonPSI
	Trinity v2.6.6






#############################################
## AUGUSTUS
#############################################
## 
## http://bioinf.uni-greifswald.de/augustus/
## 
wget http://bioinf.uni-greifswald.de/augustus/binaries/augustus-3.3.1.tar.gz
tar -zxvf augustus-3.3.1.tar.gz
cd augustus-3.3.1/
## Next make the changes to each script detailed in Mods_to_programs.sh
## 
## Will not build anything in the auxprogs directory as they requires too many dependancys. 
## If you need these programs you will have to make them seperately. 

make




#############################################
## BBmap
#############################################
## 
## https://jgi.doe.gov/data-and-tools/bbtools/
## 
wget -O BBMap_38.08.tar.gz https://sourceforge.net/projects/bbmap/files/BBMap_38.08.tar.gz/download 
tar -zxvf BBMap_38.08.tar.gz



#############################################
## Blastall
#############################################
## 
## http://nebc.nox.ac.uk/bioinformatics/docs/blastall.html
## 
wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/legacy.NOTSUPPORTED/2.2.26/blast-2.2.26-x64-linux.tar.gz
tar -zxvf blast-2.2.26-x64-linux.tar.gz
./blast-2.2.26/bin/blastall 



#############################################
## BLAT
#############################################
## 
## https://genome.ucsc.edu/FAQ/FAQblat#blat3
## 
mkdir blat_v36x2
cd blat_v36x2/
wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/blat/blat
chmod +x blat
./blat



#############################################
## Bowtie2
#############################################
## 
## http://bowtie-bio.sourceforge.net/bowtie2/index.shtml
## 
wget https://sourceforge.net/projects/bowtie-bio/files/bowtie2/2.3.4.1/bowtie2-2.3.4.1-linux-x86_64.zip/download
mv download bowtie2-2.3.4.1-linux-x86_64.zip
unzip bowtie2-2.3.4.1-linux-x86_64.zip
./bowtie2-2.3.4.1-linux-x86_64/bowtie2
./bowtie2-2.3.4.1-linux-x86_64/bowtie2-build



#############################################
## CD-HIT
#############################################
## 
## https://github.com/weizhongli/cdhit
## 
wget https://github.com/weizhongli/cdhit/releases/download/V4.6.8/cd-hit-v4.6.8-2017-1208-source.tar.gz
tr -zxvf cd-hit-v4.6.8-2017-1208-source.tar.gz
cd cd-hit-v4.6.8-2017-1208/
make
./cd-hit



#############################################
## cdbfasta
#############################################
## 
## https://github.com/gpertea/cdbfasta
## 
git clone https://github.com/gpertea/cdbfasta.git
mv cdbfasta/ cdbfasta_v1
cd cdbfasta_v1/
make



#############################################
## EMBOSS
#############################################
## 
## http://emboss.sourceforge.net/
## 
wget ftp://emboss.open-bio.org/pub/EMBOSS/EMBOSS-6.6.0.tar.gz
tar -zxvf EMBOSS-6.6.0.tar.gz
cd EMBOSS-6.6.0/
./configure --prefix=$PWD
make
make check
make install
./bin/revseq --help



#############################################
## EVidenceModeler
#############################################
## 
## https://evidencemodeler.github.io/
## 
wget https://github.com/EVidenceModeler/EVidenceModeler/archive/v1.1.1.tar.gz
mv v1.1.1.tar.gz EVidenceModeler_v1.1.1.tar.gz
tar -zxvf EVidenceModeler_v1.1.1.tar.gz
mv EVidenceModeler-1.1.1 EVidenceModeler-1.1.1-modified
cd EVidenceModeler-1.1.1-modified/
# Modify file (See Mods_to_programs.sh)



#############################################
## Genemark-ES
#############################################
## 
## http://opal.biology.gatech.edu/GeneMark/
## 
## Need to register and download the 64bit version, as well as the key.
## Copy the gm_key_64 you downloaded to your home directory
cp gm_key_64 ~/.gm_key
tar -zxvf gm_et_linux_64.tar.gz
cd gm_et_linux_64/gmes_petap/
# Edit gmes_petap.pl (See Mods_to_programs.sh)



#############################################
## gmap
#############################################
## 
## http://research-pub.gene.com/gmap/
## 
wget http://research-pub.gene.com/gmap/src/gmap-gsnap-2018-07-04.tar.gz
tar -zxvf gmap-gsnap-2018-07-04.tar.gz
cd gmap-2018-07-04/
./configure --prefix=$PWD
make
make check
make install
./bin/gmap



#############################################
## HHBLITS
#############################################
## 
## hhsuite3: https://github.com/soedinglab/hh-suite
## 
## If you are using the transposon database distributed by JAMg
## you need to use hhsuite2 not 3. The database formats changed 
## between versions and is not backwards compatable. 
## 
## Also as hhsuite2 is no longer supported the pre-compiled binaries 
## are not avalible online and the source code available does not compile
## on delta. The pre-compiled binaries supplied with this workflow were downloaded 
## back in 2016
tar -zxvf hhsuite-latest-linux-x86_64.tar.gz
./hhsuite-2.0.16-linux-x86_64/bin/hhblits



#############################################
## JAMg
#############################################
## 
## https://github.com/genomecuration/JAMg
## See tutorial & procedures: http://jamg.sourceforge.net/
## 
git clone https://github.com/genomecuration/JAMg.git
date > JAMg/date_retrieved.txt

## You now have to modify the prepare_golden_genes_for_predictors.pl script
## provided by JAMg so it recognises GA acceptor sites.
## The easiest, cleanes and most portable approach is to copy these files into a clean directory.
mkdir Prepare_Golden_Genes
cp JAMg/date_retrieved.txt Prepare_Golden_Genes/
cp JAMg/bin/prepare_golden_genes_for_predictors.pl Prepare_Golden_Genes/prepare_golden_genes_for_predictors_GA_DonorSite.pl
cp JAMg/bin/run_exonerate.pl Prepare_Golden_Genes/run_exonerate_withPSSM.pl
cp -r JAMg/PerlLib Prepare_Golden_Genes/
## Next make the changes to each script detailed in Mods_to_programs.sh



#############################################
## Jellyfish
#############################################
## 
## https://github.com/gmarcais/Jellyfish
## 
mkdir -p Jellyfish-2.2.10/bin
cd Jellyfish-2.2.10/bin/
wget https://github.com/gmarcais/Jellyfish/releases/download/v2.2.10/jellyfish-linux
mv jellyfish-linux jellyfish
chmod +x jellyfish
./jellyfish



#############################################
## NSEG
#############################################
mkdir nseg
cd nseg/
wget ftp://ftp.ncbi.nih.gov/pub/seg/nseg/*
make
./nseg
./nmerge 



#############################################
## PASA (SQLite compatable)
#############################################
## 
## https://github.com/PASApipeline/PASApipeline/wiki
## 
## Needs Perl modules: 
## 	Data::Dumper
## 	DBD::SQLite
## 	DB_File
wget https://github.com/PASApipeline/PASApipeline/releases/download/pasa-v2.3.3/PASApipeline-v2.3.3.tar.gz
tar -zxvf PASApipeline-v2.3.3.tar.gz
mv PASApipeline-v2.3.3 PASApipeline-v2.3.3-modified
cd PASApipeline-v2.3.3-modified/
# Modify file (See Mods_to_programs.sh)
make
./Launch_PASA_pipeline.pl 



#############################################
## RECON 1.08 (http://eddylab.org/software/recon/)
#############################################
wget http://www.repeatmasker.org/RepeatModeler/RECON-1.08.tar.gz
tar -zxvf RECON-1.08.tar.gz
cd RECON-1.08/src/
make
make install
# Edit scripts/recon.pl - Add the path to the RECON bin directory on line 3.
./scripts/recon.pl




#############################################
## RepeatMasker
#############################################
## 
## http://www.repeatmasker.org/RMDownload.html
## 
## Requires:
## 	RMBlast
##	TRF
## 
wget http://www.repeatmasker.org/RepeatMasker-open-4-0-7.tar.gz
tar -zxvf RepeatMasker-open-4-0-7.tar.gz
mv RepeatMasker RepeatMasker-open-4-0-7
# Install RMBlast and Tandom Repeats Finder
# Update repeat libraires. Dfam v2.0 is included with RepeatMasker and likely doesnt need updating.
#	Dfam_consensus will need updating. Check the download website (http://www.dfam-consensus.org/#/public/download) for
# 	the newest version.
cd Libraries/
wget http://www.dfam-consensus.org/assets/download/Dfam_consensus-20171107.tar.gz
tar -zxvf Dfam_consensus-20171107.tar.gz
# 	The RepBase library is not included and will need to be downloaded (requires free registration). 
#	Download the RepBaseRepeatMaskerEdition-20170127.tar.gz file (Or what ever the new version is) into the RepeatMasker-open-4-0-7 directory
cd RepeatMasker-open-4-0-7/
tar -zxvf RepBaseRepeatMaskerEdition-20170127.tar.gz 
# This will unpack the library into the Libraries directory
./configure
# Follow the configure instructions. Provide the location of TRF and RMBlast (use as default search engine)
./RepeatMasker



#############################################
## RepeatModeler
#############################################
## 
## http://www.repeatmasker.org/RepeatModeler/
## 
## Requires:
##	nseg
##	RepeatMasker
##	RepeatScout
##	RMBlast
## 	TRF
## 
wget http://www.repeatmasker.org/RepeatModeler/RepeatModeler-open-1.0.11.tar.gz
tar -zxvf RepeatModeler-open-1.0.11.tar.gz
cd RepeatModeler-open-1.0.11/
./configure
# Follow the configure instructions. Provide the location of RepeatMasker, TRF, RepeatScout, RECON, nseg and RMBlast (use as default search engine)
# 
# NOTE: If you get a 'bad interpreter' error you need to change the top line of configure to be '#!/usr/bin/env perl' 
./RepeatModeler



#############################################
## RMBlast (http://www.repeatmasker.org/RMBlast.html)
#############################################
# 
# v2.2.28
wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/rmblast/2.2.28/ncbi-rmblastn-2.2.28-x64-linux.tar.gz
wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.2.28/ncbi-blast-2.2.28+-x64-linux.tar.gz

tar -zxvf ncbi-rmblastn-2.2.28-x64-linux.tar.gz
tar -zxvf ncbi-blast-2.2.28+-x64-linux.tar.gz
cp -r ncbi-rmblastn-2.2.28/* ncbi-blast-2.2.28+/
rm -rf ncbi-rmblastn-2.2.28
mv ncbi-blast-2.2.28+ rmblast-2.2.28
./rmblast-2.2.28/bin/rmblastn -help

# NOTE: v2.6 failes on Delta during 'make install' with "make[1]: *** [install-toolkit] Error 1"
# 	It is very likely that this error can be ignored however to be safe I used the original 2.2.28 version
# 
# Needs gcc v5.2.0 to work
wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.6.0/ncbi-blast-2.6.0+-src.tar.gz
wget http://www.repeatmasker.org/isb-2.6.0+-changes-vers2.patch.gz

tar -zxvf ncbi-blast-2.6.0+-src.tar.gz
gunzip isb-2.6.0+-changes-vers2.patch.gz

mv ncbi-blast-2.6.0+-src ncbi-rmblast-2.6.0+-src
cd ncbi-rmblast-2.6.0+-src
patch -p1 < ../isb-2.6.0+-changes-vers2.patch

cd c++/
module load gcc/5.2.0
module load boost/1.58.0
./configure --with-mt --prefix=$PWD/.. --without-debug
make
make install



#############################################
## RepeatScout 1.0.5
#############################################
wget http://www.repeatmasker.org/RepeatScout-1.0.5.tar.gz
tar -zxvf RepeatScout-1.0.5.tar.gz
mv RepeatScout-1 RepeatScout-1.0.5
cd RepeatScout-1.0.5/
make
./RepeatScout 



#############################################
## Salmon
#############################################
## 
## http://salmon.readthedocs.io/en/latest/index.html
## 
wget https://github.com/COMBINE-lab/salmon/releases/download/v0.9.1/Salmon-0.9.1_linux_x86_64.tar.gz
tar -zxvf Salmon-0.9.1_linux_x86_64.tar.gz
mv Salmon-latest_linux_x86_64 Salmon-0.9.1
./Salmon-0.9.1/bin/salmon 



#############################################
## SNAP
#############################################
## 
## http://korflab.ucdavis.edu/software.html
## https://github.com/KorfLab/SNAP
## 
git clone https://github.com/KorfLab/SNAP.git
mv SNAP/ SNAP_ret20Jul2018
cd SNAP_ret20Jul2018/
export ZOE=$PWD/Zoe
make



#############################################
## Tandom Repeats Finder (http://tandem.bu.edu/trf/trf.html)
#############################################
# http://tandem.bu.edu/trf/trf.html
# Download Linux 64 bit version (legacy GLIBC, <= 2.12).
mkdir Tandem_Repeats_Finder_4.09
cd Tandem_Repeats_Finder_4.09/
# Copy in downloaded file
mv trf409.legacylinux64 trf
chmod +x trf
./trf



#############################################
## TransposonPSI
#############################################
## 
## Modified code provided by Raul
## 



#############################################
## Trinity RNA-seq
#############################################
## 
## https://github.com/trinityrnaseq/trinityrnaseq/wiki
## 
## Requires:
## 	Bowtie2
## 	Jellyfish
## 	salmon
## 
## From: https://github.com/trinityrnaseq/trinityrnaseq/releases
## Download the leatest version of the software.
wget https://github.com/trinityrnaseq/trinityrnaseq/archive/Trinity-v2.6.6.tar.gz
tar -zxvf Trinity-v2.6.6.tar.gz
mv trinityrnaseq-Trinity-v2.6.6/ Trinity-v2.6.6/
cd Trinity-v2.6.6/
make
make plugins
./Trinity
# Run test dataset
export PATH=$PATH:$PWD/../../../Jellyfish-2.2.10/bin
export PATH=$PATH:$PWD/../../../bowtie2-2.3.4.1-linux-x86_64
export PATH=$PATH:$PWD/../../../Salmon-0.9.1/bin
cd sample_data/test_Trinity_Assembly/
./runMe.sh






















## UNIVEC
## 
## https://www.ncbi.nlm.nih.gov/tools/vecscreen/univec/
## 
mkdir -p UNIVEC/BUILD_10.0/
cd UNIVEC/BUILD_10.0/
wget ftp://ftp.ncbi.nlm.nih.gov/pub/UniVec/UniVec
wget ftp://ftp.ncbi.nlm.nih.gov/pub/UniVec/UniVec_Core
wget ftp://ftp.ncbi.nlm.nih.gov/pub/UniVec/README.uv
mkdir formatdb
cd formatdb/
/shares/common/groups/Group-Ragan/Dinoflagellate_Annotation_Workflow/programs/blast-2.2.26/bin/formatdb -i UniVec -p F
/shares/common/groups/Group-Ragan/Dinoflagellate_Annotation_Workflow/programs/blast-2.2.26/bin/formatdb -i UniVec_Core -p F





## 
## Transposon Database
## 
mkdir transposon_db_hhblits
cd transposon_db_hhblits/
wget -O transposons.hhblits.tar.bz2 'http://downloads.sourceforge.net/project/jamg/databases/transposons.hhblits.tar.bz2?r=&ts=1448327546&use_mirror=liquidtelecom'
tar -jxvf transposons.hhblits.tar.bz2












