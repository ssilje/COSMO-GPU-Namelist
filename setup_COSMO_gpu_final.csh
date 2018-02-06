#!/usr/bin/tcsh

if ($#argv != 1) then
  echo "ERROR: incorrect number of arguments"
  echo "Usage: setup_experiment.csh <number_of_sim_year>"
  exit 1
endif

# get command line arguments
set experiment=COSMO-GPU_EUR50_ERAI_calibration_2000_2010
set numbyear=$argv[1]


set startdate=2000010100

set startyear=`echo $startdate | cut -c1-4`
@ endyear = ${startyear} + ${numbyear}
set enddate=${endyear}010100
@ endyear--

set workdir=/scratch/snx3000/${user}/${experiment}

# create all necessary directories
# create all necessary directories
mkdir -p $workdir
mkdir -p $workdir/input
mkdir -p $workdir/jobs
mkdir -p $workdir/log
mkdir -p $workdir/restart
mkdir -p $workdir/output
mkdir -p $workdir/output/station

foreach stream (out01 out02 out03 out04 out05 out06 out07)
  mkdir -p ${workdir}/output/${stream}
  set yr=$startyear
  while (${yr} <= ${endyear})
    mkdir -p ${workdir}/output/${stream}/${yr}
    @ yr++
  end
end

# copy and create namelist input files
cp /project/pr04/ssilje/RUN_COSMO_gpu/INPUT_files/INPUT_DYN $workdir
cp /project/pr04/ssilje/RUN_COSMO_gpu/INPUT_files/INPUT_DIA $workdir
cp /project/pr04/ssilje/RUN_COSMO_gpu/INPUT_files/INPUT_ASS $workdir
cp /project/pr04/ssilje/RUN_COSMO_gpu/INPUT_files/INPUT_INI $workdir
cp /project/pr04/ssilje/RUN_COSMO_gpu/INPUT_files/INPUT_PHY $workdir
cp /project/pr04/ssilje/RUN_COSMO_gpu/INPUT_files/modules_fortran.env $workdir

set yr=${startyear}
@ nyr = $startyear + 1
@ lyr = $startyear - 1

set stahr=0
set endhr=`/users/luethi/bin/time_diff ${startdate} ${nyr}010100`
set dirin="./input/${yr}/"

# loop over all desired years
while ( $yr <= $endyear )
# create INPUT_ORG for the current year
cat > ${workdir}/INPUT_ORG.${yr} <<EOFEOF
 &LMGRID
  startlat_tot = -28.93,
  startlon_tot  = -33.93,
  pollat = 39.25,
  pollon = -162.0,
  dlon = 0.440,
  dlat = 0.440,
  ie_tot = 132,
  je_tot = 129,
  ke_tot = 40,
 /END
 &RUNCTL
  dt = 300,
  hstart = ${stahr}, hstop = ${endhr},
  ydate_ini = '${startdate}',
  ydate_end = '${enddate}',
  nprocx = 1, nprocy = 1, nprocio = 0, nproma = -1,
  nboundlines = 3, 
  itype_calendar = 0,
  hincmxt = 24, hincmxu = 24,
  ncomm_type = 1,
  ldump_ascii=.FALSE.,
 /END
 &ARTIFCTL
  irefatm = 2,
 /END
&TUNING
  securi = 0.5,
  tkhmin = 0.4,
  tkmmin = 0.4,
  mu_rain = 0.5,
  v0snow = 20.0,
  rlam_heat = 1.0,
  qi0 = 0.0,
  uc1 = 0.3,
  cgamma= 0.63,
  tur_len= 500.0,
  fac_rootdp2= 1.0,
  radfac= 0.6,
 /END

EOFEOF



# create INPUT_IO for current year
  cat > ${workdir}/INPUT_IO.${yr} <<EOFEOF
 &IOCTL
  l_ke_in_gds=.TRUE.,
  yform_read = 'ncdf',
  nhour_restart = ${endhr},${endhr},720,
  ydir_restart_out = './restart',
  ydir_restart_in = './restart',
  ytunit_restart = 'd',
  ngribout = 7,
  yncglob_institution="Institute for Atmospheric and Climate Science, ETH Zurich
, Switzerland",
  yncglob_title = "control simulation cosmo-gpu over Europe",
  yncglob_source = "control",
  yncglob_project_id = "CORDEX-EU 0.44 ",
  yncglob_experiment_id =" ERA-I control ",
  ncglob_realization = 1,
  yncglob_contact = "Silje Soerland (silje.soerland@env.ethz.ch)"
  yncglob_references = "control",
  lbdclim = .TRUE.,
 /END
 &DATABASE
 /END
 &GRIBIN
  lbdana = .FALSE.,
  lana_qi = .FALSE.,
  llb_qi = .FALSE.,
  ydirini = '${dirin}',
  ydirbd = './input/${yr}/',
  hincbound = 6,
  lchkini = .TRUE.,
  lan_t_so0  = .TRUE.,
  lan_t_snow = .TRUE.,
  lan_t_cl   = .TRUE.,
  lan_w_snow = .TRUE.,
  lan_w_i    = .TRUE.,
  lan_w_cl   = .TRUE.,
  lan_vio3   = .TRUE.,
  lan_hmo3   = .TRUE.,
  lan_plcov  = .TRUE.,
  lan_lai    = .TRUE.,
  lan_rootdp = .TRUE.,
  ytunitbd='d',
 /END
 &GRIBOUT
  hcomb = ${stahr},${endhr},3,
  yvarml='FRESHSNW','PP','QC','QI','QV','QV_S','T','T_S','T_SNOW','T_SO',
         'U','V','W_I','W_SNOW','W_SO','WTDEPTH','S_SO','SATLEV',
         'Q_ROFF','W_SO_ICE',
  yvarpl = ' ', 
  yvarzl = ' ',
  luvmasspoint = .FALSE.,
  lcheck = .FALSE.,
  lwrite_const = .TRUE.,
  ydir = './output/out01/${yr}/',
  ytunit = 'd',
  yform_write = 'ncdf',
 /END
&GRIBOUT
  hcomb = ${stahr},${endhr},24,
  yvarml='P','W',
  yvarpl = ' ', 
  yvarzl = ' ',
  luvmasspoint = .TRUE.,
  lcheck = .FALSE.,
  lwrite_const = .FALSE.,
  ydir = './output/out02/${yr}/',
  ytunit = 'd',
  yform_write = 'ncdf',
 /END
 &GRIBOUT
  hcomb = ${stahr},${endhr},1,
  yvarml = 'SNOW_CON','SNOW_GSP','RAIN_CON','RAIN_GSP','TOT_PREC','DEW',
  yvarpl = ' ', 
  yvarzl = ' ',
  luvmasspoint = .TRUE.,
  lcheck = .FALSE.,
  lwrite_const = .FALSE.,
  ydir = './output/out03/${yr}/',
  ytunit = 'd',
  yform_write = 'ncdf',
 /END
 &GRIBOUT
  hcomb = ${stahr},${endhr},3,
  yvarml = 'ALHFL_S','ALWD_S','ALWU_S','ASHFL_S','ASOD_T','ASOB_T','ASOB_S','ATHB_T','ATHB_S',
           'ASWDIFD_S ','ASWDIFU_S','ASWDIR_S','CLCT','DURSUN','PMSL','PS','QV_2M','T_2M','U_10M','V_10M',
           'RELHUM_2M','ALB_RAD','ALHFL_BS','ALHFL_PL',
  yvarpl = ' ', 
  yvarzl = ' ',
  luvmasspoint = .TRUE.,
  lcheck = .FALSE.,
  lwrite_const = .FALSE.,
  ydir = './output/out04/${yr}/',
  ytunit = 'd',
  yform_write = 'ncdf',
 /END
 &GRIBOUT
  hcomb = ${stahr},${endhr},6,
  yvarml = 'AEVAP_S','CLCH','CLCL','CLCM','H_SNOW','RUNOFF_G','RUNOFF_S',
           'T_S','TQC ','TQI','TQV', 'W_SO_ICE','W_SO','HPBL','SNOW_MELT',
           'W_SNOW',
  yvarpl = ' ', 
  yvarzl = ' ',
  luvmasspoint = .TRUE.,
  lcheck = .FALSE.,
  lwrite_const = .FALSE.,
  ydir = './output/out05/${yr}/',
  ytunit = 'd',
  yform_write = 'ncdf',
 /END
 &GRIBOUT
  hcomb = ${stahr},${endhr},6,
  yvarml = ' '
  yvarpl = 'FI','QV','T','U','V','RELHUM',
  plev = 200.,500.,850.,925.,
  yvarzl = ' ',
  luvmasspoint = .TRUE.,
  lcheck = .FALSE.,
  lwrite_const = .FALSE.,
  ydir = './output/out06/${yr}/',
  ytunit = 'd',
  yform_write = 'ncdf',
 /END
&GRIBOUT
  hcomb = ${stahr},${endhr},24,
  yvarml='TMAX_2M','TMIN_2M','VMAX_10M','VABSMX_10M',
  yvarpl=' ',
  yvarzl=' ',
  luvmasspoint=.TRUE.,
  lcheck = .FALSE.,
  lwrite_const = .FALSE.,
  ydir = './output/out07/${yr}/',
  ytunit = 'd',
  yform_write = 'ncdf',
 /END
EOFEOF

# create job file for current year
cat > ${workdir}/jobs/job.${yr} <<EOF
#!/bin/tcsh
#SBATCH --job-name=cclm-gpu-50km_${yr}
#SBATCH --ntasks=1
#SBATCH --output=log/cclmgpu_50km_erai_${yr}.out
#SBATCH --error=log/cclmgpu_50km_erai_${yr}.err
#SBATCH --time=04:00:00
#SBATCH --gres=gpu:1
#SBATCH --account=pr04
#SBATCH --ntasks-per-node=1



setenv MV2_ENABLE_AFFINITY 0
setenv MV2_USE_CUDA 1
setenv MPICH_RDMA_ENABLED_CUDA 1
setenv MPICH_G2G_PIPELINE 256

ulimit -s unlimited

export OMP_NUM_THREADS=1
export MALLOC_MMAP_MAX_=0
export MALLOC_TRIM_THRESHOLD_=536870912

# ----------------
# GPU version
# ----------------
export G2G=1
export MV2_USE_CUDA=1
export MV2_USE_GPUDIRECT=0
export COSMO_NPROC_NODEVICE=0

source modules_fortran.env

cd ${workdir}
if ( -e YUSPECIF ) then
/bin/rm YU*
endif

if ( -e INPUT_ORG ) then
  /bin/rm -f INPUT_ORG
endif

cp INPUT_ORG.$yr INPUT_ORG

if ( -e INPUT_IO ) then
  /bin/rm -f INPUT_IO
endif
cp INPUT_IO.$yr INPUT_IO

# Run CLM in working directory

export MPICH_GNI_LMT_PATH=disabled  
srun -n 1 -u ./cosmo 


foreach f (YU*)
  mv \$f log/\${f}.$yr
end

foreach f (M_*)
  mv \$f output/station/\${f}.${yr}
end


if (${yr} < ${endyear}) then 
  if ( -e ./restart/lrfd${nyr}010100o ) then
    sbatch -N 1 -C gpu jobs/job.${nyr}
  endif
endif 


EOF



cat > ${workdir}/jobs/lbc_xfer.${yr} <<EOFEOF
#!/bin/csh
#SBATCH --account=pr04
#SBATCH --nodes=1
#SBATCH --partition=xfer
#SBATCH --time=4:00:00
#SBATCH --output=log/lbc_xfer.out
#SBATCH --error=log/lbc_xfer.err
#SBATCH --job-name="lbc_xfer_${yr}"




if (! -d ${workdir}/input/${yr}) then
  mkdir -p ${workdir}/input/${yr}
endif

cd ${workdir}/input/${yr}

foreach f (/store/c2sm/ch4/CORDEX_044/driving_data/year${yr}/laf*.tar )
   tar xvf \$f
end

if (${yr} > ${startyear}) then 

  cp  ${workdir}/input/${lyr}/lbfd${lyr}123118.nc .  

endif 
 
cd ${workdir}/input/${yr}

cd ${workdir}/
if (${yr} < ${endyear}) then 

    sbatch jobs/lbc_xfer.${nyr}

endif 
 
EOFEOF




  set dirin='./restart/'
  set yr=$nyr
  @ nyr++
  @ lyr++
  set stahr=$endhr
  set endhr=`/users/luethi/bin/time_diff ${startdate} ${nyr}010100`

end

# prepare initial and boundary data for the required years


#This needs to be copied in the initial condition file
#ncks -v S_ORO /project/pr04/external_parameter_files/s_oro_CORDEX-EU-044.nc laf1979010100.nc


# link executable to working directory


ln -sf /scratch/snx3000/ksilver/merge_terra/pascal_fix/cosmo-pompa/cosmo/cosmo_cordex_gpu ${workdir}/cosmo 
exit 0
