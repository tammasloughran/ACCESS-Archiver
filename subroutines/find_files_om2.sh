#!/bin/bash

if [ ! -z $1 ]; then
  base_dir=$1
  loc_exp=$2
  here=$3
else
  echo "information not provided to subroutines/find_files_om2.sh"
  exit
fi

echo -e "\n---- Finding Files ----"
echo -e "finding model output files in $base_dir for $loc_exp"
echo -e "OM2-style"

indir=$base_dir/$loc_exp

echo "output_num cycle_num year_start year_end" > $here/tmp/$loc_exp/om2_info.csv

echo "searching for history"
for om2dir in $( ls -d ${indir}/output* ); do
  #echo $om2dir
  yarr=()
  while IFS=' ' read -ra year; do
    yarr+=( "$( printf '%04d' $year )" )
  done < "${om2dir}/ocean/time_stamp.out"
  #echo ${yarr[@]}
  om2dirbase=`basename $om2dir`
  om2dirbaseval=$((10#${om2dirbase//output/} + 1))
  om2dirbasevalf=$( printf "%04d" ${om2dirbaseval##+(0)} )
  echo "$om2dirbase $om2dirbasevalf ${yarr[0]} ${yarr[1]}" >> $here/tmp/$loc_exp/om2_info.csv
  for ocnfile in $( ls ${om2dir}/ocean/ocean_*.nc ); do
    ls $ocnfile >> $here/tmp/$loc_exp/hist_ocn_files.csv
  done
  for icefile in $( ls ${om2dir}/ice/OUTPUT/ice*.nc ); do
    ls $icefile >> $here/tmp/$loc_exp/hist_ice_files.csv
  done
done

exit

#RESTARTS NO LONGER SAVED FOR OM2
echo "searching for restarts"
for restdir in $( ls -d ${indir}/restart* ); do
  #echo $restdir
  restdirbase=`basename $restdir`
  restdirbaseval=$((10#${restdirbase//restart/}))
  #restdirbasevalf=$( printf "%04d" ${om2dirbaseval} )
  echo $restdir >> $here/tmp/$loc_exp/rest_ocn_files.csv
  if ! (( ${restdirbaseval} % 5 )) ; then
      echo $restdir >> $here/tmp/$loc_exp/rest_ocn_files.csv
  fi
done

echo -e "finished finding OM2 files; lists here: $here/tmp/$loc_exp"  

