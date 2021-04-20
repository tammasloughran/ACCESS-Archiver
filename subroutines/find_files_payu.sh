#!/bin/bash

if [ ! -z $1 ]; then
  base_dir=$1
  loc_exp=$2
  here=$3
else
  echo "information not provided to subroutines/find_files_payu.sh"
  exit
fi

echo -e "\n---- Finding Files ----"
echo -e "finding model output files in $base_dir for $loc_exp"
echo -e "payu-style"

indir=$base_dir/$loc_exp

echo "output_num cycle_num year_start year_end" > $here/tmp/$loc_exp/payu_info.csv

echo "searching for history"
for payudir in $( ls -d ${indir}/output00? ); do
  echo $payudir
  if [[ ! -f ${payudir}/ocean/time_stamp.out ]]; then
    continue
  fi
  yarr=()
  while IFS=' ' read -ra year; do
    yarr+=( "$( printf '%04d' $year )" )
  done < "${payudir}/ocean/time_stamp.out"
  #echo ${yarr[@]}
  payudirbase=`basename $payudir`
  payudirbaseval=$((10#${payudirbase//output/}))
  payudirbasevalf=$( printf "%04d" ${payudirbaseval##+(0)} )
  echo "$payudirbase $payudirbasevalf ${yarr[0]} ${yarr[1]}" >> $here/tmp/$loc_exp/payu_info.csv
  for atmfile in $( ls ${payudir}/atmosphere/aiihca.p* ); do
    ls $atmfile >> $here/tmp/$loc_exp/hist_atm_files.csv
  done
  for ocnfile in $( ls ${payudir}/ocean/ocean_*.nc ); do
    ls $ocnfile >> $here/tmp/$loc_exp/hist_ocn_files.csv
  done
  for icefile in $( ls ${payudir}/ice/ice*.nc ); do
    ls $icefile >> $here/tmp/$loc_exp/hist_ice_files.csv
  done
done

echo "searching for restarts - (restart000-style)"
for restdir in $( ls -d ${indir}/restart00? ); do
  #echo $restdir
  restdirbase=`basename $restdir`
  restdirbaseval=$((10#${restdirbase//restart/}))
  if ! (( ${restdirbaseval} % 5 )) ; then
    echo $restdir >> $here/tmp/$loc_exp/rest_dirs.csv
  fi
done

echo -e "finished finding payu files; lists here: $here/tmp/$loc_exp"  

