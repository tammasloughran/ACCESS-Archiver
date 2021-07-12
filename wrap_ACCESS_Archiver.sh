#!/bin/bash
#####################
#
# This is the multi-experiment wrapper for the ACCESS Archiver
# 09/11/2020
# 
# Developed by Chloe Mackallah, CSIRO Aspendale
#
#####################
# USER SETTINGS

# where to archive
arch_dir=/g/data/p66/cm2704/archive/
#arch_dir=/scratch/p66/cm2704/archive/

# above raw output directory
base_dir=/scratch/p66/txz599/archive/
#base_dir=/scratch/p66/cm2704/archive/
#base_dir=/scratch/p66/cm2704/ACCESS-CM2-Chem/fd0474/


# [cm2, cm2amip, esmscript, esmpayu, om2]
access_version=esmscript

loc_exp=(
SSP-585-15
SSP-585-16
SSP-585-17
SSP-585-18
SSP-585-19
SSP-585-20
SSP-585-21
SSP-585-22
SSP-585-23
SSP-585-24
)

for exp in ${loc_exp[@]}; do
  ./ACCESS_Archiver.sh $arch_dir $base_dir $access_version $exp
  #./Archive_checker.sh $arch_dir $base_dir $access_version $exp
  #break
done

exit
