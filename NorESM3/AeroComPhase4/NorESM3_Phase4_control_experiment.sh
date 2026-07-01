paths_noresm="/cluster/projects/nn2345k/ovewh/"

perror(){
  if [ $1 -ne 0 ]; then
    echo "ERROR: $2"
    exit $1
  fi
}

noresm_dir_name="CAM-PPE"
runStartDate="2016-12-01"
res="ne16pg3_ne16pg3_mtn14"
compset="HIST_CAM70%LT%NORESM%CAMoslo_CLM60%SP_CICE%PRES_DOCN%DOM_MOSART_DGLC%NOEVOLVE_SWAV_SESP" 
wall_clock_time="14:59:00"
queue="normal"
user_mods_dir="/cluster/projects/nn2345k/ovewh/CAM-PPE/cime_config/usermods_dirs/AEROCOM_Phase4/"
tag="aerocomSP"
nmonths=13
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
    create_newcase --mach betzy --case "${case_dir}/${case_name}" --compset "${compset}" --res "${res}" --project "${project}" --compiler "intel" --driver nuopc --run-unsupported --user-mods-dirs ${user_mods_dir}
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
./xmlchange REST_OPTION=never
./case.setup

./case.build

./case.submit