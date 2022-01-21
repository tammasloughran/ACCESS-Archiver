#!/bin/bash
################################
#
# This is the ACCESS Archiver, v1.0
# 15/07/2021
# 
# Developed by Chloe Mackallah, CSIRO Aspendale
#
################################
if [ -z $arch_dir ]; then
  echo "no experiment settings"
  exit
fi
################################
# ADDITIONAL USER SETTINGS

#turn on/off realms
atm=1
ocn=1
ice=1

################################
# DO NOT EDIT - FIXED TASKS

#check wrapper is used
if [ -z $arch_dir ]; then
  echo "no experiment settings"
  exit
fi
here=$( pwd )
mkdir -p $here/tmp/$loc_ecp
rm -f $here/tmp/$loc_exp/job_arch_check.qsub.sh 
#identify NCI project of base_dir
IFS='/'
read -a base_dir_split <<< $base_dir
for bdse in ${base_dir_split[@]}; do
  if [[ $bdse == '' ]] || [[ $bdse == ' ' ]] || [[ $bdse == 'g' ]] || \
    [[ $bdse == 'data' ]] || [[ $bdse == 'scratch' ]]; then
    continue
  fi
  base_grp=$bdse
  break
done
#identify NCI project of arch_dir
IFS='/'
read -a arch_dir_split <<< $arch_dir
for adse in ${arch_dir_split[@]}; do
  if [[ $adse == '' ]] || [[ $adse == ' ' ]] || [[ $adse == 'g' ]] || \
    [[ $adse == 'data' ]] || [[ $adse == 'scratch' ]]; then
    continue
  fi
  arch_grp=$adse
  break
done
#
################################
# PRINT DETAILS TO SCREEN 

echo -e "\n==== ACCESS_Archiver ===="
echo "compute project: $comp_proj"
echo "base directory: $base_dir"
echo "archive directory: $arch_dir"
echo "access version: $access_version"
echo "local exp: $loc_exp"

#################################
#
cat << EOF > $here/tmp/$loc_exp/job_arch_check.qsub.sh 
#!/bin/bash
#PBS -P ${comp_proj}
#PBS -q copyq
#PBS -l walltime=10:00:00,ncpus=1,mem=8Gb,wd
#PBS -l storage=scratch/${base_grp}+gdata/${base_grp}+scratch/${arch_grp}+gdata/${arch_grp}+gdata/hh5+gdata/access
#PBS -j oe
#PBS -N ${expt}_arch_check
module purge
#module use /g/data/hh5/public/modules
#module use ~access/modules
#module load ants/0.11.0
module load nco
module load nccmp

expt=$loc_exp
access_ver=$access_version
loc=$arch_dir/$loc_exp
origloc=$base_dir
rm -f \$loc/tmp*
atm=$atm
ocn=$ocn
ice=$ice
subdaily=$subdaily

if [[ -z \$origloc ]]; then 
  echo no data location found for experiment \$expt
  exit
fi

echo "ACCESS Archiver Checker"
echo "expt: \$expt"
echo "original loc: \$origloc"
echo "expt loc: \$loc"

if $subdaily; then
  declare -A atmfreq=( ["[m,a]"]="mon" ["[d,e]"]="dai" ["[7,j]"]="6h" ["[8,i]"]="3h" )
else
  declare -A atmfreq=( ["[m,a]"]="mon" ["[d,e]"]="dai" )
fi

declare -A monmap=( ["jan"]="01" ["feb"]="02" ["mar"]="03" ["apr"]="04" ["may"]="05" ["jun"]="06"\
    ["jul"]="07" ["aug"]="08" ["sep"]="09" ["oct"]="10" ["nov"]="11" ["dec"]="12" )

for freq in "\${!atmfreq[@]}"; do
  if [[ "\$atm" == 1 ]]; then
    echo "checking \${atmfreq[\$freq]} \$freq atm..."
    atmok=0
    atmbad=0
    atmmissing=0
    if [[ $access_ver == cm2 ]] || [[ $access_ver == esmscript ]]; then
      atmfind=\$( find \${origloc}/\${expt}/history/atm/ -maxdepth 1 -type f -name "*.p"\$freq"*" -printf "%p\n" | sort )
    elif [[ $access_ver == cm2amip ]]; then
      atmfind=\$( find \${origloc}/u-\${expt}/share/data/History_Data/ -maxdepth 1 -type f -name "*.p"\$freq"*" -printf "%p\n" | sort )
    elif [[ $access_ver == *payu ]]; then
      atmfind=\$( find \${origloc}/\${expt}/output*/atmosphere/ -maxdepth 1 -type f -name "aiihca.p"\$freq"*" -printf "%p\n" | sort )
    else
      echo "ACCESS version $access_ver not included in Archive_checker yet!"
      exit
    fi
    if [ "\${atmfind}" != "" ]; then
      count=0
      for origfile in \${atmfind}; do
        #echo "origfile: \$origfile"
        if [ -e \${origfile}.nc ]; then
          continue
        fi
        b=\$(basename \$origfile)
        if [[ \$b == .?* ]]; then
          echo "\$b is hidden, skipping"
          continue
        elif [[ \$b == *.nc ]]; then
          b=\${b//.nc}
        fi
        if [[ $access_ver == *payu ]]; then
          dir=\$(dirname \$origfile)
          timestampfile="\$dir"/../ocean/time_stamp.out
          if [ ! -f \$timestampfile ]; then
            echo "ERR: no time stamp file for \$origfile"
            atmbad=\$((atmbad+1))
            continue
          fi
          yarr=()
          while IFS=' ' read -ra year; do
            yarr+=( "\$( printf '%04d' \$year )" )
          done < "\$timestampfile"
          payuyr=\${yarr[0]}
          freqind=\${b#aiihca.p}
          freqind=\${freqind:0:1}
          for key in \${!monmap[@]}; do
            if [[ \$b == *"\${key}" ]]; then
              monind=\${monmap[\${key}]}
            fi
          done
          newfile=\$loc/history/atm/netCDF/\${expt}.p\${freqind}-\${payuyr}\${monind}_\${atmfreq[\$freq]}.nc
        else
          monmapkey=0
          for key in \${!monmap[@]}; do
            if [[ \$b == *"\${key}" ]]; then
              newfile=\$loc/history/atm/netCDF/\${b%\${key}}"\${monmap[\${key}]}_\${atmfreq[\$freq]}".nc
              monmapkey=1
            fi
          done
          if [[ \$monmapkey == 0 ]]; then
            if [[ "\$b" == *.p?-[0-9][0-9][0-9][0-9]0[0-9][0-9]001 ]]; then
              b=\${b::-3}
              sb=\${b::-3}
              eb=\${b: -2}
              b="\${sb}\${eb}"
            fi
            newfile=\$loc/history/atm/netCDF/\${b}"_\${atmfreq[\$freq]}".nc
          fi
        fi
        #echo "newfile: \$newfile"
        #exit
        #
        if [ -e "\$newfile" ]; then
          if [[ "\$count" == 120 ]] || [[ "\$count" == 0 ]]; then
            #echo "new comparison file"
            #echo "   \$(basename \$newfile) (original: \$(basename \$origfile))"
            compfile=\$newfile
            ncks -m \$compfile > \$loc/tmp_comp.txt
            sed -i '/UNLIMITED/d' \$loc/tmp_comp.txt
            sed -i '/netcdf/d' \$loc/tmp_comp.txt
            sed -i '/time_0/d' \$loc/tmp_comp.txt
            count=0
            atmok=\$((atmok+1))
          else
            ncks -m \$newfile > \$loc/tmp_new.txt
            sed -i '/UNLIMITED/d' \$loc/tmp_new.txt
            sed -i '/netcdf/d' \$loc/tmp_new.txt
            sed -i '/time_0/d' \$loc/tmp_new.txt
            diff=\$( diff \$loc/tmp_comp.txt \$loc/tmp_new.txt )
            if [[ "\$diff" == "" ]]; then
              atmok=\$((atmok+1))
            else
              echo "caution! meta does not match, new comparison file"
              echo "   \$(basename \$newfile) (original: \$origfile)"
              compfile=\$newfile
              ncks -m \$compfile > \$loc/tmp_comp.txt
              sed -i '/UNLIMITED/d' \$loc/tmp_comp.txt
              sed -i '/netcdf/d' \$loc/tmp_comp.txt
              sed -i '/time_0/d' \$loc/tmp_comp.txt
              count=0
              atmok=\$((atmok+1))
            fi
          fi
        else
          echo "caution: missing file!"
          echo "   \$(basename \$newfile) (original: \$origfile)"
          atmmissing=\$((atmmissing+1))
        fi
        count=\$((count+1))
        done
    else
      echo "   no \${atmfreq[\$freq]} atm files"
    fi
    echo ""
    echo "\${atmfreq[\$freq]} atm summary:"
    echo "\${atmfreq[\$freq]} atm ok = \$atmok"
    echo "\${atmfreq[\$freq]} atm bad = \$atmbad"
    echo "\${atmfreq[\$freq]} atm missing = \$atmmissing"
    echo ""
  else
    echo "not checking \${atmfreq[\$freq]} atm"
  fi
done

if [[ $access_ver == cm2amip ]]; then
  exit
fi

if [[ "\$ocn" == 1 ]]; then
  echo "checking ocn..."
  ocnok=0
  ocnbad=0
  ocnmissing=0
  if [[ $access_ver == *payu ]]; then
    ocnfind=\$( find \${origloc}/\${expt}/output*/ocean -type f -name "ocean_*.nc*" -printf "%p\n" | sort )
  else
    ocnfind=\$( find \${origloc}/\${expt}/history/ocn/ -type f -name "ocean*.nc*" -printf "%p\n" | sort )
  fi
  if [ "\${ocnfind}" != "" ]; then
    for origfile in \${ocnfind}; do
      b=\$(basename \$origfile)
      if [[ \$b == .?* ]]; then
        echo "\$b is hidden, skipping"
        continue
      fi
      if [[ $access_ver == *payu ]]; then
        dir=\$(dirname \$origfile)
        timestampfile="\$dir"/time_stamp.out
        if [ ! -f \$timestampfile ]; then
          echo "ERR: no time stamp file for \$origfile"
          continue
        fi
        yarr=()
        while IFS=' ' read -ra year; do
          yarr+=( "\$( printf '%04d' \$year )" )
        done < "\$timestampfile"
        payuyr=\${yarr[0]}
        if [[ \$b != *\$payuyr* ]]; then
          newfile=\$loc/history/ocn/\${b}\-\${payuyr}1231
        fi
      else
        newfile=\$loc/history/ocn/\${b}
      fi
      if [[ \$newfile == *.nc.[0-9][0-9][0-9][0-9]* ]]; then
        if [[ \$newfile == *.nc.0000* ]]; then
          if [[ $access_ver == *payu ]]; then
            newfile=\${newfile//.0000/}
          else
            #mppnfile=\${newfile%.*}
            #IFS=- read tmp DATE <<< \$b
            #newfile=\$mppnfile-\${DATE}
            newfile=\${newfile//.0000/}
          fi
          if [ -e "\$newfile" ]; then
            ocnok=\$((ocnok+1))
          else
            echo "caution: missing file!"
            echo "   \$(basename \$newfile) (original: \$origfile)"
            ocnmissing=\$((ocnmissing+1))
          fi
        fi
      else
        if [ -e "\$newfile" ]; then
          if nccmpout=\$( nccmp --warn=format -BNmq \$newfile \$origfile ); then
            ocnok=\$((ocnok+1))
          else
            if [ -e "\${origfile//.nc/.nc.0000}" ]; then
              ocnok=\$((ocnok+1))
            else
              echo "caution: bad file!"
              echo "   \$(basename \$newfile) (original: \$origfile)"
              ocnbad=\$((ocnbad+1))
            fi
          fi
        else
          echo "caution: missing file!"
          echo "   \$(basename \$newfile) (original: \$origfile)"
          ocnmissing=\$((ocnmissing+1))
        fi
      fi
    done
    echo ""
    echo "ocn summary:"
    echo "ocn ok = \$ocnok"
    echo "ocn bad = \$ocnbad"
    echo "ocn missing = \$ocnmissing"
    echo ""
  else
    echo "   no ocn files"
  fi
else
  echo "not checking ocn"
fi

if [[ "\$ice" == 1 ]]; then
  echo ""
  echo "checking ice..."
  iceok=0
  icebad=0
  icemissing=0
  if [[ $access_ver == *payu ]]; then
    icefind=\$( find \${origloc}/\${expt}/output*/ice/ -type f -name "ice*.nc" -printf "%p\n" | sort )
  else
    icefind=\$( find \${origloc}/\${expt}/history/ice/ -type f -name "iceh*" -printf "%p\n" | sort )
  fi
  if [ "\${icefind}" != "" ]; then
    for origfile in \${icefind}; do
      b=\$(basename \$origfile)
      if [[ \$b == .?* ]]; then
        echo "\$b is hidden, skipping"
        continue
      fi
      if [[ $access_ver == *payu ]]; then
        dir=\$(dirname \$origfile)
        timestampfile="\$dir"/../ocean/time_stamp.out
        if [ ! -f \$timestampfile ]; then
          echo "ERR: no time stamp file for \$origfile"
          continue
        fi
        yarr=()
        while IFS=' ' read -ra year; do
          yarr+=( "\$( printf '%04d' \$year )" )
        done < "\$timestampfile"
        payuyr=\${yarr[0]}
        if [[ \$b != *\$payuyr* ]]; then
          if [[ \$b == ice*.????-??.nc ]]; then
            IFS=.-
            read -ra fnamearr <<< "\$b"
            unset IFS
            newfile=\$loc/history/ice/\${fnamearr[0]}.\${payuyr}-\${fnamearr[2]}.nc
          fi
        else
          newfile=\$loc/history/ice/\${b}
        fi
      else
        newfile=\$loc/history/ice/\${b}
      fi
      if [ -e "\$newfile" ]; then
        if nccmpout=\$( nccmp --warn=format -BNmq \$newfile \$origfile ); then
          iceok=\$((iceok+1))
        elif nccmpout=\$( nccmp --warn=format -BNmq -x hi,hs,Tsfc,aice,uvel,vvel,hi_m,hs_m,Tsfc_m,aice_m,uvel_m,vvel_m \$newfile \$origfile ); then
          iceok=\$((iceok+1))
        else
          echo "caution: bad file!"
          echo "   \$(basename \$newfile) (original: \$origfile)"
          icebad=\$((icebad+1))
        fi  
      else
        echo "caution: missing file!"
        echo "   \$(basename \$newfile) (original: \$origfile)"
        icemissing=\$((icemissing+1))
      fi
    done
    echo ""
    echo "ice summary:"
    echo "ice ok = \$iceok"
    echo "ice bad = \$icebad"
    echo "ice missing = \$icemissing"
    echo ""
  else
    echo "   no ice files"
  fi
else
  echo "not checking ice"
fi

#
# The end
#

EOF

/bin/chmod 755 $here/tmp/$expt/job_arch_check.qsub.sh
ls $here/tmp/$expt/job_arch_check.qsub.sh
qsub $here/tmp/$expt/job_arch_check.qsub.sh
