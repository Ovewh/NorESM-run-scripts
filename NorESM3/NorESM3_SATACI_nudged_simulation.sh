paths_noresm="/cluster/projects/nn2345k/ovewh/"

perror(){
  if [ $1 -ne 0 ]; then
    echo "ERROR: $2"
    exit $1
  fi
}

noresm_dir_name="NorESM3-mvertens"


cd ${paths_noresm}/${noresm_dir_name}
./describe_version
perror $? "Problem with describe_version"

export PATH=${paths_noresm}/${noresm_dir_name}/cime/scripts:${PATH}
nmonths=2
resubmit=0
project="nn2345k"
runStartDate="2020-06-01"
res="ne16pg3_ne16pg3_mtn14"
compset="HIST_CAM70%LT%NORESM%CAMoslo_CLM60%SP_CICE%PRES_DOCN%DOM_MOSART_DGLC%NOEVOLVE_SWAV_SESP"
wall_clock_time="03:59:00"
queue="normal"
tag="SATACI_beta07_UVnudged"
compset_tag="NFLHIST"
case_dir="/cluster/projects/nn2345k/ovewh/SATACI_simulations/cases"

mkdir -p ${case_dir}
current_date=$(date +%Y%m%d)

setup_case() {
    case_name=$1
    echo "Creating case: ${case_name}"
    echo "create_newcase --mach betzy --case \"${case_dir}/${case_name}\" --compset \"${compset}\" --res \"${res}\" --project \"${project}\" --compiler \"intel\" --driver nuopc --run-unsupported"
    create_newcase --mach betzy --case "${case_dir}/${case_name}" --compset "${compset}" --res "${res}" --project "${project}" --compiler "intel" --driver nuopc --run-unsupported
    perror $? "Problem with creating new case"
}

case_name="${compset_tag}_${res}_${tag}_${current_date}"
if [ -e "${case_dir}/${case_name}" ]; then
    echo "${case_name} already exists, skipping"
    continue
fi  

echo "Setting up case: ${case_name}"
setup_case "${case_name}"
cd ${case_dir}/${case_name}
./xmlchange NTASKS=-4
./xmlchange STOP_OPTION="nmonths"
./xmlchange --subgroup case.st_archive JOB_WALLCLOCK_TIME='00:45:00'
./xmlchange STOP_N="${nmonths}"
./xmlchange RUN_STARTDATE="${runStartDate}"
./xmlchange RUN_TYPE=hybrid
./xmlchange CALENDAR=GREGORIAN
./xmlchange JOB_WALLCLOCK_TIME="${wall_clock_time}" --subgroup case.run
./xmlchange JOB_QUEUE="${queue}" --subgroup case.run
./xmlchange RUN_REFDATE="2018-01-01"
./xmlchange RUN_REFDIR="/cluster/work/users/ovewh/archive/NFLTHIST_ne16pg3_ne16pg3_mtn14_Nudging_no_comp_SP_FATES_20251204/rest/2018-01-01-00000"
./xmlchange RUN_REFCASE="NFLTHIST_ne16pg3_ne16pg3_mtn14_Nudging_no_comp_SP_FATES_20251204"
./xmlchange GET_REFCASE=TRUE
./xmlchange CAM_CONFIG_OPTS="-phys cam7 -camnor -cosp -chem trop_mam_oslo -model_top lt"
./case.setup

cat > user_nl_cam << EOF
&nudging_nl
Nudge_Model = .true.
Nudge_Filenames = 'era5_UVPS_58levels_202006.nc', 'era5_UVPS_58levels_202007.nc'
Nudge_Datapath = '/cluster/shared/noresm/inputdata/noresm-only/inputForNudging/era5_UVPS_58levels_2020/'
Nudge_Meshfile  = '/cluster/shared/noresm/inputdata/noresm-only/inputForNudging/era5_UVPS_ESMF_Mesh_cdf5.nc'
Nudge_Force_Opt = 1
Nudge_Uprof     = 1
Nudge_Ucoef     = 1.0
Nudge_Vprof     = 1
Nudge_Vcoef     = 1.0
Nudge_Tprof     = 0
Nudge_Tcoef     = 0.0
Nudge_PSprof    = 0
Nudge_PScoef    = 0.0
Nudge_Qprof = 0
Nudge_Qcoef = 0.0
nudge_timescale_opt		= 0
Nudge_beg_day=2
Nudge_beg_month=6
Nudge_end_day=31
Nudge_end_month=7
Nudge_beg_year=2020
Nudge_end_year=2020
Model_update_times_per_day = 48
/

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

prescribed_ozone_file = "ozone_strataero_WACCM_L70_zm5day_18500101-21010201_CMIP6histEnsAvg_SSP245_c190403.nc"

flbc_file = '/cluster/shared/noresm/inputdata/atm/waccm/lb/LBC_17500116-25001216_CMIP6_SSP585_0p5degLat_h2-ch4-lbc-hyway_c20200824.nc'


nhtfrq = 0, -3, -3,
mfilt = 1, 120, 120

use_aerocom = .true.

history_aerosol = .true.

history_amwg = .true.

avgflag_pertape = 'A', 'I', 'I'

fincl2 = 'EC550AER', 'mmr_DUST', 'PS', 'AIRMASS', 'CLDLIQ', 'CLDICE', 'BERGO', 'HOMOO', 'MNUCCCO',
         'ACTNI', 'ACTNL', 'ACTNL_B', 'ACTNL', 'ACTREI', 'ACTREL', 'AWNC', 'AWNI', 'CCN_B', 'CLDTOT', 'FICE',
         'NUMICE', 'NUMLIQ', 'FCTI', 'FCTL', 'FCTL_B', 'TGCLDCWP', 'TGCLDIWP', 'T', 'CCN3', 'TGCLDLWP','D550_DU',
         'DOD550', 'DOD870', 'DOD440' 

fincl3 = 'CLDTOT_ISCCP', 'CLHMODIS', 'CLLMODIS', 'CLIMODIS', 'CLMODIS', 'CLMMODIS', 'CLTMODIS', 'CLWMODIS', 'IWPMODIS',
         'CLWMODIS', 'LWPMODIS', 'IWPMODIS', 'MEANPTOP_ISCCP', 'MEANTB_ISCCP', 'PCTMODIS', 'MEANCLDALB_ISCCP',
         'FISCCP1_COSP', 'TAUIMODIS', 'REFFCLWMODIS', 'REFFCLIMODIS', 'TAUTMODIS', 'TAUWMODIS'

interpolate_nlat   = 96, 96, 0
interpolate_nlon   = 144, 144, 0
interpolate_output = .true., .true., .false.


dust_emis_method = 'Leung_2023'
rafsip_on  = .true.

micro_mg_dcs               = 750.D-6
zmconv_c0_lnd		= 0.0075D0
zmconv_c0_ocn		= 0.0075D0
zmconv_ke               =  5.0E-6
zmconv_ke_lnd           =  1.0E-5
dust_emis_fact = 4.1D0
clim_modal_aero_top_press = 1.D-4
clubb_c8                   =  3.9D0
EOF
perror $? "Problem with writing user_nl_cam"

cat > user_nl_clm << EOF
use_init_interp = .true.
init_interp_fill_missing_urban_with_HD = .true.
EOF

perror $? "Problem with writing user_nl_clm"

./preview_namelists
perror $? "Problem with preview_namelists"

./case.build
perror $? "Problem with case.build"

./case.submit
perror $? "Problem with case.submit"