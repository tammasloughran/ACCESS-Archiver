# ACCESS-Archiver

This is the ACCESS Archiver, v1.1

Developed by Chloe Mackallah, CSIRO Aspendale; 
with significant contributions from Martin Dix and others.

---

The ACCESS Archiver is designed to archive model output from [ACCESS](https://research.csiro.au/access/) simulations. It's focus is to copy ACCESS model output from its initial location to a secondary location (typically from /scratch to /g/data), while converting UM files to netCDF, compressing MOM/CICE files, and culling restart files to 10-yearly. Saves 50-80% of storage space due to conversion and compression.

Supported versions are CM2 (coupled, amip & chem versions), ESM1.5 (script & payu versions), OM2[-025]. For use on NCI's Gadi system only.

## wrap_ACCESS_Archiver.sh

Main control script. Here you will specify:  
i) the NCI project to use (*comp_proj*),  
ii) the directory in which the target model output is located (*base_dir*),   
iii) the directory in which the model archive is to be created (*arch_dir*),   
iv) the version of ACCESS used (*access_version*; supported versions are CM2, CM2-amip, ESM1.5-script, ESM1.5-payu, OM2),   
v) the name(s) of the experiment(s) which is/are to be archived (*loc_exps*),  
vi) whether of not to archive subdaily atmospheric files (*subdaily*),  
vii) whether or not to use any pre-converted netCDF files (*ncexists*), and  
viii) the task to run (*task*; either archive an exp, or check a previously archived exp). 

To run, simply use the command: 
``` 
$ ./wrap_ACCESS_Archiver.sh  
```

## ACCESS_Archiver.sh

PBS job creator script. Additional controls in this script include options to:   
i) separate zonally-averaged fields in the atmosphere files (*zonal*; primarily used for CM2 DAMIP simulations),   
ii) reduce the number of pressure levels in daily atmosphere files from 19 to 8 (*plev8*; primarily used for ESM1.5 CMIP6 simulations).

This script will first call *find_files[\_payu,\_om2].sh*, 
which will save lists of model output and restart files, 
and copy any other required scripts from the *subroutines/* directory, in *tmp/*.  
For payu and OM2 versions, this includes creating a reference file relating cycles to model years.

Three PBS jobs are then created:

**1. atmosphere conversion job:**  
*run_um2nc.py* calls the Iris-based um2netcdf4 code 
from the ACCESS project area (*/g/data/access/projects/access/modules/pythonlib/um2netcdf4/2.0*), 
and renames files appropriately. Atmosphere files are saved in the archive under *history/atm/netCDF*.   
(*Note: job not created for ACCESS-OM2*)

**2. ocean, sea-ice, & restart copy job:**  
*copy_hist.sh* will copy and appropriately rename 
all ocean and sea-ice files, while also checking for netCDF version (nc4 conversion where necessary) 
and certain sea-ice variable names which break the APP4 CMORisation code. *copy_rest.sh* will save 10-yearly 
restart files (5-yearly for payu).  
(*Note: for ACCESS-OM2, few files are actually copied -- only sea-ice files 
requiring variable renaming -- due to the CMIP6 use case where the model output was retained in the COSIMA project. 
By and large, only symlinks are created, which are useful for the APP4 CMORisation code*)

**3. ocean cleanup job:**  
*mppnccomb_check.sh* will check if any ocean files did not combine correctly 
(usually performed by ACCESS, but occasionally fails), calling the mppnccombine code from the ACCESS project area 
(*/g/data/access/projects/access/access-cm2/utils/mppnccombine_nc4*) if necessary.  
This job is automatically submitted at the end of the ocn/ice/rest copy job.

## Archive_checker.sh

This script will (independently of the file lists in *tmp/*) check that all model output files from the 
target experiment have been copied, along with some basic metadata checks in the case of corrupted files. 
Currently supported for CM2, CM2-amip, ESM1.5-script, and ESM1.5-payu. 
This is called from *wrap_ACCESS_Archiver.sh* by altering the *task* variable.


