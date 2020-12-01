#!/bin/bash
#PBS -P p66
#PBS -l walltime=6:00:00,ncpus=1,mem=8Gb
#PBS -l wd
#PBS -l storage=scratch/p66+gdata/p66+gdata/hh5+scratch/access
#PBS -q normal
#PBS -j oe
#PBS -N extvar_cdo
module purge
module load cdo


dir=/g/data/p66/cm2704/archive/bj594/history/atm/netCDF/link
var=fld_s03i236

cdo -select,name=$var $dir/*.pm* tas_test.nc
