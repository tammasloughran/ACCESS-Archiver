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
base_dir=/scratch/v45/hh0162/access-om2/archive #/scratch/p66/txz599/archive
loc_exp=1deg_jra55_iaf_omip2 #SSP-245-stg-30
#
zonal=false     # DAMIP-CM2-only
esm=false       # used in um2nc & cp_rest
plev8=false
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
  plev8=$6
  omip=$7
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
#PBS -l walltime=24:00:00,ncpus=24,mem=128Gb
#PBS -l wd
#PBS -l storage=scratch/p66+gdata/p66+gdata/hh5+gdata/access
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
export plev8=$plev8
export UMDIR=/projects/access/umdir

python -W ignore subroutines/run_um2nc.py

EOF

if ! $omip; then
  ls $here/tmp/$loc_exp/job_um2nc.qsub.sh
  chmod +x $here/tmp/$loc_exp/job_um2nc.qsub.sh
  #um2nc=$( qsub $here/tmp/$loc_exp/job_um2nc.qsub.sh )
  echo $um2nc
fi
#----------------------------#

#exit

#---- mppnccombine job --------------#
cat << EOF > $here/tmp/$loc_exp/job_mppnc.qsub.sh
#!/bin/bash
#PBS -P p66
#PBS -l walltime=48:00:00,ncpus=1,mem=12Gb
#PBS -l wd
#PBS -l storage=scratch/p66+gdata/p66+gdata/hh5+gdata/access
#PBS -q normal
#PBS -j oe
#PBS -N ${loc_exp}_mppnc
##PBS -W depend=on:1
module purge
module use /g/data/hh5/public/modules
module use ~access/modules
module load cdo
module load nco
module load conda/analysis3
export here=$here
export base_dir=$base_dir
export arch_dir=$arch_dir
export loc_exp=$loc_exp
export esm=$esm

./subroutines/mppnccomb_check.sh

EOF

ls $here/tmp/$loc_exp/job_mppnc.qsub.sh
chmod +x $here/tmp/$loc_exp/job_mppnc.qsub.sh
#----------------------------#

#---- copy job --------------#
cat << EOF > $here/tmp/$loc_exp/job_arch.qsub.sh
#!/bin/bash
#PBS -P p66
#PBS -l walltime=10:00:00,ncpus=1,mem=8Gb
#PBS -l wd
#PBS -l storage=scratch/p66+gdata/p66+gdata/hh5+gdata/access
#PBS -q copyq
#PBS -j oe
#PBS -N ${loc_exp}_arch
##PBS -W depend=beforeany:$mppn
module purge
module use /g/data/hh5/public/modules
module use ~access/modules
module load cdo
module load nco
module load conda/analysis3
export here=$here
export base_dir=$base_dir
export arch_dir=$arch_dir
export loc_exp=$loc_exp
export esm=$esm

./subroutines/cp_hist.sh
./subroutines/cp_rest.sh

qsub $here/tmp/$loc_exp/job_mppnc.qsub.sh

EOF

ls $here/tmp/$loc_exp/job_arch.qsub.sh
chmod +x $here/tmp/$loc_exp/job_arch.qsub.sh
arch=$( qsub $here/tmp/$loc_exp/job_arch.qsub.sh )
echo $arch
#----------------------------#

echo -e "\n---- DONE: $loc_exp ----"
