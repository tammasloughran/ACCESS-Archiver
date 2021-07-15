#!/bin/bash

echo -e "\n---- Copy history ----"
echo $loc_exp
echo $access_version

if [ ! -f $here/tmp/$loc_exp/payu_info.csv ]; then
  echo "$here/tmp/$loc_exp/payu_info.csv not found!"
  exit
fi
#
if [[ $arch_dir == $base_dir ]]; then
  echo "cannot use payu version of ACCESS_Archiver on itself"
  exit
fi

determ_payu_val () {
  while IFS=' ' read outnums cyclenums ystarts yends; do
    if [[ $1 == */$outnums/* ]]; then
      cyclenum=$cyclenums
      ystart=$ystarts
      yend=$yends
      break
    fi
  done < $here/tmp/$loc_exp/payu_info.csv
}

# ocn
echo -e "\ncopying $( cat $here/tmp/$loc_exp/hist_ocn_files.csv | wc -l ) ocean files"
curdir=$arch_dir/$loc_exp/history/ocn
mkdir -p $curdir
rm -f $curdir/*_tmp* 2>/dev/null
while IFS=, read -r file; do
  fdir=`dirname $file`
  fname=`basename $file`
  unset cyclenum
  unset ystart
  unset yend
  determ_payu_val $fdir
  if [[ $fname != *$ystart* ]]; then
    fname=${fname}-${ystart}1231
  fi
  if [ ! -f $curdir/${fname} ]; then
    if [[ $file != *.nc.[0-9][0-9][0-9][0-9]* ]]; then
      echo "-- $file -> $fname"
      # check nc version
      unset nctype
      nctype=$( ncdump -k $file )
      if [[ $nctype == "classic" ]]; then
        echo "  converting nc version"
        nccopy -k "netCDF-4 classic model" -d 1 -s $file $curdir/${fname}_tmp
      else
        rsync -av $file $curdir/${fname}_tmp
      fi
      mv $curdir/${fname}_tmp $curdir/$fname
      chmod 644 $curdir/$fname
      chgrp p66 $curdir/$fname
    else
      if [[ $file == *.nc.0000* ]]; then
        echo "creating symlinks"
        for mpn in $( ls ${file//0000/????}); do
          echo "  -- $mpn"
          mpnbase=`basename $mpn`
          ln -s ${mpn} $curdir/${mpnbase}-${ystart}1231
        done
        echo "completed symlinks for ${file//0000/????}"
      fi
    fi
  else
    if [[ $file != *.nc.[0-9][0-9][0-9][0-9]* ]]; then
      echo "-- $file copied already"
    fi
  fi
done < $here/tmp/$loc_exp/hist_ocn_files.csv
rm -f $curdir/*_tmp

# ice
echo -e "\ncopying $( cat $here/tmp/$loc_exp/hist_ice_files.csv | wc -l ) ice files"
curdir=$arch_dir/$loc_exp/history/ice
mkdir -p $curdir
rm -f $curdir/*_tmp* 2>/dev/null
while IFS=, read -r file; do
  fdir=`dirname $file`
  fname=`basename $file`
  unset cyclenum
  unset ystart
  unset yend
  determ_payu_val $fdir
  if [[ $fname != *$ystart* ]]; then
    if [[ $fname == ice*.????-??.nc ]]; then
      IFS=.-
      read -ra fnamearr <<< "$fname"
      unset IFS
      fname=${fnamearr[0]}.${ystart}-${fnamearr[2]}.nc
    else
      echo "could not determine file name: $fname"
      continue
    fi
  fi
  if [ ! -f $curdir/${fname} ]; then
    echo "-- $file"
    # check nc version
    unset nctype
    nctype=$( ncdump -k $file )
    if [[ $nctype = "classic" ]]; then
      echo "  converting nc version"
      nccopy -k "netCDF-4 classic model" -d 1 -s $file $curdir/${fname}_tmp
    else
      rsync -av $file $curdir/${fname}_tmp
    fi
    # check for non-standard field names (ESM1.5)
    echo "checking for non-standard field names"
    for var in $( ncks --jsn -q $curdir/${fname}_tmp | jq '.variables | keys | .[]' ); do
      var=${var//\"/}
      if [[ $var == *_m ]]; then
        ncrename -Oh -v $var,${var//_m/} $curdir/${fname}_tmp
      fi
    done
    mv $curdir/${fname}_tmp $curdir/$fname
    chmod 644 $curdir/$fname
    chgrp p66 $curdir/$fname
  else
    echo "-- $file copied already"
  fi
done < $here/tmp/$loc_exp/hist_ice_files.csv
rm -f $curdir/*_tmp
