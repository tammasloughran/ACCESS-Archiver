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
arch_dir=/scratch/p66/cm2704/archive

# above raw output directory
#base_dir=/g/data/ik11/outputs/access-om2/
base_dir=/g/data/ob22/jxb548/ACCESS-ESM/archive/
#base_dir=/scratch/p66/cm2704/cylc-run
#base_dir=/scratch/p66/txz599/archive

# [cm2, cm2amip, esmscript, esmpayu, om2]
access_version=esmpayu

loc_exp=(
#1deg_jra55_iaf_omip2_cycle1
esm-mh
)


for exp in ${loc_exp[@]}; do
  ./ACCESS_Archiver.sh $arch_dir $base_dir $access_version $exp
  #./Archive_checker.sh $arch_dir $base_dir $access_version $exp
done

exit
