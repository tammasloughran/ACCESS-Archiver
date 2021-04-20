#!/bin/bash

echo -e "\n---- Checking for mppnccombine ----"

mppnc=/g/data/access/projects/access/access-cm2/utils/mppnccombine_nc4

ocndir=$arch_dir/$loc_exp/history/ocn
mppncfiles=$( find $ocndir -name "*.nc.0000*" -printf "%p\n" | sort )

for histfile in ${mppncfiles[@]}; do
  echo $histfile
  #drop the suffix '.0000'
  basefile=${histfile%.*}
  IFS=- read tmp DATE <<< `basename $histfile`
  output=$basefile-${DATE}
  echo $output
  rm -f $output
  $mppnc -n4 -z -v -r $output ${basefile}.????-$DATE
  echo "completed generating $output"
done

