paths_noresm="/cluster/projects/nn2345k/ovewh/"

perror(){
  if [ $1 -ne 0 ]; then
    echo "ERROR: $2"
    exit $1
  fi
}

noresm_dir_name="CAM-PPE"
runStartDate="2019-05-01"
res="ne16pg3_ne16pg3_mtn14"
compset="HIST_CAM70%LT%NORESM%CAMoslo_CLM60%FATES-SP%NORESM_CICE%PRES_DOCN%DOM_MOSART_DGLC%NOEVOLVE_SWAV_SESP" 
wall_clock_time="04:59:00"
queue="normal"
tag="AerocomMMPPE_OAT_spinnup"
nmonths=3
project="nn2345k"
resubmit=0
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
./xmlchange REST_OPTION="nmonths"
./xmlchange --subgroup case.st_archive JOB_WALLCLOCK_TIME='03:00:00'
./xmlchange --subgroup case.compress JOB_WALLCLOCK_TIME='03:00:00'
./xmlchange STOP_N="${nmonths}"
./xmlchange REST_N="${nmonths}"
./xmlchange DOUT_S_SAVE_INTERIM_RESTART_FILES=TRUE
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
history_aerosol_radiation = .true.

avgflag_pertape = 'A','I'
nhtfrq = 0,-6
mfilt =1,120
fincl2 = 'A550_BC',
	'A550_DU',
	'A550_POM',
	'A550_SO4',
	'A550_SS',
	'ABS550',
	'ACTNI',
	'ACTNL',
	'ACTREI'
	'ACTREL',
	'CCN3',
	'CCN_B',
	'CDNUMC',
	'CLDFREE',
	'CLDTOT',
	'CLOUD',
	'D440_BC',
	'D440_DU',
	'D440_POM',
	'D440_SO4',
	'D440_SS',
	'D550_BC',
	'D550_DU',
	'D550_DU',
	'D550_POM',
	'D550_SO4',
	'D550_SS',
	'D870_BC',
	'D870_DU',
	'D870_POM',
	'D870_SO4',
	'D870_SS',
	'DELTAH',
	'DLT_BC',
	'DLT_DUST',
	'DLT_POM',
	'DLT_SO4',
	'DLT_SS',
	'DOD440',
	'DOD550',
	'DOD870',
	'EC550AER',
	'ECDRY440',
	'ECDRY870',
	'ECDRYAER',
	'FCTI',
	'FCTL',
	'FCTL_B',
	'FLNT',
	'FORMRATE',
	'FREQI',
	'FREQL',
	'FSDS',
	'FSDSC',
	'FSNS',
	'FSNT',
	'FSUTOA',
	'LHFLX',
	'LWCF',
	'PRECT',
	'PS',
	'SOLIN',
	'SWCF',
	'TGCLDCWP',
	'TGCLDIWP',
	'TGCLDLWP',
	'TREFHT',
	'U10',
	'WSUB',
	'cb_BC',
	'cb_DMS',
	'cb_DUST',
	'cb_H2O2',
	'cb_H2SO4',
	'cb_OM',
	'cb_SALT',
	'cb_SO2',
	'cb_SULFATE',
	'cb_isoprene',
	'cb_monoterp'

bndtvg                     = '/cluster/shared/noresm/inputdata/atm/cam/ggas/noaamisc.r8.nc'
ubc_file_input_type = 'CYCLICAL'
ubc_file_cycle_yr = 2010
ubc_file_path = '/cluster/shared/noresm/inputdata/atm/cam/chem/ubc/b.e21.BWHIST.f09_g17.CMIP6-historical-WACCM.ensAvg123.cam.h0zm.H2O.185001-201412_c230509cdf5.nc'

prescribed_ozone_file = "ozone_strataero_WACCM_L70_zm5day_18500101-21010201_CMIP6histEnsAvg_SSP245_c190403.nc"

flbc_file = '/cluster/shared/noresm/inputdata/atm/waccm/lb/LBC_17500116-25001216_CMIP6_SSP585_0p5degLat_h2-ch4-lbc-hyway_c20200824.nc'
EOF

cat > user_nl_clm << EOF
finidat = '/cluster/work/users/ovewh/archive/NFLHIST_ne16pg3_ne16pg3_mtn14_AerocomNorESMbeta20_spinnup_20260707/rest/2021-01-01-00000/NFLHIST_ne16pg3_ne16pg3_mtn14_AerocomNorESMbeta20_spinnup_20260707.clm2.r.2021-01-01-00000.nc'
check_finidat_year_consistency = .false.
EOF
./case.build
