#1/bin/bash

echo -e "\n---- Copy & cull restarts ----"
echo $loc_exp
echo $access_version

# ocn
echo -e "copying $( cat $here/tmp/$loc_exp/rest_dirs.csv | wc -l ) restart cycles"
curdir=$arch_dir/$loc_exp/restart/
mkdir -p $curdir
while IFS=, read -r cycle; do
  cyclename=`basename $cycle`
  echo "-- $cyclename"
  rsync -rav $cycle $arch_dir/$loc_exp/restart/
  chmod -R 755 $arch_dir/$loc_exp/restart/$cyclename
  chgrp -R p66 $arch_dir/$loc_exp/restart/$cyclename
done < $here/tmp/$loc_exp/rest_dirs.csv
