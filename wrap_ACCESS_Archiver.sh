#!/bin/bash
set -a
#########################
#
# This is the wrapper for the ACCESS Archiver
# 09/11/2020
# 
# Developed by Chloe Mackallah, CSIRO Aspendale
#
#########################
# USER SETTINGS

#comp_proj = NCI project to charge compute
comp_proj=p66

#base_dir = location above raw output directory
base_dir=/scratch/p66/txz599/archive/

#arch_dir = location to archive
arch_dir=/g/data/p73/archive/non-CMIP/ #ACCESS-ESM1-5/

#access_version = [cm2, cm2amip, cm2chem, esmscript, esmpayu, om2]
access_version=esmscript

#ncexists = [true, false] 
#true: Copy netcdf version of file if it exists; false: Always use UM pp-file if it exists, whether or not netcdf version exists
ncexists=false

#subdaily = [true, false]; convert subdaily atm files?
subdaily=false

#loc_exps = list of local experiment names (stored in 'base_dir') to archive
loc_exps=( HI-08-t2 )

#task = [archive, check]
#archive: run ACCESS_Archiver.sh; check: run Archive_checker.sh
task=archive


#
#########################
# DO NOT EDIT - FIXED TASKS

#run Archiver or checker
for loc_exp in ${loc_exps[@]}; do
  if [[ $task == archive ]]; then 
    ./ACCESS_Archiver.sh
  elif [[ $task == check ]]; then
    ./Archive_checker.sh
  else
    echo "could not identify 'task'"; exit
  fi
done

#########################

exit
