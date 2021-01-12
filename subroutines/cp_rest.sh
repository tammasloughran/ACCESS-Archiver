#1/bin/bash

echo -e "\n---- Copy & cull restarts ----"

if [ -f $here/tmp/$loc_exp/omip_info.csv ]; then
  omip=true
else
  omip=false
fi
determ_omip_val () {
  while IFS=' ' read cycle outvals; do
    if [[ $1 == */${cycle//output/restart}/* ]]; then
      outval=$outvals
      break
    fi
  done < $here/tmp/$loc_exp/omip_info.csv
}

# atm
echo -e "linking $( cat $here/tmp/$loc_exp/rest_atm_files.csv | wc -l ) atm restart files"
curdir=$arch_dir/$loc_exp/restart/atm
mkdir -p $curdir
while IFS=, read -r file; do
  fdir=`dirname $file`
  fname=`basename $file`
  if [ ! -f $curdir/${fname} ]; then
    echo "-- $fname"
    ln -s $file $curdir/$fname
  fi
done < $here/tmp/$loc_exp/rest_atm_files.csv

# ocn
echo -e "linking $( cat $here/tmp/$loc_exp/rest_ocn_files.csv | wc -l ) ocn restart files"
curdir=$arch_dir/$loc_exp/restart/ocn
mkdir -p $curdir
while IFS=, read -r file; do
  fdir=`dirname $file`
  fname=`basename $file`
  if $omip; then
    determ_omip_val $fdir
    #if [[ $fname != *$eyear* ]]; then
    #  fname=${fname}-${eyear}
    #fi
    fname=${fname}-${outval}
    unset outval
  fi
  if [ ! -f $curdir/${fname} ]; then
    echo "-- $fname"
    ln -s $file $curdir/$fname
  fi
done < $here/tmp/$loc_exp/rest_ocn_files.csv

# ice
echo -e "linking $( cat $here/tmp/$loc_exp/rest_ice_files.csv | wc -l ) ice restart files"
curdir=$arch_dir/$loc_exp/restart/ice
mkdir -p $curdir
while IFS=, read -r file; do
  fdir=`dirname $file`
  fname=`basename $file`
  if $omip; then
    determ_omip_val $fdir
    #if [[ $fname != *$eyear* ]]; then
    #  fname=${fname}-${eyear}
    #fi
    fname=${fname}-${outval}
    unset outval
  fi
  if [ ! -f $curdir/${fname} ]; then
    echo "-- $fname"
    ln -s $file $curdir/$fname
  fi
done < $here/tmp/$loc_exp/rest_ice_files.csv

# cpl
echo -e "linking $( cat $here/tmp/$loc_exp/rest_cpl_files.csv | wc -l ) cpl restart files"
curdir=$arch_dir/$loc_exp/restart/cpl
mkdir -p $curdir
while IFS=, read -r file; do
  fdir=`dirname $file`
  fname=`basename $file`
  if $omip; then
    determ_omip_val $fdir
    #if [[ $fname != *$eyear* ]]; then
    #  fname=${fname}-${eyear}
    #fi
    fname=${fname}-${outval}
    unset outval
  fi
  if [ ! -f $curdir/${fname} ]; then
    echo "-- $fname"
    ln -s $file $curdir/$fname
  fi
done < $here/tmp/$loc_exp/rest_cpl_files.csv

#exit

# do cull
#if $omip; then
#  echo "omip - no restart cull"
if $esm; then
  echo "cleaning up restarts - ESM"
  python $here/subroutines/restart_cleanup_esm.py -v -c -d 0 --archivedir $arch_dir $loc_exp
else
  echo "cleaning up restarts - CM2"
  python $here/subroutines/restart_cleanup.py -v -c -d 0 --archivedir $arch_dir $loc_exp
fi

# do copy
curdir=$arch_dir/$loc_exp/restart
restfiles=$( find $curdir -type l -printf "%p\n" | sort )
restfilescount=$( wc -l <<< "${restfiles[@]}" )
echo -e "copying $restfilescount restart files"
for restfile in $restfiles; do
  echo "-- $restfile"
  link=$( readlink $restfile )
  rsync -av $link ${restfile}_tmp
  mv ${restfile}_tmp $restfile
  chmod 644 $restfile
  chgrp p66 $restfile
done
