
export PATH=$PATH:${MAKER}
export MPI_BLASTDB=__MPI_DB__/mpi_blastdb
source ../../../env.sh

cd $PBS_O_WORKDIR
cp -Hr * $TMPDIR
cd $TMPDIR

mkdir ${TMPDIR}/tmp

maker --fix_nucleotides --mpi_blastdb $MPI_BLASTDB -TMP ${TMPDIR}/tmp -genome __SEQS2RUN__

cp -Hr * $PBS_O_WORKDIR

