#1/bin/bash

echo -e "\n---- Copy & cull restarts ----"
echo $loc_exp
echo $access_version

echo -e "copying $( cat $here/tmp/$loc_exp/rest_dirs.csv | wc -l ) restart cycles"
curdir=$arch_dir/$loc_exp/restart/
mkdir -p $curdir; chgrp $arch_grp $curdir
while IFS=, read -r cycle; do
  cyclename=`basename $cycle`
  echo "-- $cyclename"
  rsync -rav $cycle $arch_dir/$loc_exp/restart/
  chmod -R 755 $arch_dir/$loc_exp/restart/$cyclename
  chgrp -R $arch_grp $arch_dir/$loc_exp/restart/$cyclename
done < $here/tmp/$loc_exp/rest_dirs.csv
