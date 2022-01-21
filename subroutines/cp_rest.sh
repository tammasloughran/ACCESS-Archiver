#1/bin/bash

echo -e "\n---- Copy & cull restarts ----"
echo $loc_exp
echo $access_version

# atm
echo -e "linking $( cat $here/tmp/$loc_exp/rest_atm_files.csv | wc -l ) atm restart files"
curdir=$arch_dir/$loc_exp/restart/atm
mkdir -p $curdir; chgrp $arch_grp $curdir
while IFS=, read -r file; do
  fdir=`dirname $file`
  fname=`basename $file`
  if [ ! -f $curdir/${fname} ]; then
    #echo "-- $fname"
    ln -s $file $curdir/$fname
  fi
done < $here/tmp/$loc_exp/rest_atm_files.csv

# ocn
echo -e "linking $( cat $here/tmp/$loc_exp/rest_ocn_files.csv | wc -l ) ocn restart files"
curdir=$arch_dir/$loc_exp/restart/ocn
mkdir -p $curdir; chgrp $arch_grp $curdir
while IFS=, read -r file; do
  fdir=`dirname $file`
  fname=`basename $file`
  if [ ! -f $curdir/${fname} ]; then
    #echo "-- $fname"
    ln -s $file $curdir/$fname
  fi
done < $here/tmp/$loc_exp/rest_ocn_files.csv

# ice
echo -e "linking $( cat $here/tmp/$loc_exp/rest_ice_files.csv | wc -l ) ice restart files"
curdir=$arch_dir/$loc_exp/restart/ice
mkdir -p $curdir; chgrp $arch_grp $curdir
while IFS=, read -r file; do
  fdir=`dirname $file`
  fname=`basename $file`
  if [ ! -f $curdir/${fname} ]; then
    #echo "-- $fname"
    ln -s $file $curdir/$fname
  fi
done < $here/tmp/$loc_exp/rest_ice_files.csv

# cpl
echo -e "linking $( cat $here/tmp/$loc_exp/rest_cpl_files.csv | wc -l ) cpl restart files"
curdir=$arch_dir/$loc_exp/restart/cpl
mkdir -p $curdir; chgrp $arch_grp $curdir
while IFS=, read -r file; do
  fdir=`dirname $file`
  fname=`basename $file`
  if [ ! -f $curdir/${fname} ]; then
    #echo "-- $fname"
    ln -s $file $curdir/$fname
  fi
done < $here/tmp/$loc_exp/rest_cpl_files.csv

#exit

# do cull
echo "checking for restart cull"
if [[ $access_version == esm* ]]; then
  echo "cleaning up restarts - ESM"
  python $here/subroutines/restart_cleanup_esm.py -v -c -d 0 --archivedir $arch_dir $loc_exp
elif [[ $access_version == cm2* ]]; then
  echo "cleaning up restarts - CM2"
  python $here/subroutines/restart_cleanup_cm2.py -v -c -d 0 --archivedir $arch_dir $loc_exp
else
  echo "no restart cull"
fi

# do copy
curdir=$arch_dir/$loc_exp/restart
restfiles=$( find $curdir -type l -printf "%p\n" | sort )
restfilescount=$( wc -l <<< "${restfiles[@]}" )
echo -e "copying $restfilescount restart files"
for restfile in $restfiles; do
  echo "-- $restfile"
  link=$( readlink -f $restfile )
  rsync -av $link ${restfile}_tmp
  mv ${restfile}_tmp $restfile
  chmod 644 $restfile
  chgrp $arch_grp $restfile
done
