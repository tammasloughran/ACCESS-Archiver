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
arch_dir=/g/data/p66/cm2704/archive

# above raw output directory
#base_dir=/g/data/ik11/outputs/access-om2/
#base_dir=/g/data/ik11/outputs/access-om2-025/
base_dir=/scratch/p66/txz599/archive

# [cm2, cm2amip, esmscript, esmpayu, om2]
access_version=esmscript

loc_exp=(
#1deg_jra55_iaf_omip2_cycle1
#025deg_jra55_iaf_omip2_cycle1
SSP-370-15
SSP-370-16
SSP-370-17
SSP-370-18
SSP-370-19
SSP-370-20
SSP-370-21
SSP-370-22
SSP-370-23
SSP-370-24
)


for exp in ${loc_exp[@]}; do
  #./ACCESS_Archiver.sh $arch_dir $base_dir $access_version $exp
  ./Archive_checker.sh $arch_dir $base_dir $access_version $exp
  #break
done

exit
