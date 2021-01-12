#!/bin/bash

if [ ! -z $1 ]; then
  base_dir=$1
  loc_exp=$2
  here=$3
else
  echo "information not provided to subroutines/find_files_omip.sh"
  exit
fi

echo -e "\n---- Finding Files ----"
echo -e "finding model output files in $base_dir for $loc_exp"
echo -e "OMIP-style (NOT payu, output value used here)"

indir=$base_dir/$loc_exp

outstart=2013
outend=2378

echo "searching for history"
for omipdir in $( ls -d ${indir}/output* ); do
  #echo $omipdir
  #yarr=()
  #while IFS=' ' read -ra year; do
  #  yarr+=( "$( printf '%04d' $year )" )
  #done < "${omipdir}/ocean/time_stamp.out"
  #echo ${yarr[@]}
  omipdirbase=`basename $omipdir`
  omipdirbaseval=$( expr ${omipdirbase//output/} + 0 )
  omipdirbaseval=$( printf "%04d" ${omipdirbaseval} )
  if [ "$omipdirbaseval" -ge "$outstart" ] && [ "$omipdirbaseval" -le "$outend" ]; then
    echo "$omipdirbase $omipdirbaseval" >> $here/tmp/$loc_exp/omip_info.csv
    for ocnfile in $( ls ${omipdir}/ocean/ocean_*.nc ); do
      ls $ocnfile >> $here/tmp/$loc_exp/hist_ocn_files.csv
    done
    for icefile in $( ls ${omipdir}/ice/OUTPUT/ice*.nc ); do
      ls $icefile >> $here/tmp/$loc_exp/hist_ice_files.csv
    done
  fi
done

#exit
echo "searching for restarts"
for restdir in $( ls -d ${indir}/restart* ); do
  #echo $restdir
  restdirbase=`basename $restdir`
  restdirbaseval=$( expr ${restdirbase//restart/} + 0 )
  restdirbaseval=$( printf "%04d" ${restdirbaseval} )
  if [ "$restdirbaseval" -ge "$outstart" ] && [ "$restdirbaseval" -le "$outend" ]; then
    for ocnrest in $( ls ${restdir}/ocean/* ); do
      if [[ `basename $ocnrest` == ocean_*.nc ]]; then
        ls $ocnrest >> $here/tmp/$loc_exp/rest_ocn_files.csv
      elif [[ `basename $ocnrest` == ?2?.nc ]]; then
        ls $ocnrest >> $here/tmp/$loc_exp/rest_cpl_files.csv
      fi
    done
    for icerest in $( ls ${restdir}/ice/* ); do
      if [[ `basename $icerest` == ice* ]]; then
        ls $icerest >> $here/tmp/$loc_exp/rest_ice_files.csv
      elif [[ `basename $icerest` == ?2?.nc ]]; then
        ls $icerest >> $here/tmp/$loc_exp/rest_cpl_files.csv
      fi
    done
  fi
done

echo -e "finished finding OMIP files; lists here: $here/tmp/$loc_exp"
