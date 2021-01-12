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
#
arch_dir=/g/data/p66/cm2704/archive
base_dir=/scratch/p66/txz599/archive
#
zonal=false #DAMIP-CM2-only
esm=true
plev8=false
omip=false
#
loc_exp=(
#SSP-126-ext-06
#cpocnice
SSP-126-ext-05
#SSP-126-ext-07
#SSP-126-ext-08
#SSP-126-ext-09
#SSP-126-ext-10
#SSP-126-ext-11
#SSP-126-ext-12
#SSP-126-ext-13
#SSP-126-ext-14
#PI-ZEC-154-02
#PI-ZEC-168-02
#PI-ZEC-181-02
#PI-ZEC-194-02
#PI-ZEC-205-02
#PI-ZEC-216-02
)

for exp in ${loc_exp[@]}; do
  ./ACCESS_Archiver.sh $arch_dir $base_dir $exp $zonal $esm $plev8 $omip
done

exit
#cpocnice
SSP-126-ext-05
SSP-126-ext-07
SSP-126-ext-08
SSP-126-ext-09
SSP-126-ext-10
SSP-126-ext-11
SSP-126-ext-12
SSP-126-ext-13
SSP-126-ext-14
PI-ZEC-154-02
PI-ZEC-168-02
PI-ZEC-181-02
PI-ZEC-194-02
PI-ZEC-205-02
PI-ZEC-216-02
