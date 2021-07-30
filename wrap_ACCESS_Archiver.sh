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
#base_dir=/scratch/p66/txz599/archive/
#base_dir=/scratch/p66/cm2704/archive/
#base_dir=/scratch/p66/cm2704/ACCESS-CM2-Chem/fd0474/
base_dir=/g/data/ob22/jxb548/ACCESS-ESM/archive/

# where to archive
#arch_dir=/g/data/p66/cm2704/archive/
arch_dir=/scratch/p66/cm2704/archive/

# [cm2, cm2amip, esmscript, esmpayu, om2]
access_version=esmpayu

loc_exp=(
esm-mh
)

for exp in ${loc_exp[@]}; do
  #./ACCESS_Archiver.sh $arch_dir $base_dir $access_version $exp $proj
  ./Archive_checker.sh $arch_dir $base_dir $access_version $exp $proj
  #break
done

exit
PI-C-04
PI-CN-04
PI-C-rev-01
PI-CN-rev-01
