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

# NCI project to charge compute and use in storage flags
proj=p66

# above raw output directory
base_dir=/scratch/p66/txz599/archive/
#base_dir=/scratch/p66/mrd599/archive/
#base_dir=/scratch/p66/cm2704/ACCESS-CM2-Chem/fd0474/

# where to archive
arch_dir=/g/data/p73/archive/non-CMIP/ACCESS-ESM1-5/
#arch_dir=/scratch/p66/cm2704/archive/

# [cm2, cm2amip, cm2chem, esmscript, esmpayu, om2]
access_version=esmscript

loc_exp=(
HI-CN-05
HI-C-05
HI-noluc-CN-05
HI-noluc-C-05
)

for exp in ${loc_exp[@]}; do
  ./ACCESS_Archiver.sh $arch_dir $base_dir $access_version $exp $proj
  #./Archive_checker.sh $arch_dir $base_dir $access_version $exp $proj
  #break
done

exit

