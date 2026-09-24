paths_noresm="/cluster/projects/nn2345k/ovewh/"

perror(){
  if [ $1 -ne 0 ]; then
    echo "ERROR: $2"
    exit $1
  fi
}

noresm_dir_name="CAM-SATACI"
runStartDate="0000-01-01"
res="ne16pg3_ne16pg3_mtn14"
compset="2000_CAM70%LT%NORESM%CAMoslo_CLM60%SP_CICE%PRES_DOCN%DOM_MOSART_DGLC%NOEVOLVE_SWAV_SESP" 
wall_clock_time="14:59:00"
queue="normal"
tag="NFHIST"
nmonths=12
project="nn2345k"
resubmit=4
compset_tag="NF2000_CLM-SP"
case_dir="/cluster/projects/nn2345k/ovewh/NorESM_dev/cases"

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
./xmlchange JOB_WALLCLOCK_TIME="${wall_clock_time}" --subgroup case.run
./xmlchange JOB_QUEUE="${queue}" --subgroup case.run
./xmlchange GET_REFCASE=FALSE
./xmlchange RESUBMIT="${resubmit}"
./case.setup
cat > user_nl_cam << EOF
use_aerocom = .true.
history_aerosol = .true.
history_aerosol_radiation = .true.

nhtfrq = 0
mfilt =1

bndtvg                     = '/cluster/shared/noresm/inputdata/atm/cam/ggas/noaamisc.r8.nc'
ubc_file_input_type = 'CYCLICAL'
ubc_file_cycle_yr = 2010
ubc_file_path = '/cluster/shared/noresm/inputdata/atm/cam/chem/ubc/b.e21.BWHIST.f09_g17.CMIP6-historical-WACCM.ensAvg123.cam.h0zm.H2O.185001-201412_c230509cdf5.nc'

prescribed_ozone_file = "ozone_strataero_WACCM_L70_zm5day_18500101-21010201_CMIP6histEnsAvg_SSP245_c190403.nc"

flbc_file = '/cluster/shared/noresm/inputdata/atm/waccm/lb/LBC_17500116-25001216_CMIP6_SSP585_0p5degLat_h2-ch4-lbc-hyway_c20200824.nc'
EOF

cat > user_nl_clm << EOF
EOF
./case.build