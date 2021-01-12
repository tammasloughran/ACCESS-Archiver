import os, sys, collections, csv
import multiprocessing as mp
import um2netcdf4 #_cm2704 as um2netcdf4
import subprocess as sp
import mule
import shutil

try: ncpus=int(os.environ.get('ncpus'))
except: ncpus=1
here=os.environ.get('here')
base_dir=os.environ.get('base_dir')
arch_dir=os.environ.get('arch_dir')
loc_exp=os.environ.get('loc_exp')
if os.environ.get('zonal').lower() in ['true','yes','1']: zonal=True
else: zonal=False
if os.environ.get('esm').lower() in ['true','yes','1']: esm=True
else: esm=False
if os.environ.get('plev8').lower() in ['true','yes','1']: plev8=True
else: plev8=False
Args = collections.namedtuple('Args',\
    'nckind compression simple nomask hcrit verbose include_list exclude_list nohist use64bit')
args = Args(3, 4, True, False, 0.5, False, None, None, False, False)
monmap={"jan":"01","feb":"02","mar":"03","apr":"04","may":"05","jun":"06",\
    "jul":"07","aug":"08","sep":"09","oct":"10","nov":"11","dec":"12"}

def plev8(outname):
    if (outname.find('.pe') != -1) or (outname.find('.pd') != -1):
        print('attempting plev8 conversion')
        [dirname,basename]=os.path.split(outname)
        os.makedirs(dirname+'/plev19_daily',exist_ok=True)
        plev19file=dirname+'/plev19_daily/'+basename
        plev8file=outname+'_plev8'
        os.rename(outname,plev19file)
        output = sp.run(['ncks','-d','pressure,2','-d','pressure,5','-d','pressure,7','-d',\
            'pressure,10','-d','pressure,13','-d','pressure,15','-d','pressure,16','-d',\
            'pressure,18',plev19file,plev8file],capture_output=True,text=True)
        if output.returncode != 0:
            print('no plev19 found')
        else:
            os.replace(plev8file,outname)
            print('converted to plev8')
    else: return

def fix_esm_lbvc9(file,outname):
    lbvc9=False
    ff=mule.FieldsFile.from_file(file, 'r')
    for fld in ff.fields:
        if fld.lbvc == 9:
            fld.lbvc=65
            lbvc9=True
    if lbvc9:
        ff.to_file(outname.replace('.nc','')+'_lbvc9-fixed')
    return lbvc9

def do_um2nc(file,freq):
    basename=os.path.basename(file)
    for key in monmap.keys():
        if basename.find(key) != -1: basename=basename.replace(key,monmap[key]+'001')
    if arch_dir == base_dir:
        print(basename+': already archived')
        if plev8: plev8(file)
        sys.stdout.flush()
    elif basename.find('.nc'):
        print(basename+': file already netCDF')
        outname=arch_dir+'/'+loc_exp+'/history/atm/netCDF/'+basename
        shutil.copyfile(file,outname+'_tmp')
        os.replace(outname+'_tmp',outname)
        if plev8: plev8(outname)
        os.chmod(outname,0o644)
        sys.stdout.flush()
    else:
        outname=arch_dir+'/'+loc_exp+'/history/atm/netCDF/'+basename+'_'+freq+'.nc'
        try: os.remove(outname+'_tmp')
        except: pass
        try: os.remove(outname.replace('.nc','')+'_lbvc9-fixed')
        except: pass
        if not os.path.exists(outname):
            print(basename)
            if esm: 
                lbvc9=fix_esm_lbvc9(file,outname)
                if lbvc9: 
                    um2netcdf4.process(outname.replace('.nc','')+'_lbvc9-fixed',outname+'_tmp',args)
                    os.remove(outname.replace('.nc','')+'_lbvc9-fixed')
                else: um2netcdf4.process(file,outname+'_tmp',args)
            else: um2netcdf4.process(file,outname+'_tmp',args)
            os.replace(outname+'_tmp',outname)
            if plev8: plev8(outname)
            os.chmod(outname,0o644)
            sys.stdout.flush()
        else: 
            print(basename+': file already exists')
            #if plev8: plev8(outname)
            sys.stdout.flush()
        
def do_um2nc_zonal(file,freq):
    basename=os.path.basename(file)
    os.makedirs(arch_dir+'/'+loc_exp+'/history/atm/zonal/',exist_ok=True)
    tmpname=arch_dir+'/'+loc_exp+'/history/atm/zonal/'+basename
    for key in monmap.keys():
        if basename.find(key) != -1: basename=basename.replace(key,monmap[key]+'001')
    outname=arch_dir+'/'+loc_exp+'/history/atm/netCDF/'+basename+'_'+freq+'.nc'
    try: os.remove(outname+'_tmp')
    except: pass
    try: os.remove(outname+"_zonal_tmp")
    except: pass
    try: os.remove(tmpname+"_zonal")
    except: pass
    try: os.remove(tmpname+"_nonzonal")
    except: pass
    if not os.path.exists(outname):
        print(basename)
        sp.run(["mule-select",file,tmpname+"_zonal","--include","lbnpt=1"],capture_output=False)
        sp.run(["mule-select",file,tmpname+"_nonzonal","--exclude","lbnpt=1"],capture_output=False)
        try:
            um2netcdf4.process(tmpname+"_zonal",outname+"_zonal_tmp",args)
            os.replace(outname+"_zonal_tmp",outname+"_zonal")
            os.chmod(outname+"_zonal",0o644)
        except: print('no zonal data')
        um2netcdf4.process(tmpname+"_nonzonal",outname+'_tmp',args)
        os.remove(tmpname+"_nonzonal")
        os.remove(tmpname+"_zonal")
        os.replace(outname+'_tmp',outname)
        os.chmod(outname,0o644)
        sys.stdout.flush()
    else: 
        print(basename+': file already exists')
        sys.stdout.flush()

def read_files(here,loc_exp):
    print('reading '+here+'/tmp/'+loc_exp+'/hist_atm_files.csv')
    hist_atm_mon=[]
    hist_atm_dai=[]
    hist_atm_6hr=[]
    hist_atm_3hr=[]
    hist_atm_oth=[]
    try:
        with open(here+'/tmp/'+loc_exp+'/hist_atm_files.csv',newline='') as csvfile:
            read=csv.reader(csvfile)
            for row in read:
                if any(mon in os.path.basename(row[0]) for mon in ['.pm','.pa']):
                    hist_atm_mon.append(row[0])
                elif any(dai in os.path.basename(row[0]) for dai in ['.pd','.pe']):
                    hist_atm_dai.append(row[0])
                elif any(sixhr in os.path.basename(row[0]) for sixhr in ['.p7','.pj']):
                    hist_atm_6hr.append(row[0])
                elif any(threehr in os.path.basename(row[0]) for threehr in ['.p8','.pi']):
                    hist_atm_3hr.append(row[0])
                else: hist_atm_oth.append(row[0])
    except: print('file not found: '+here+'/tmp/'+loc_exp+'/hist_atm_files.csv')
    hist_atm=[hist_atm_mon,hist_atm_dai,hist_atm_6hr,hist_atm_3hr,hist_atm_oth]
    return hist_atm

def main():
    print('\n---- Run um2netCDF4 ----')
    # Read in file list from tmp/$loc_exp
    hist_atm=read_files(here,loc_exp)
    hist_atm_mon,hist_atm_dai,hist_atm_6hr,hist_atm_3hr,hist_atm_oth=hist_atm
    print('len(hist_atm) = {}'.format(len(hist_atm)))
    if len(hist_atm_mon)+len(hist_atm_dai)+len(hist_atm_6hr)+len(hist_atm_3hr)+len(hist_atm_oth) > 0:
        os.makedirs(arch_dir+'/'+loc_exp+'/history/atm/netCDF',exist_ok=True)   
    else: 
        print('no atm history files found')
    #sys.exit('no atm history files found')
    # Do um2netcdf  
    print('converting UM files to netCDF4')
    print('multiprocessor sees {} cpus'.format(ncpus))
    print('zonal processing is {}'.format(zonal))
    if len(hist_atm_mon) > 0:
        print('found '+str(len(hist_atm_mon))+' monthly atm files')
        if ncpus == 1:
            for file in hist_atm_mon: do_um2nc(file,'mon')
        else:
            with mp.Pool(ncpus) as pool:
                pool.starmap(do_um2nc,((file,'mon') for file in hist_atm_mon))
    if len(hist_atm_dai) > 0:
        print('found '+str(len(hist_atm_dai))+' daily atm files')
        if ncpus == 1:
            for file in hist_atm_dai: do_um2nc(file,'dai')
        else:
            with mp.Pool(ncpus) as pool:
                if zonal: pool.starmap(do_um2nc_zonal,((file,'dai') for file in hist_atm_dai))
                else: pool.starmap(do_um2nc,((file,'dai') for file in hist_atm_dai))
    if len(hist_atm_6hr) > 0:
        print('found '+str(len(hist_atm_6hr))+' 6-hourly atm files')
        if ncpus == 1:
            for file in hist_atm_6hr: do_um2nc(file,'6h')
        else:
            with mp.Pool(ncpus) as pool:
                pool.starmap(do_um2nc,((file,'6h') for file in hist_atm_6hr))
    if len(hist_atm_3hr) > 0:
        print('found '+str(len(hist_atm_3hr))+' 3-hourly atm files')
        if ncpus == 1:
            for file in hist_atm_3hr: do_um2nc(file,'3h')
        else:
            with mp.Pool(ncpus) as pool:
                pool.starmap(do_um2nc,((file,'3h') for file in hist_atm_3hr))
    if len(hist_atm_oth) > 0:
        print('found '+str(len(hist_atm_oth))+' unidentified atm files (will not be converted)')
    print('um2netCDF_iris complete')

if __name__ == "__main__":
    main()
