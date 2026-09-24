paths_noresm="/cluster/projects/nn2345k/ovewh/"

perror(){
  if [ $1 -ne 0 ]; then
    echo "ERROR: $2"
    exit $1
  fi
}

noresm_dir_name="CAM-PPE"
runStartDate="2016-01-01"
res="ne16pg3_ne16pg3_mtn14"
compset="HIST_CAM70%LT%NORESM%CAMoslo_CLM60%FATES-SP%NORESM_CICE%PRES_DOCN%DOM_MOSART_DGLC%NOEVOLVE_SWAV_SESP" 
wall_clock_time="14:59:00"
queue="normal"
tag="AerocomNorESMbeta20_spinnup"
nmonths=12
project="nn2345k"
resubmit=4
compset_tag="NFLHIST"
case_dir="/cluster/projects/nn2345k/ovewh/AEROCOM_PHASE4/cases"

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
./xmlchange --subgroup case.compress JOB_WALLCLOCK_TIME='03:00:00'
./xmlchange STOP_N="${nmonths}"
./xmlchange RUN_STARTDATE="${runStartDate}"
./xmlchange RUN_TYPE=startup
./xmlchange CALENDAR=GREGORIAN
./xmlchange JOB_WALLCLOCK_TIME="${wall_clock_time}" --subgroup case.run
./xmlchange JOB_QUEUE="${queue}" --subgroup case.run
./xmlchange GET_REFCASE=FALSE
./case.setup
cat > user_nl_cam << EOF
Nudge_model = .true.
Nudge_Filenames = 'era5_UVPS_58levels_2016-2017/era5_UVPS_58levels_201601.nc','era5_UVPS_58levels_2016-2017/era5_UVPS_58levels_201602.nc',
                  'era5_UVPS_58levels_2016-2017/era5_UVPS_58levels_201603.nc','era5_UVPS_58levels_2016-2017/era5_UVPS_58levels_201604.nc',
                  'era5_UVPS_58levels_2016-2017/era5_UVPS_58levels_201605.nc','era5_UVPS_58levels_2016-2017/era5_UVPS_58levels_201606.nc',
                  'era5_UVPS_58levels_2016-2017/era5_UVPS_58levels_201607.nc','era5_UVPS_58levels_2016-2017/era5_UVPS_58levels_201608.nc',
                  'era5_UVPS_58levels_2016-2017/era5_UVPS_58levels_201609.nc','era5_UVPS_58levels_2016-2017/era5_UVPS_58levels_201610.nc', 
                  'era5_UVPS_58levels_2016-2017/era5_UVPS_58levels_201611.nc','era5_UVPS_58levels_2016-2017/era5_UVPS_58levels_201612.nc',
                  'era5_UVPS_58levels_2016-2017/era5_UVPS_58levels_201701.nc','era5_UVPS_58levels_2016-2017/era5_UVPS_58levels_201702.nc',
                  'era5_UVPS_58levels_2016-2017/era5_UVPS_58levels_201703.nc','era5_UVPS_58levels_2016-2017/era5_UVPS_58levels_201704.nc',
                  'era5_UVPS_58levels_2016-2017/era5_UVPS_58levels_201705.nc','era5_UVPS_58levels_2016-2017/era5_UVPS_58levels_201706.nc',
                  'era5_UVPS_58levels_2016-2017/era5_UVPS_58levels_201707.nc','era5_UVPS_58levels_2016-2017/era5_UVPS_58levels_201708.nc',
                  'era5_UVPS_58levels_2016-2017/era5_UVPS_58levels_201709.nc','era5_UVPS_58levels_2016-2017/era5_UVPS_58levels_201710.nc',
                  'era5_UVPS_58levels_2016-2017/era5_UVPS_58levels_201711.nc','era5_UVPS_58levels_2016-2017/era5_UVPS_58levels_201712.nc',
                  'era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_201801.nc','era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_201802.nc',
                  'era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_201803.nc','era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_201804.nc',
                  'era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_201805.nc','era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_201806.nc',
                  'era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_201807.nc','era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_201808.nc',
                  'era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_201809.nc','era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_201810.nc',
                  'era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_201811.nc','era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_201812.nc',
                  'era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_201901.nc','era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_201902.nc',
                  'era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_201903.nc','era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_201904.nc',
                  'era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_201905.nc','era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_201906.nc',
                  'era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_201907.nc','era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_201908.nc',
                  'era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_201909.nc','era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_201910.nc',
                  'era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_201911.nc','era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_201912.nc',
                  'era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_202001.nc','era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_202002.nc',
                  'era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_202003.nc','era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_202004.nc',
                  'era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_202005.nc','era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_202006.nc',
                  'era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_202007.nc','era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_202008.nc',
                  'era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_202009.nc','era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_202010.nc',
                  'era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_202011.nc','era5_UVPS_58levels_2018-2020/era5_UVPS_58levels_202012.nc'
Nudge_Datapath = '/cluster/shared/noresm/inputdata/noresm-only/inputForNudging/'
Nudge_Meshfile = '/cluster/shared/noresm/inputdata/noresm-only/inputForNudging/era5_UVPS_ESMF_Mesh_cdf5.nc'
Nudge_Data_Year_First = 2016
Nudge_Data_Year_Last = 2020
Nudge_Data_taxmode = 'limit'
Nudge_beg_day = 1
Nudge_beg_month = 1
Nudge_beg_year = 2016
Nudge_end_day = 31
Nudge_end_month = 12
Nudge_end_year = 2020
Model_update_times_per_day = 48
Nudge_Force_Opt = 1
Nudge_Uprof = 2
Nudge_Ucoef = 1.0
Nudge_Vprof = 2
Nudge_Vcoef = 1.0
Nudge_Tprof = 0
Nudge_Tcoef = 0.0
Nudge_PSprof = 0
Nudge_PScoef = 0.0

use_aerocom = .true.
history_aerosol = .true.
history_aerosol_radiation = .true.

nhtfrq = 0,-24
mfilt =1,30


fincl2 = 'ABS440:A', 'ABS550:A' ,'ABS870:A', 'DOD440:A', 'DOD550:A', 'DOD870:A','D550_DU'
bndtvg                     = '/cluster/shared/noresm/inputdata/atm/cam/ggas/noaamisc.r8.nc'
ubc_file_input_type = 'CYCLICAL'
ubc_file_cycle_yr = 2010
ubc_file_path = '/cluster/shared/noresm/inputdata/atm/cam/chem/ubc/b.e21.BWHIST.f09_g17.CMIP6-historical-WACCM.ensAvg123.cam.h0zm.H2O.185001-201412_c230509cdf5.nc'

prescribed_ozone_file = "ozone_strataero_WACCM_L70_zm5day_18500101-21010201_CMIP6histEnsAvg_SSP245_c190403.nc"

flbc_file = '/cluster/shared/noresm/inputdata/atm/waccm/lb/LBC_17500116-25001216_CMIP6_SSP585_0p5degLat_h2-ch4-lbc-hyway_c20200824.nc'
EOF

cat > user_nl_clm << EOF
fates_history_dimlevel = 1,2
hist_fexcl1='ACTUAL_IMMOB','BTRANMN','EFLXBUILD','EFLX_DYNBAL','EFLX_GRND_LAKE','FATES_DEMOTION_CARBONFLUX','FATES_EXCESS_RESP','FATES_MAINT_RESP_UNREDUCED','FATES_PRIMARY_PATCHFUSION_ERR','FATES_PROMOTION_CARBONFLUX','FATES_SEEDS_IN_LOCAL','FATES_UNGERM_SEED_BANK','HEAT_FROM_AC','HIA','HIA_R','HIA_U','HUMIDEX','HUMIDEX_R','HUMIDEX_U','LAKEICEFRAC_SURF','LAKEICETHICK','LNC','MORTALITY_CROWNAREA_CANOPY','MORTALITY_CROWNAREA_UNDERSTORY','QIRRIG_FROM_GW_CONFINED','QIRRIG_FROM_GW_UNCONFINED','QIRRIG_FROM_SURFACE','RSSHA','RSSUN','SWBGT','SWBGT_U','SWBGT_R','TBUILD','URBAN_AC','URBAN_HEAT','WASTEHEAT','WBT','WBT_R','WBT_U','FPG','FSH_R','F_DENIT','F_N2O_DENIT','F_N2O_NIT','F_NIT','GROSS_NMIN','HEAT_FROM_AC','HIA_R','HIA_U','HUMIDEX_R','HUMIDEX_U','LITTERC_HR','LIT_CEL_N','LIT_LIG_N','LIT_LIG_C','LIT_MET_C','LIT_MET_N','MORTALITY_CROWNAREA_CANOPY','MORTALITY_CROWNAREA_UNDERSTORY','NDEP_TO_SMINN','NET_NMIN','NFIX_TO_SMINN','POTENTIAL_IMMOB','POT_F_DENIT','POT_F_NIT','QIRRIG_FROM_GW_CONFINED','QIRRIG_FROM_GW_UNCONFINED','QIRRIG_FROM_SURFACE','SMINN_TO_PLANT','SMIN_NH4','SMIN_NO3','SMIN_NO3_LEACHED','SMIN_NO3_RUNOFF','SOM_ACT_C','SOM_ACT_N','SOM_C_LEACHED','SOM_PAS_C','SOM_PAS_N','SOM_SLO_C','SUPPLEMENT_TO_SMINN','SWBGT_R','SWBGT_U','TOTCOLC','TOTCOLN','TOTECOSYSC','TOTECOSYSN','TOTLITC','TOTLITC_1m','TOTLITN','TOTLITN_1m','TOTSOMC','TOTSOMN','TOT_WOODPRODC','TOT_WOODPRODC_LOSS','TOT_WOODPRODN','TOT_WOODPRODN_LOSS','WASTEHEAT','WBT','WBT_U','WBT_R','DWT_WOODPRODN_GAIN','VENTILATION','LIT_LIG_N_vr','LIT_LIG_N_vr','LIT_MET_N_vr','LIT_CEL_N_vr','SOILN_vr','SOM_ACT_N_vr','SOM_PAS_N_vr','SOM_SLO_N_vr','SMINN_vr','SMIN_NO3_vr','DWT_WOODPRODC_GAIN','EFLX_LH_TOT_R','LAISHA','LAISUN','SMINN','TOTSOMN_1m','SMIN_NH4_vr'
EOF
./case.build

./case.submit