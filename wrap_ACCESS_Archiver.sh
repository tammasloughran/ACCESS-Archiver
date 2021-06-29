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
SSP-126-35
SSP-126-36
SSP-126-37
SSP-126-38
SSP-126-39
SSP-126-40
SSP-126-41
SSP-126-42
SSP-126-43
SSP-126-44
SSP-245-35
SSP-245-36
SSP-245-37
SSP-245-38
SSP-245-39
SSP-245-40
SSP-245-41
SSP-245-42
SSP-245-43
SSP-245-44
)

for exp in ${loc_exp[@]}; do
  ./ACCESS_Archiver.sh $arch_dir $base_dir $access_version $exp
  #./Archive_checker.sh $arch_dir $base_dir $access_version $exp
  #break
done

exit
