# Clean up restart files

# Default is to leave one per year.
# Also option to leave one per decade, d0 to leave year 10, 20
# d1 to leave 11, 21 etc

# Normally leaves the last several files so it can be safely used
# on a running suite. Use -c to specify that the suite is complete
# and this isn't required
#
# Now also saves the very first file automatically
#
# E.g. py restart_cleanup_cm2.py -v -c -d 0 --dryrun bi889 #--exclude=2015 (SSPs)

from __future__ import print_function
import argparse, pathlib, os, datetime

parser = argparse.ArgumentParser(description="Clean up restart files")
# Use count so that -vv works
parser.add_argument('-v', '--verbose', dest='verbose',
                    action='count', default=0, help='verbose output')
parser.add_argument('-c', dest='complete', action='store_true',
                    help='Run is complete')
parser.add_argument('-d', dest='decadal_start', required=False,
                    type=int, default=-1,
                    help='Start year for keeping only decadal')
parser.add_argument('--dryrun', dest='dryrun', action='store_true',
                    help='Print what would be done')
parser.add_argument('--noatm', dest='noatm', action='store_true',
                    help='Skip atmosphere files')
parser.add_argument('--noocn', dest='noocn', action='store_true',
                    help='Skip ocean files')
parser.add_argument('--noice', dest='noice', action='store_true',
                    help='Skip ice files')
parser.add_argument('--nocpl', dest='nocpl', action='store_true',
                    help='Skip coupler files')
parser.add_argument('--exclude', dest='exclude', type=int,
                        nargs = '+', help='List of years to exclude (atm numbering')
parser.add_argument('--archivedir', dest='archivedir',
                    default=None,
                    help='archive directory (default is $disk/$PROJECT/$USER/archive')
parser.add_argument('--disk', dest='disk', default='/g/data',
                    help='disk where data is stored (default is /g/data/)')
parser.add_argument('runid', help='Run to process')

args = parser.parse_args()

if args.archivedir:
    archivedir = pathlib.Path(args.archivedir)
else:
    archivedir = pathlib.Path(args.disk, os.getenv('PROJECT'),
                              os.getenv('USER'), 'archive')
restartdir = archivedir.joinpath(args.runid,'restart')

if args.verbose:
    print("RESTARTDIR", restartdir)
    if args.exclude:
        print("Excluding", args.exclude)
if not args.exclude:
    args.exclude = []

if args.complete:
    keeplast = 1
else:
    keeplast = 10

if not args.noatm:    
    # Atmospheric files
    files = sorted(restartdir.joinpath('atm').glob("%sa.da[0-9]*_00" % args.runid))
    flist = list(files)[1:-keeplast]
    # Remove anything that's not 0101_00
    rlist = []
    for f in flist:
        if f.name.endswith('0101_00'):
            if args.decadal_start >= 0:
                # Remove everything where year%10 != decadal_start
                y = int(f.name[-11:-7])
                if y%10 != args.decadal_start and y not in args.exclude:
                    rlist.append(f)
        else:
            rlist.append(f)

    # Also remove the associated xhist files
    xlist = []
    for f in rlist:
        y = int(f.name[-11:-7])
        m = int(f.name[-7:-5])
        d = int(f.name[-5:-3])
        date = datetime.date(y,m,d)
        prev = date - datetime.timedelta(days=1)
        # For a warm restart this file might not exist at the start
        xfile = f.with_name('%s.xhist-%4.4d%2.2d%2.2d' % (args.runid, prev.year, prev.month, prev.day))
        if xfile.exists():
            xlist.append(f.with_name('%s.xhist-%4.4d%2.2d%2.2d' % (args.runid, prev.year, prev.month, prev.day)))

    remaining = list(set(files) - set(rlist))
    remaining.sort()
    if args.verbose:
        print("To remove\n", [f.name for f in rlist])
        print("Remaining\n", [f.name for f in remaining])

    if args.dryrun:
        if not args.verbose:
            print("To remove\n", [f.name for f in rlist])
    else:
        for f in rlist + xlist:
            f.unlink()

if not args.noocn:
    # Ocean files all have dates corresonding to end of run.
    # use temp_salt as a model for the rest
    files = sorted(restartdir.joinpath('ocn').glob("ocean_temp_salt.res.nc-[0-9]*"))
    flist = list(files)[1:-keeplast]
    # Remove anything that's not 1231
    rlist = []
    for f in flist:
        if f.name.endswith('1231'):
            if args.decadal_start >= 0:
                # Remove everything where year%10 != decadal_start
                y = int(f.name[-8:-4])
                # Use y+1 here to match the atm years
                if (y+1)%10 != args.decadal_start and y+1 not in args.exclude:
                    rlist.append(f)
        elif f.name.endswith('1231.tar'):
            if args.decadal_start >= 0:
                # Remove everything where year%10 != decadal_start
                y = int(f.name[-8:-4])
                # Use y+1 here to match the atm years
                if (y+1)%10 != args.decadal_start and y+1 not in args.exclude:
                    rlist.append(f)
        else:
            rlist.append(f)

    remaining = list(set(files) - set(rlist))
    remaining.sort()
    if args.verbose:
        print("To remove\n", [f.name for f in rlist])
        print("Remaining\n", [f.name for f in remaining])

    # Real list to remove is all files with the same suffix as
    # ocean_temp_salt.res.nc-YYYYMMDD
    rlistall = []
    for f in rlist:
        suffix = f.name[-8:]
        rlistall += sorted(restartdir.joinpath('ocn').glob("ocean*" + suffix))
    if args.verbose > 1:
        print("Full list to remove\n", [f.name for f in rlistall])

    if args.dryrun:
        if not args.verbose:
            print("To remove\n", [f.name for f in rlist])
    else:
        for f in rlistall:
            f.unlink()

if not args.noice:
    # Ice has ice.restart_file-YYYYMMDD and mice.nc-YYYYMMDD using
    # end of run date and iced.YYYY-MM-DD-00000.nc using start of
    # following run date
    for prefix in ("ice.restart_file-", "mice.nc-"):
        files = sorted(restartdir.joinpath('ice').glob(prefix +"[0-9]*"))
        flist = list(files)[1:-keeplast]
        # Remove anything that's not 1231
        rlist = []
        for f in flist:
            if f.name.endswith('1231'):
                if args.decadal_start >= 0:
                    # Remove everything where year%10 != decadal_start
                    y = int(f.name[-8:-4])
                    # Use y+1 here to match the atm years
                    if (y+1)%10 != args.decadal_start and y+1 not in args.exclude :
                        rlist.append(f)
            else:
                rlist.append(f)

        remaining = list(set(files) - set(rlist))
        remaining.sort()
        if args.verbose:
            print("To remove\n", [f.name for f in rlist])
            print("Remaining\n", [f.name for f in remaining])

        if args.dryrun:
            if not args.verbose:
                print("To remove\n", [f.name for f in rlist])
        else:
            for f in rlist:
                f.unlink()

    files = sorted(restartdir.joinpath('ice').glob("iced.[0-9-]*.nc"))
    flist = list(files)[1:-keeplast]
    # Remove anything that's not 0101_00000.nc
    rlist = []
    for f in flist:
        if f.name.endswith('01-01-00000.nc'):
            if args.decadal_start >= 0:
                # Remove everything where year%10 != decadal_start
                y = int(f.name[-19:-15])
                if y%10 != args.decadal_start and y not in args.exclude:
                    rlist.append(f)
        else:
            rlist.append(f)

    remaining = list(set(files) - set(rlist))
    remaining.sort()
    if args.verbose:
        print("To remove\n", [f.name for f in rlist])
        print("Remaining\n", [f.name for f in remaining])

    if args.dryrun:
        if not args.verbose:
            print("To remove\n", [f.name for f in rlist])
    else:
        for f in rlist:
            f.unlink()

if not args.nocpl:
    # Coupler files all have dates corresonding to end of run.
    # Use a2i.nc as a model for the rest
    files = sorted(restartdir.joinpath('cpl').glob("a2i.nc-[0-9]*"))
    flist = list(files)[1:-keeplast]
    # Remove anything that's not 1231
    rlist = []
    for f in flist:
        if f.name.endswith('1231'):
            if args.decadal_start >= 0:
                # Remove everything where year%10 != decadal_start
                y = int(f.name[-8:-4])
                # Use y+1 here to match the atm years
                if (y+1)%10 != args.decadal_start and y+1 not in args.exclude:
                    rlist.append(f)
        else:
            rlist.append(f)

    remaining = list(set(files) - set(rlist))
    remaining.sort()
    if args.verbose:
        print("To remove\n", [f.name for f in rlist])
        print("Remaining\n", [f.name for f in remaining])

    # Real list to remove is all files with the same suffix as
    # 
    rlistall = []
    for f in rlist:
        suffix = f.name[-8:]
        rlistall += sorted(restartdir.joinpath('cpl').glob("?2?.nc-*" + suffix))
    if args.verbose > 1:
        print("Full list to remove\n", [f.name for f in rlistall])

    if args.dryrun:
        if not args.verbose:
            print("To remove\n", [f.name for f in rlist])
    else:
        for f in rlistall:
            f.unlink()
    
