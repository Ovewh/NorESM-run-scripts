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
nmonths=27
resubmit=0
project="nn2345k"
runStartDate="2018-09-01"
res="ne16pg3_ne16pg3_mtn14"
compset="HIST_CAM70%LT%NORESM%CAMoslo_CLM60%SP_CICE%PRES_DOCN%DOM_MOSART_DGLC%NOEVOLVE_SWAV_SESP"
wall_clock_time="12:59:00"
queue="normal"
tag="SATACI_beta11_UVnudged"
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
./xmlchange --subgroup case.st_archive JOB_WALLCLOCK_TIME='03:00:00'
./xmlchange STOP_N="${nmonths}"
./xmlchange RUN_STARTDATE="${runStartDate}"
./xmlchange RUN_TYPE=startup
./xmlchange CALENDAR=GREGORIAN
./xmlchange JOB_WALLCLOCK_TIME="${wall_clock_time}" --subgroup case.run
./xmlchange JOB_QUEUE="${queue}" --subgroup case.run
./xmlchange GET_REFCASE=FALSE
./xmlchange CAM_CONFIG_OPTS="-phys cam7 -camnor -cosp -chem trop_mam_oslo -model_top lt"
./case.setup

cat > user_nl_cam << EOF
&nudging_nl
Nudge_Model = .true.
Nudge_Filenames = 'era5_UVPS_58levels_201801.nc',
                  'era5_UVPS_58levels_201802.nc',
                  'era5_UVPS_58levels_201803.nc',
                  'era5_UVPS_58levels_201804.nc',
                  'era5_UVPS_58levels_201805.nc',
                  'era5_UVPS_58levels_201806.nc',
                  'era5_UVPS_58levels_201807.nc',
                  'era5_UVPS_58levels_201808.nc',
                  'era5_UVPS_58levels_201809.nc',
                  'era5_UVPS_58levels_201810.nc',
                  'era5_UVPS_58levels_201811.nc',
                  'era5_UVPS_58levels_201812.nc',
                  'era5_UVPS_58levels_201901.nc',
                  'era5_UVPS_58levels_201902.nc',
                  'era5_UVPS_58levels_201903.nc',
                  'era5_UVPS_58levels_201904.nc',
                  'era5_UVPS_58levels_201905.nc',
                  'era5_UVPS_58levels_201906.nc',
                  'era5_UVPS_58levels_201907.nc',
                  'era5_UVPS_58levels_201908.nc',
                  'era5_UVPS_58levels_201909.nc',
                  'era5_UVPS_58levels_201910.nc',
                  'era5_UVPS_58levels_201911.nc',
                  'era5_UVPS_58levels_201912.nc',
                  'era5_UVPS_58levels_202001.nc',
                  'era5_UVPS_58levels_202002.nc',
                  'era5_UVPS_58levels_202003.nc',
                  'era5_UVPS_58levels_202004.nc',
                  'era5_UVPS_58levels_202005.nc',
                  'era5_UVPS_58levels_202006.nc',
                  'era5_UVPS_58levels_202007.nc',
                  'era5_UVPS_58levels_202008.nc',
                  'era5_UVPS_58levels_202009.nc',
                  'era5_UVPS_58levels_202010.nc',
                  'era5_UVPS_58levels_202011.nc',
                  'era5_UVPS_58levels_202012.nc'

Nudge_Datapath = '/cluster/shared/noresm/inputdata/noresm-only/inputForNudging/era5_UVPS_58levels_2018-2020/'
Nudge_Meshfile  = '/cluster/shared/noresm/inputdata/noresm-only/inputForNudging/era5_UVPS_ESMF_Mesh_cdf5.nc'
Nudge_Data_Year_First = 2018
Nudge_Data_Year_Last = 2020
Nudge_Data_taxmode = 'limit'
Nudge_beg_day = 1
Nudge_beg_month = 1
Nudge_beg_year = 2018
Nudge_end_year = 2020
Nudge_end_day = 31
Nudge_end_month=12
Model_update_times_per_day = 48
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
/

&chem_inparm
 ext_frc_specifier		= 'H2O    -> /cluster/shared/noresm/inputdata/atm/cam/chem/emis/elev/H2OemissionCH4oxidationx2_3D_L70_1849-2101_CMIP6ensAvg_SSP2-4.5_c190403.nc',
         'BC_AX  ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_BC_AX_airALL_vertical_1995-2025_1.9x2.5_version20250620.nc',
         'BC_AX  ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_BC_AX_anthroprofENEIND_vertical_1995-2025_1.9x2.5_version20250620.nc',
         'BC_N   ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_BC_N_airALL_vertical_1995-2025_1.9x2.5_version20250620.nc',
         'BC_N   ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_BC_N_anthroprofENEIND_vertical_1995-2025_1.9x2.5_version20250620.nc',
         'BC_NI  ->  /cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_BC_NI_bbAGRIBORFDEFOPEATSAVATEMF_vertical_1995-2025_1.9x2.5_version20250620.nc',
         'OM_NI  ->  1.4*/cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_OM_NI_airALL_vertical_1995-2025_1.9x2.5_version20250620.nc',
         'OM_NI  ->  1.4*/cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_OM_NI_anthroprofENEIND_vertical_1995-2025_1.9x2.5_version20250620.nc',
         'OM_NI  ->  2.6*/cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_OM_NI_bbAGRIBORFDEFOPEATSAVATEMF_vertical_1995-2025_1.9x2.5_version20250620.nc',
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
         'OM_NI  ->  1.4*/cluster/shared/noresm/inputdata/atm/cam/chem/emis/cmip7_emissions_version20250620/emissions_cmip7_noresm3_OM_NI_anthrosurfAGRTRADOMSOLWSTSHP_surface_1995-2025_1.9x2.5_version20250620.nc',
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
history_aerosol_radiation = .true.

avgflag_pertape = 'A', 'I', 'I'

fincl2 = 'EC550AER','EC550DU', 'mmr_DUST', 'PS', 'AIRMASS', 'CLDLIQ', 'CLDICE', 'BERGO', 'HOMOO', 'MNUCCCO',
         'ACTNI', 'ACTNL', 'ACTNL_B', 'ACTNL', 'ACTREI', 'ACTREL', 'AWNC', 'AWNI', 'CCN_B', 'CLDTOT', 'FICE',
         'NUMICE', 'NUMLIQ', 'FCTI', 'FCTL', 'FCTL_B', 'TGCLDCWP', 'TGCLDIWP', 'T', 'CCN3', 'TGCLDLWP','D550_DU',
         'DOD550', 'DOD870', 'DOD440', 'DELTAH', 'Z3' 

fincl3 = 'CLDTOT_ISCCP', 'CLHMODIS', 'CLLMODIS', 'CLIMODIS', 'CLMODIS', 'CLMMODIS', 'CLTMODIS', 'CLWMODIS', 'IWPMODIS',
         'CLWMODIS', 'LWPMODIS', 'IWPMODIS', 'MEANPTOP_ISCCP', 'MEANTB_ISCCP', 'PCTMODIS', 'MEANCLDALB_ISCCP',
         'FISCCP1_COSP', 'TAUIMODIS', 'REFFCLWMODIS', 'REFFCLIMODIS', 'TAUTMODIS', 'TAUWMODIS'

interpolate_nlat   = 96, 96, 0
interpolate_nlon   = 144, 144, 0
interpolate_output = .true., .true., .false.


dust_emis_method = 'Leung_2023'
rafsip_on  = .true.

micro_mg_dcs               = 550.D-6
micro_mg_berg_eff_factor   = 0.50D0
hetfrz_dust_scalfac        = 0.2D0
zmconv_tiedke_add          = 0.7
zmconv_c0_lnd              =  0.0075D0
zmconv_c0_ocn              =  0.0300D0
zmconv_ke                  =  5.0E-6
zmconv_ke_lnd              =  1.0E-5
dust_emis_fact = 3.4D0
clim_modal_aero_top_press = 1.D-4
clubb_c8                   = 5.0D0
EOF
perror $? "Problem with writing user_nl_cam"

cat > user_nl_clm << EOF
paramfile = '/cluster/shared/noresm/inputdata/lnd/clm2/paramdata/ctsm60_params.5.3.045_noresm_v14_c260117.nc'
snow_thermal_cond_glc_method = 'Jordan1991'
# use_init_interp = .true.
# init_interp_fill_missing_urban_with_HD = .true.
# finidat = '/cluster/work/users/kjetisaa/archive/i1850.ne30pg3_tn14.ctsm5.4.002_noresm_v1.CPLHIST_postADspinup_SHORT.2025-12-18/rest/0071-01-01-00000/i1850.ne30pg3_tn14.ctsm5.4.002_noresm_v1.CPLHIST_postADspinup_SHORT.2025-12-18.clm2.r.0071-01-01-00000.nc'
EOF

# perror $? "Problem with writing user_nl_clm"

./preview_namelists
perror $? "Problem with preview_namelists"

./case.build
perror $? "Problem with case.build"

./case.submit
perror $? "Problem with case.submit"