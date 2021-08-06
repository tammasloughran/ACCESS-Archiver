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
#base_dir=/scratch/p66/cm2704/archive/
#base_dir=/scratch/p66/cm2704/ACCESS-CM2-Chem/fd0474/

# where to archive
#arch_dir=/g/data/p66/cm2704/archive/
arch_dir=/scratch/p66/cm2704/archive/

# [cm2, cm2amip, esmscript, esmpayu, om2]
access_version=esmscript

loc_exp=(
)

for exp in ${loc_exp[@]}; do
  ./ACCESS_Archiver.sh $arch_dir $base_dir $access_version $exp $proj
  #./Archive_checker.sh $arch_dir $base_dir $access_version $exp $proj
  #break
done

exit

SSP-126-ext-t1
SSP-245-rt1-05
SSP-245-rt1-06
SSP-245-rt1-07
SSP-245-rt1-08
SSP-245-rt1-09
SSP-245-rt1-10
SSP-245-rt1-11
SSP-245-rt1-12
SSP-245-rt1-13
SSP-245-rt1-14
SSP-245-t10
SSP-245-t11
SSP-245-t12
SSP-245-t13
SSP-245-t14
SSP-245-t15
SSP-245-t16
SSP-245-t17
SSP-245-t8
SSP-245-t9
SSP-126-t8
SSP-370-t8
SSP-585-t8
HI-bio-01
HI-bio-02
HI-bio-03
HI-bio-04
HI-bio-05
