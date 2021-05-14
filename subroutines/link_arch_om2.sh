#!/bin/bash

echo -e "\n---- Link OM2 archive ----"
echo $loc_exp
echo $access_version

if [ ! -f $here/tmp/$loc_exp/om2_info.csv ]; then
  echo "$here/tmp/$loc_exp/om2_info.csv not found!"
  exit
fi
#
if [[ $arch_dir == $base_dir ]]; then
  echo "cannot use OM2 version of ACCESS_Archiver on itself"
  exit
fi

determ_om2_val () {
  while IFS=' ' read outnums cyclenums ystarts yends; do
    if [[ $1 == */$outnums/* ]]; then
      cyclenum=$cyclenums
      ystart=$ystarts
      yend=$yends
      break
    fi
  done < $here/tmp/$loc_exp/om2_info.csv
}

# ocn
echo -e "\nlinking $( cat $here/tmp/$loc_exp/hist_ocn_files.csv | wc -l ) ocean files"
curdir=$arch_dir/$loc_exp/history/ocn
mkdir -p $curdir
rm -f $curdir/*_tmp* 2>/dev/null
while IFS=, read -r file; do
  fdir=`dirname $file`
  fname=`basename $file`
  unset cyclenum
  unset ystart
  unset yend
  determ_om2_val $fdir
  fname=${fname}-${cyclenum}
  if [ ! -L $curdir/${fname} ]; then
    echo "-- $file -> ${fname}"
    ln -s $file $curdir/${fname}
  else
    echo "-- ${fname} link already exists"
    link=$( readlink $curdir/${fname} )
    if [[ $link != $file ]]; then
      echo "  replacing link"
      rm $curdir/${fname}
      ln -s $file $curdir/${fname}
    fi
  fi
done < $here/tmp/$loc_exp/hist_ocn_files.csv

# ice
echo -e "\nlinking $( cat $here/tmp/$loc_exp/hist_ice_files.csv | wc -l ) ice files"
curdir=$arch_dir/$loc_exp/history/ice
mkdir -p $curdir
rm -f $curdir/*_tmp* 2>/dev/null
while IFS=, read -r file; do
  fdir=`dirname $file`
  fname=`basename $file`
  unset cyclenum
  unset ystart
  unset yend
  determ_om2_val $fdir
  if [[ $fname == *${ystart}* ]]; then
    fname=${fname//${ystart}/${cyclenum}}
  else
    fname=${fname}-${cyclenum}
  fi
  if [ -f $curdir/${fname} ]; then
    echo "-- ${fname} already exists, skipping"
    continue
  elif [ -L $curdir/${fname} ]; then
    echo "-- ${fname} link already exists"
    link=$( readlink $curdir/${fname} )
    if [[ $link != $file ]]; then
      echo "  deleting link"
      rm $curdir/${fname}
    fi
  fi
  if [ ! -L $curdir/${fname} ]; then
    echo "-- $file -> ${fname}"
    # check for non-standard field names (*_m)
    ice_m=false
    for var in $( ncks --jsn -q $file | jq '.variables | keys | .[]' ); do
      var=${var//\"/}
      if [[ $var == *_m ]]; then
        ice_m=true
      fi
    done
    if $ice_m; then
      echo "  non-standard field name detected, copying and fixing"
      # check nc version
      unset nctype
      nctype=$( ncdump -k $file )
      if [[ $nctype == "classic" ]]; then
        echo "  converting nc version"
        nccopy -k "netCDF-4 classic model" -d 1 -s $file $curdir/${fname}_tmp
      else
        rsync -av $file $curdir/${fname}_tmp
      fi
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
      ln -s $file $curdir/${fname}
    fi
  fi
done < $here/tmp/$loc_exp/hist_ice_files.csv
rm -f $curdir/*_tmp

exit
# restarts
echo -e "copying $( cat $here/tmp/$loc_exp/rest_dirs.csv | wc -l ) restart cycles"
curdir=$arch_dir/$loc_exp/restart/
mkdir -p $curdir
while IFS=, read -r cycle; do
  cyclename=`basename $cycle`
  echo "-- $cyclename"
  ln -s $cycle $arch_dir/$loc_exp/restart/$cyclename
done < $here/tmp/$loc_exp/rest_dirs.csv
