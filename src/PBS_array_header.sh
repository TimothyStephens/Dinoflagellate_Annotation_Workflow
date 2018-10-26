#PBS -l nodes=1:ppn=__NCPUS__,mem=__MEM__,vmem=__VMEM__,walltime=__WALLTIME__
#PBS -k oe
#PBS -j oe
#PBS -J 1-__ARRAYSIZE__
#PBS -N __JOB_NAME__

set -o errexit
cd $PBS_O_WORKDIR

