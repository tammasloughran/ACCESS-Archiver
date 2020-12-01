#!/bin/bash

echo -e "\n---- Copy history ----"

if [ -f $here/tmp/$loc_exp/omip_info.csv ]; then
  omip=true
else
  omip=false
fi
determ_omip_yr () {
  while IFS=' ' read cycle start end; do
    if [[ $1 == */$cycle/* ]]; then
      syear=$start
      eyear=$end
      break
    fi
  done < $here/tmp/$loc_exp/omip_info.csv
}


# atm
echo -e "\nlinking $( cat $here/tmp/$loc_exp/hist_atm_files.csv | wc -l ) atm files"
curdir=$arch_dir/$loc_exp/history/atm
mkdir -p $curdir
while IFS=, read -r file; do
  fdir=`dirname $file`
  fname=`basename $file`
  if [ ! -f $curdir/${fname} ]; then
    echo "-- $file"
    ln -s $file $curdir/$fname
  fi
done < $here/tmp/$loc_exp/hist_atm_files.csv

# ocn
echo -e "\ncopying $( cat $here/tmp/$loc_exp/hist_ocn_files.csv | wc -l ) ocean files"
curdir=$arch_dir/$loc_exp/history/ocn
mkdir -p $curdir
while IFS=, read -r file; do
  fdir=`dirname $file`
  fname=`basename $file`
  if $omip; then
    determ_omip_yr $fdir
    if [[ $fname != *$syear* ]]; then
      if [[ $eyear == "$( expr $syear + 1 )" ]]; then
        fname=${fname}-${syear}
      else
        fname=${fname}-${syear}_${eyear}
      fi
    fi
    unset syear eyear
  fi
  if [ ! -f $curdir/${fname} ]; then
    echo "-- $file"
    rsync -av $file $curdir/${fname}_tmp
    # check nc version
    unset nctype
    nctype=$( ncdump -k $curdir/${fname}_tmp )
    if [[ $nctype = "classic" ]]; then
      echo "  converting nc version"
      nccopy -k "netCDF-4 classic model" -d 1 -s $curdir/${fname}_tmp $curdir/${fname}_tmp1
      mv $curdir/${fname}_tmp1 $curdir/${fname}_tmp
    fi
    mv $curdir/${fname}_tmp $curdir/$fname
    chmod 644 $curdir/$fname
  fi
done < $here/tmp/$loc_exp/hist_ocn_files.csv
rm -f $curdir/*_tmp
rm -f $curdir/*_tmp1

# ice
echo -e "\ncopying $( cat $here/tmp/$loc_exp/hist_ice_files.csv | wc -l ) ice files"
curdir=$arch_dir/$loc_exp/history/ice
mkdir -p $curdir
while IFS=, read -r file; do
  fdir=`dirname $file`
  fname=`basename $file`
  if $omip; then
    determ_omip_yr $fdir
    if [[ $fname != *$syear* ]]; then
      if [[ $eyear == "$( expr $syear + 1 )" ]]; then
        fname=${fname}-${syear}
      else
        fname=${fname}-${syear}_${eyear}
      fi
    fi
    unset syear eyear
  fi
  if [ ! -f $curdir/${fname} ]; then
    echo "-- $file"
    rsync -av $file $curdir/${fname}_tmp
    # check nc version
    unset nctype
    nctype=$( ncdump -k $curdir/${fname}_tmp )
    if [[ $nctype = "classic" ]]; then
      echo "  converting nc version"
      nccopy -k "netCDF-4 classic model" -d 1 -s $curdir/${fname}_tmp $curdir/${fname}_tmp1
      mv $curdir/${fname}_tmp1 $curdir/${fname}_tmp
    fi
    # check for non-standard field names (ESM1.5)
    echo "checking for non-standard field names"
    for var in $( ncks --jsn -q $curdir/${fname}_tmp | jq '.variables | keys | .[]' ); do
      var=${var//\"/}
      if [[ $var == *_m ]]; then
        ncrename -Oh -v $var,${var//_m/} $curdir/${fname}_tmp #$curdir/${fname}_tmp1
        #mv $curdir/${fname}_tmp1 $curdir/${fname}_tmp
      fi
    done
    mv $curdir/${fname}_tmp $curdir/$fname
    chmod 644 $curdir/$fname
  fi
done < $here/tmp/$loc_exp/hist_ice_files.csv
rm -f $curdir/*_tmp
rm -f $curdir/*_tmp1
