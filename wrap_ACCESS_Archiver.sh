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
base_dir=/scratch/e14/afp599/access-esm/archive/

# where to archive
#arch_dir=/g/data/p66/cm2704/archive/
#arch_dir=/scratch/p66/cm2704/archive/
arch_dir=/g/data/e14/cm2704/archive/


# [cm2, cm2amip, esmscript, esmpayu, om2]
access_version=esmpayu

loc_exp=(
esm-ssp585-ctrl-test1
)

for exp in ${loc_exp[@]}; do
  ./ACCESS_Archiver.sh $arch_dir $base_dir $access_version $exp $proj
  #./Archive_checker.sh $arch_dir $base_dir $access_version $exp $proj
  #break
done

exit
