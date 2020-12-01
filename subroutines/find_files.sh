#!/bin/bash

if [ ! -z $1 ]; then
  base_dir=$1
  loc_exp=$2
  here=$3
else
  echo "information not provided to subroutines/find_files.sh"
  exit
fi

echo -e "\n---- Finding Files ----"
echo -e "finding model output files in $base_dir for $loc_exp"

if [[ -d $base_dir/$loc_exp/history ]]; then
  echo "assuming standard dir structure"
  dir_struc=0
elif [[ -d $base_dir/u-$loc_exp/share/data/History_Data ]]; then
  echo "assuming cylc-run dir structure; atm-only"
  dir_struc=1
else
  echo "could not identify dir structure, exiting"
  exit
fi

year=""

echo "searching for history"
if [ $dir_struc == 0 ]; then
  find $base_dir/$loc_exp/history/atm -name "${loc_exp}*.p[m,a,d,e,7,i,8,j]*$year" -printf "%p\n" | sort \
      > $here/tmp/$loc_exp/hist_atm_files.csv
  find $base_dir/$loc_exp/history/ocn -name "*.nc*$year" -printf "%p\n" | sort \
      > $here/tmp/$loc_exp/hist_ocn_files.csv
  find $base_dir/$loc_exp/history/ice -name "ice*$year.nc*" -printf "%p\n" | sort \
      > $here/tmp/$loc_exp/hist_ice_files.csv
elif [ $dir_struc == 1 ]; then
  find $base_dir/$loc_exp/share/data/History_Data -name "${loc_exp}*.p[m,a,d,e,7,i,8,j]*$year" -printf "%p\n" | sort \
      > $here/tmp/$loc_exp/hist_atm_files.csv
  # ocean?
  # ice?
fi

echo "searching for restarts"
if [ $dir_struc == 0 ]; then
  find $base_dir/$loc_exp/restart/atm -type f -name "*$year" -printf "%p\n" | sort \
      > $here/tmp/$loc_exp/rest_atm_files.csv
  find $base_dir/$loc_exp/restart/ocn -type f -name "*$year" -printf "%p\n" | sort \
      > $here/tmp/$loc_exp/rest_ocn_files.csv
  find $base_dir/$loc_exp/restart/ice -type f -name "*$year" -printf "%p\n" | sort \
      > $here/tmp/$loc_exp/rest_ice_files.csv
  find $base_dir/$loc_exp/restart/cpl -type f -name "*$year" -printf "%p\n" | sort \
      > $here/tmp/$loc_exp/rest_cpl_files.csv
elif [ $dir_struc == 1 ]; then
  find $base_dir/$loc_exp/share/data/History_Data -type f -name "*$year" -printf "%p\n" | sort \
      > $here/tmp/$loc_exp/rest_atm_files.csv
  # ocean?
  # ice?
fi

echo -e "finished finding files; lists here: $here/tmp/$loc_exp"
