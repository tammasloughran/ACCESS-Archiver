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
base_dir=/scratch/p66/mrd599/archive
#
zonal=true
esm=false
omip=false
#
loc_exp=(
bu010
bu839
bu840
bw966
bx128
bx129
by350
by438
by563
)

for exp in ${loc_exp[@]}; do
  ./ACCESS_Archiver.sh $arch_dir $base_dir $exp $zonal $esm $omip
done
