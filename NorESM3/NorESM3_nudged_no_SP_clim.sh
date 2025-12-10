#!/bin/bash

paths_noresm="/cluster/projects/nn2345k/ovewh/"

perror(){
  if [ $1 -ne 0 ]; then
    echo "ERROR: $2"
    exit $1
  fi
}

noresm_dir_name="NorESM3-mvertens"
export PATH=${paths_noresm}/${noresm_dir_name}/cime/scripts:${PATH}
nyears=13
resubmit=0
project="nn2345k"
runStartDate="2016-12-01"
res="ne16pg3_ne16pg3_mtn14"
compset="HIST_CAM70%LT%NORESM%CAMoslo_CLM60%SP_CICE%PRES_DOCN%DOM_MOSART_DGLC%NOEVOLVE_SWAV_SESP"
wall_clock_time="24:00:00"
queue="normal"
tag="noresm_develop_v7_proto-286-ge922f27"
case_dir="/cluster/projects/nn2345k/ovewh/Nudged_baseline/cases"

# set up the directory structure
mkdir -p ${case_dir}
current_date=$(date +%Y%m%d)

setup_case() {
    case_name=$1
    echo "Creating case: ${case_name}"
    echo "create_newcase --mach betzy --case \"${case_dir}/${case_name}\" --compset \"${compset}\" --res \"${res}\" --project \"${project}\" --compiler \"intel\" --driver nuopc --run-unsupported"
    create_newcase --mach betzy --case "${case_dir}/${case_name}" --compset "${compset}" --res "${res}" --project "${project}" --compiler "intel" --driver nuopc --run-unsupported
    perror $? "Problem with creating new case"
}

case_name="NFLTHIST_${res}_${tag}_${current_date}"
if [ -e "${case_dir}/${case_name}" ]; then
    echo "${case_name} already exists, skipping"
    continue
fi

echo "Setting up case: ${case_name}"

setup_case "${case_name}"

cd ${case_dir}/${case_name}

./xmlchange SSTICE_DATA_FILENAME="/cluster/shared/noresm/inputdata/atm/cam/sst/sst_HadOIBl_bc_1x1_1850_2021_c120422.nc"
./xmlchange NTASKS=-8
./xmlchange STOP_OPTION="nmonths"
./xmlchange RESUBMIT="${resubmit}"
./xmlchange --subgroup case.st_archive JOB_WALLCLOCK_TIME='04:00:00'
./xmlchange STOP_N="${nyears}"

./xmlchange RUN_STARTDATE="${runStartDate}"
./xmlchange SSTICE_YEAR_END="2021"
./xmlchange RUN_TYPE=startup
./xmlchange CALENDAR=GREGORIAN
./xmlchange JOB_WALLCLOCK_TIME="${wall_clock_time}" --subgroup case.run
./xmlchange JOB_QUEUE="${queue}" --subgroup case.run
./xmlchange --subgroup case.compress JOB_WALLCLOCK_TIME=3:00:00
./xmlchange REST_N=7
./case.setup

perror $? "Problem with case.setup."

echo "Setting up user namelists"

cat > user_nl_cam << EOF

! Users should add all user specific namelist changes below in the form of 
! namelist_var = new_namelist_value 
 
Nudge_model                = .true.
Nudge_Filenames            = 'era5_UVPS_58levels_201611.nc', 'era5_UVPS_58levels_201612.nc', 'era5_UVPS_58levels_201701.nc', 'era5_UVPS_58levels_201702.nc', 'era5_UVPS_58levels_201703.nc', 'era5_UVPS_58levels_201704.nc', 'era5_UVPS_58levels_201705.nc', 'era5_UVPS_58levels_201706.nc', 'era5_UVPS_58levels_201707.nc', 'era5_UVPS_58levels_201708.nc', 'era5_UVPS_58levels_201709.nc', 'era5_UVPS_58levels_201710.nc', 'era5_UVPS_58levels_201711.nc', 'era5_UVPS_58levels_201712.nc'
Nudge_Datapath             = '/cluster/shared/noresm/inputdata/noresm-only/inputForNudging/era5_UVPS_58levels_2016-2017/'
Nudge_Meshfile             = '/cluster/shared/noresm/inputdata/noresm-only/inputForNudging/era5_UVPS_ESMF_Mesh_cdf5.nc'
Nudge_beg_day              = 1
Nudge_beg_month            = 1
Nudge_beg_year             = 2016
Nudge_end_day              = 31
Nudge_end_month            = 12
Nudge_end_year             = 2017
Model_update_times_per_day = 48
Nudge_Force_Opt            = 1
Nudge_Uprof                = 1
Nudge_Ucoef                = 1.0
Nudge_Vprof                = 1
Nudge_Vcoef                = 1.0
Nudge_Tprof                = 0
Nudge_Tcoef                = 0.0
Nudge_PSprof               = 0
Nudge_PScoef               = 0.0
interpolate_nlat           = 96
interpolate_nlon           = 144
interpolate_output         = .true.
nhtfrq                     = -1,-1
mfilt                      = 1,1
ndens                      = 2,2

interpolate_nlat = 96,96
interpolate_nlon = 144,144
mfilt		= 1,120
ndens		= 2,2
nhtfrq		= 0,-3
fincl2    = 'Nudge_U','Nudge_V','Target_U','Target_V', 'U', 'V'
interpolate_output = .true., .true.

prescribed_ozone_file = "ozone_strataero_WACCM_L70_zm5day_18500101-21010201_CMIP6histEnsAvg_SSP245_c190403.nc"

flbc_file = '/cluster/shared/noresm/inputdata/atm/waccm/lb/LBC_17500116-25001216_CMIP6_SSP585_0p5degLat_h2-ch4-lbc-hyway_c20200824.nc'
history_aerosol = .true.
use_aerocom  = .true.
dust_emis_fact = 6.1D0
rafsip_on = .true.

micro_mg_dcs               = 700.D-6
clubb_c8                   =  5.0

&chem_inparm
 ext_frc_specifier		= 'H2O    -> /cluster/shared/noresm/inputdata/atm/cam/chem/emis/elev/H2OemissionCH4oxidationx2_3D_L70_1849-2101_CMIP6ensAvg_SSP2-4.5_c190403.nc',
         'BC_AX  ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_BC_AX_airALL_vertical_1995-2025_1.9x2.5_version20250620.nc',
         'BC_AX  ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_BC_AX_anthroprofENEIND_vertical_1995-2025_1.9x2.5_version20250620.nc',
         'BC_N   ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_BC_N_airALL_vertical_1995-2025_1.9x2.5_version20250620.nc',
         'BC_N   ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_BC_N_anthroprofENEIND_vertical_1995-2025_1.9x2.5_version20250620.nc',
         'BC_NI  ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_BC_NI_bbAGRIBORFDEFOPEATSAVATEMF_vertical_1995-2025_1.9x2.5_version20250620.nc',
         'OM_NI  ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_OM_NI_airALL_vertical_1995-2025_1.9x2.5_version20250620.nc',
         'OM_NI  ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_OM_NI_anthroprofENEIND_vertical_1995-2025_1.9x2.5_version20250620.nc',
         'OM_NI  ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_OM_NI_bbAGRIBORFDEFOPEATSAVATEMF_vertical_1995-2025_1.9x2.5_version20250620.nc',
         'SO2    ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_SO2_airALL_vertical_1995-2025_1.9x2.5_version20250620.nc',
         'SO2    ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_SO2_anthroprofENEIND_vertical_1995-2025_1.9x2.5_version20250620.nc',
         'SO2    ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_SO2_bbAGRIBORFDEFOPEATSAVATEMF_vertical_1995-2025_1.9x2.5_version20250620.nc',
         'SO2    ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_SO2_volcCONTEXPL_vertical_1995-2025_1.9x2.5_version20250620.nc',
         'SO4_PR ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_SO4_PR_airALL_vertical_1995-2025_1.9x2.5_version20250620.nc',
         'SO4_PR ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_SO4_PR_anthroprofENEIND_vertical_1995-2025_1.9x2.5_version20250620.nc',
         'SO4_PR ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_SO4_PR_bbAGRIBORFDEFOPEATSAVATEMF_vertical_1995-2025_1.9x2.5_version20250620.nc',
         'SO4_PR ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_SO4_PR_volcCONTEXPL_vertical_1995-2025_1.9x2.5_version20250620.nc'
  
 srf_emis_specifier	= 'BC_AX  ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_BC_AX_anthrosurfAGRTRADOMSOLWSTSHP_surface_1995-2025_1.9x2.5_version20250620.nc',
         'BC_N   ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_BC_N_anthrosurfAGRTRADOMSOLWSTSHP_surface_1995-2025_1.9x2.5_version20250620.nc',
         'OM_NI  ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_OM_NI_anthrosurfAGRTRADOMSOLWSTSHP_surface_1995-2025_1.9x2.5_version20250620.nc',
         'SO2    ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_SO2_anthrosurfAGRTRADOMSOLWSTSHP_surface_1995-2025_1.9x2.5_version20250620.nc',
         'SO4_PR ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_SO4_PR_anthrosurfAGRTRADOMSOLWSTSHP_surface_1995-2025_1.9x2.5_version20250620.nc'
 tracer_cnst_file	= "tracer_cnst_halons_3D_L70_1849-2101_CMIP6ensAvg_SSP2-4.5_c190403.nc"
    
/

ubc_file_input_type = 'CYCLICAL'
ubc_file_cycle_yr = 2010
ubc_file_path = '/cluster/shared/noresm/inputdata/atm/cam/chem/ubc/b.e21.BWHIST.f09_g17.CMIP6-historical-WACCM.ensAvg123.cam.h0zm.H2O.185001-201412_c230509cdf5.nc'


clim_modal_aero_top_press = 1.D-4

zmconv_c0_lnd		= 0.0075D0
zmconv_c0_ocn		= 0.0075D0
zmconv_ke               =  5.0E-6
zmconv_ke_lnd           =  1.0E-5
EOF

cat > user_nl_clm << EOF
EOF

cd ${case_dir}/${case_name}
./case.build

# perror $? "Problem with case.build."
# ./case.submit
# perror $? "Problem with case.submit."