#!/bin/bash

echo -e "\n==== ACCESS_Archiver -- copy_job ===="
echo "base dir: $base_dir"
echo "arch dir: $arch_dir"
echo "local exp: $loc_exp"
echo "access version: $access_version"

# ocn
echo -e "\ncopying $( cat $here/tmp/$loc_exp/hist_ocn_files.csv | wc -l ) ocean files"
curdir=$arch_dir/$loc_exp/history/ocn
mkdir -p $curdir; chgrp $arch_grp $curdir
rm -f $curdir/*_tmp* 2>/dev/null
while IFS=, read -r file; do
  fdir=`dirname $file`
  fname=`basename $file`
  if [[ $arch_dir == $base_dir ]]; then
    #check nc version
    unset nctype
    nctype=$( ncdump -k $file )
    if [[ $nctype == "classic" ]]; then
      echo "-- $file"
      echo "  converting nc version"
      nccopy -k "netCDF-4 classic model" -d 1 -s $file ${file}_tmp
      mv ${file}_tmp ${file}
      chmod 644 $file
      chgrp $arch_grp $file
    fi
  elif [ ! -f $curdir/${fname} ]; then
    echo "-- $file"
    if [[ $file != *.nc.[0-9][0-9][0-9][0-9]* ]]; then
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
      chgrp $arch_grp $curdir/$fname
    else
      if [[ $file == *.nc.0000* ]]; then
        echo "creating symlinks"
        ln -s ${file//0000/????} $curdir
      fi
    fi
  else
    echo "-- $file copied already"
  fi
done < $here/tmp/$loc_exp/hist_ocn_files.csv
rm -f $curdir/*_tmp
rm -f $curdir/*_tmp1

# ice
echo -e "\ncopying $( cat $here/tmp/$loc_exp/hist_ice_files.csv | wc -l ) ice files"
curdir=$arch_dir/$loc_exp/history/ice
mkdir -p $curdir; chgrp $arch_grp $curdir
rm -f $curdir/*_tmp* 2>/dev/null
while IFS=, read -r file; do
  fdir=`dirname $file`
  fname=`basename $file`
  if [[ $arch_dir == $base_dir ]]; then
    #check nc version
    unset nctype
    nctype=$( ncdump -k $file )
    if [[ $nctype == "classic" ]]; then
      echo "-- $file"
      echo "  converting nc version"
      nccopy -k "netCDF-4 classic model" -d 1 -s $file ${file}_tmp
      mv ${file}_tmp ${file}
      chmod 644 $file
      chgrp $arch_grp $file
    fi
  elif [ ! -f $curdir/${fname} ]; then
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
    chgrp $arch_grp $curdir/$fname
  else
    echo "-- $file copied already"
  fi
done < $here/tmp/$loc_exp/hist_ice_files.csv
rm -f $curdir/*_tmp
rm -f $curdir/*_tmp1
