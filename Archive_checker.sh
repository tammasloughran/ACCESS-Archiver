#!/bin/bash
################################
if [ ! -z $1 ]; then
  exptloc=$1
  origloc=$2
  access_ver=$3
  expt=$4
else
  echo "no experiment settings"
  exit
fi
################################
#
atm=1
ocn=1
ice=1
#
################################
# FIXED SETTINGS
#here=$( pwd )
here=/g/data/p66/cm2704/ACCESS-Archiver
mkdir -p $here/tmp/$expt
rm -f $here/tmp/$expt/job_arch_check.qsub.sh 
####
echo -e "\n==== ACCESS_Archiver ===="
echo "orig dir: $origloc"
echo "arch dir: $exptloc"
echo "access version: $access_ver"
echo "local exp: $expt"
#
#################################
#
cat << EOF > $here/tmp/$expt/job_arch_check.qsub.sh 
#!/bin/bash
#PBS -P p66
#PBS -q copyq
#PBS -l walltime=10:00:00,ncpus=1,mem=8Gb,wd
#PBS -l storage=gdata/access+scratch/p66+gdata/p66+gdata/hh5
#PBS -j oe
#PBS -N ${expt}_arch_check
module purge
#module use /g/data/hh5/public/modules
#module use ~access/modules
#module load ants/0.11.0
module load nco
module load nccmp

expt=$expt
access_ver=$access_ver
loc=$exptloc/$expt
origloc=$origloc
rm -f \$loc/tmp*
atm=$atm
ocn=$ocn
ice=$ice

if [[ -z \$origloc ]]; then 
  echo no data location found for experiment \$expt
  exit
fi

echo "ACCESS Archiver Checker"
echo "expt: \$expt"
echo "original loc: \$origloc"
echo "expt loc: \$loc"

declare -A atmfreq=( ["[m,a]"]="mon" ["[d,e]"]="dai" ["[7,j]"]="6h" ["[8,i]"]="3h" )
#declare -A atmfreq=( ["[d,e]"]="dai" )

declare -A monmap=( ["jan"]="01" ["feb"]="02" ["mar"]="03" ["apr"]="04" ["may"]="05" ["jun"]="06"\
    ["jul"]="07" ["aug"]="08" ["sep"]="09" ["oct"]="10" ["nov"]="11" ["dec"]="12" )

for freq in "\${!atmfreq[@]}"; do
  if [[ "\$atm" == 1 ]]; then
    echo "checking \${atmfreq[\$freq]} \$freq atm..."
    atmok=0
    atmbad=0
    atmmissing=0
    if [[ $access_ver == cm2 ]] || [[ $access_ver == esmscript ]]; then
      atmfind=\$( find \${origloc}/\${expt}/history/atm/ -type f -name "*.p"\$freq"*" -printf "%p\n" | sort )
    elif [[ $access_ver == cm2amip ]]; then
      atmfind=\$( find \${origloc}/u-\${expt}/share/data/History_Data -type f -name "*.p"\$freq"*" -printf "%p\n" | sort )
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
        monmapkey=0
        for key in \${!monmap[@]}; do
          if [[ \$b == *"\${key}" ]]; then
            newfile=\$loc/history/atm/netCDF/\${b%\${key}}"\${monmap[\${key}]}_\${atmfreq[\$freq]}".nc
            monmapkey=1
          fi
        done
        if [[ \$monmapkey == 0 ]]; then
          newfile=\$loc/history/atm/netCDF/\${b}"_\${atmfreq[\$freq]}".nc
        fi
        #echo "newfile: \$newfile"
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
              echo "   \$(basename \$newfile) (original: \$(basename \$origfile))"
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
          echo "   \$(basename \$newfile) (original: \$(basename \$origfile))"
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
  ocnfind=\$( find \${origloc}/\${expt}/history/ocn/ -type f -name "ocean*.nc*" -printf "%p\n" | sort )
  if [ "\${ocnfind}" != "" ]; then
    for origfile in \${ocnfind}; do
      b=\$(basename \$origfile)
      if [[ \$b == .?* ]]; then
        echo "\$b is hidden, skipping"
        continue
      fi
      newfile=\$loc/history/ocn/\${b}
      if [[ \$newfile == *.nc.[0-9][0-9][0-9][0-9]* ]]; then
        if [[ \$newfile == *.nc.0000* ]]; then
          mppnfile=\${newfile%.*}
          IFS=- read tmp DATE <<< \$b
          newfile=\$mppnfile-\${DATE}
          if [ -e "\$newfile" ]; then
            ocnok=\$((ocnok+1))
          else
            echo "caution: missing file!"
            echo "   \$(basename \$newfile) (original: \$(basename \$origfile))"
            ocnmissing=\$((ocnmissing+1))
          fi
        fi
      else
        if [ -e "\$newfile" ]; then
          if nccmpout=\$( nccmp --warn=format -BNmq \$newfile \$origfile ); then
            ocnok=\$((ocnok+1))
          else
            if [ -e "\${newfile//.nc-/.nc.0000-}" ]; then
              ocnok=\$((ocnok+1))
            else
              echo "caution: bad file!"
              echo "   \$(basename \$newfile) (original: \$(basename \$origfile))"
              ocnbad=\$((ocnbad+1))
            fi
          fi
        else
          echo "caution: missing file!"
          echo "   \$(basename \$newfile) (original: \$(basename \$origfile))"
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
  icefind=\$( find \${origloc}/\${expt}/history/ice/ -type f -name "iceh*" -printf "%p\n" | sort )
  if [ "\${icefind}" != "" ]; then
    for origfile in \${icefind}; do
      b=\$(basename \$origfile)
      if [[ \$b == .?* ]]; then
        echo "\$b is hidden, skipping"
        continue
      fi
      newfile=\$loc/history/ice/\${b}
      if [ -e "\$newfile" ]; then
        if nccmpout=\$( nccmp --warn=format -BNmq \$newfile \$origfile ); then
          iceok=\$((iceok+1))
        elif nccmpout=\$( nccmp --warn=format -BNmq -x hi,hs,Tsfc,aice,uvel,vvel,hi_m,hs_m,Tsfc_m,aice_m,uvel_m,vvel_m \$newfile \$origfile ); then
          iceok=\$((iceok+1))
        else
          echo "caution: bad file!"
          echo "   \$(basename \$newfile) (original: \$(basename \$origfile))"
          icebad=\$((icebad+1))
        fi  
      else
        echo "caution: missing file!"
        echo "   \$(basename \$newfile) (original: \$(basename \$origfile))"
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
