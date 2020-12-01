#!/bin/bash
#####################
#
# This is the ACCESS Archiver, v0.1
# 13/10/2020
# 
# Developed by Chloe Mackallah, CSIRO Aspendale
#
#####
module purge
module load pbs
#####################
# USER SETTINGS
#
arch_dir=/g/data/p66/cm2704/archive
base_dir=/scratch/e14/rmh561/access-om2/archive #/scratch/p66/txz599/archive
loc_exp=025deg_jra55_iaf_cycle1
#
zonal=false
esm=true
omip=true
#
#####################
# IF RUN FROM WRAPPER
if [ ! -z $1 ]; then
  arch_dir=$1
  base_dir=$2
  loc_exp=$3
  zonal=$4
  esm=$5
  omip=$6
fi
#####################
# FIXED SETTINGS
here=$( pwd )
mkdir -p $here/tmp/$loc_exp
rm -f $here/tmp/$loc_exp/*
# make arch_dir
mkdir -p $arch_dir/$loc_exp
####
echo -e "\n==== ACCESS_Archiver ===="
echo "base dir: $base_dir"
echo "arch dir: $arch_dir"
echo "local exp: $loc_exp"
#####################
# RUN SUBROUTINES

if $omip; then
  ./subroutines/find_files_omip.sh $base_dir $loc_exp $here
else
  ./subroutines/find_files.sh $base_dir $loc_exp $here
fi
#exit

echo -e "\n---- Setting up jobs ----"

#---- um2nc parallel job ----#
cat << EOF > $here/tmp/$loc_exp/job_um2nc.qsub.sh
#!/bin/bash
#PBS -P p66
#PBS -l walltime=10:00:00,ncpus=24,mem=128Gb
#PBS -l wd
#PBS -l storage=scratch/p66+gdata/p66+gdata/hh5+scratch/access
#PBS -q normal
#PBS -j oe
#PBS -N ${loc_exp}_um2nc
module purge
module use /g/data/hh5/public/modules
module use ~access/modules
module load cdo
module load nco
module load pythonlib/umfile_utils/access_cm2
export ncpus=\$PBS_NCPUS
export here=$here
export base_dir=$base_dir
export arch_dir=$arch_dir
export loc_exp=$loc_exp
export zonal=$zonal
export esm=$esm
export UMDIR=/projects/access/umdir

python -W ignore subroutines/run_um2nc.py

EOF

ls $here/tmp/$loc_exp/job_um2nc.qsub.sh
chmod +x $here/tmp/$loc_exp/job_um2nc.qsub.sh
if ! $omip; then
  qsub $here/tmp/$loc_exp/job_um2nc.qsub.sh
fi
#----------------------------#

#exit

#---- copy job --------------#
cat << EOF > $here/tmp/$loc_exp/job_arch.qsub.sh
#!/bin/bash
#PBS -P p66
#PBS -l walltime=10:00:00,ncpus=1,mem=16Gb
#PBS -l wd
#PBS -l storage=scratch/p66+gdata/p66+gdata/hh5+scratch/access+gdata/access+scratch/e14
#PBS -q copyq
#PBS -j oe
#PBS -N ${loc_exp}_arch
module purge
module use /g/data/hh5/public/modules
module use ~access/modules
module load cdo
module load nco
module load pythonlib/umfile_utils/access_cm2
export here=$here
export base_dir=$base_dir
export arch_dir=$arch_dir
export loc_exp=$loc_exp
export esm=$esm

./subroutines/cp_hist.sh
./subroutines/mppnccomb_check.sh
./subroutines/cp_rest.sh

EOF

ls $here/tmp/$loc_exp/job_arch.qsub.sh
chmod +x $here/tmp/$loc_exp/job_arch.qsub.sh
qsub $here/tmp/$loc_exp/job_arch.qsub.sh
#----------------------------#

echo -e "\n---- DONE: $loc_exp ----"
