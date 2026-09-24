#!/bin/bash
# One-month CAM-Oslo DMS test on two Betzy nodes.

perror(){
  if [ $1 -ne 0 ]; then
    echo "ERROR: $2"
    exit $1
  fi
}

cam_dir="/cluster/work/users/ovewh/CAM"
case_dir="/cluster/work/users/ovewh/cam_cases"

res="ne16pg3_ne16pg3_mtn14"
compset="HIST_CAM70%LT%NORESM%CAMoslo_CLM60%FATES-NCFB%NORESM_CICE%PRES_DOCN%DOM_MOSART_DGLC%NOEVOLVE_SWAV_SESP"
compset_tag="nfhist.LM.nor30b24.521"
tag="AeroComCTRL_DMS_test"

project="nn2345k"
queue="devel"
wall_clock_time="00:59:00"

start_year=2000
end_year=2000
runStartDate="${start_year}-01-01"
nmonths=1
resubmit=0

user_mods_dir="/cluster/work/users/ovewh/CAM/cime_config/usermods_dirs/CMIP7_HistoryAerocom"

land_ic_dir="/cluster/work/users/ovewh/restarts/n1850GaxgGHG.LM.n30b24.517.20260911/1516-01-01-00000"
land_ic=$(ls ${land_ic_dir}/*.clm2.r.*.nc 2>/dev/null | head -n 1)
perror $? "Could not find CLM restart file in ${land_ic_dir}"

nudge_datapath="/cluster/shared/noresm/inputdata/noresm-only/inputForNudging/era5"
nudge_meshfile="/cluster/shared/noresm/inputdata/noresm-only/inputForNudging/era5_UVPS_ESMF_Mesh_cdf5.nc"
nudge_filenames="                  'era5_UVPS_58levels_${start_year}/era5_UVPS_58levels_${start_year}01.nc'"

mkdir -p ${case_dir}
current_date=$(date +%Y%m%d)
case_name="${compset_tag}.${tag}.${current_date}"

echo "Case dir: ${case_dir}/${case_name}"
if [ -e "${case_dir}/${case_name}" ]; then
    echo "${case_name} already exists, exiting"
    exit 1
fi

setup_case() {
    local case_name=$1
    echo "Creating case: ${case_name}"
    ${cam_dir}/cime/scripts/create_newcase \
        --case "${case_dir}/${case_name}" \
        --compset "${compset}" \
        --res "${res}" \
        --mach betzy \
        --compiler intel \
        --project "${project}" \
        --driver nuopc \
        --run-unsupported \
        --user-mods-dirs "${user_mods_dir}"
    perror $? "Problem with creating new case"
}

echo "Setting up case: ${case_name}"
setup_case "${case_name}"

cd ${case_dir}/${case_name} || exit 1

# A negative NTASKS value specifies a number of nodes in CIME.
./xmlchange NTASKS=-2
./xmlchange RUN_TYPE=startup
./xmlchange RUN_STARTDATE="${runStartDate}"
./xmlchange CALENDAR=GREGORIAN
./xmlchange STOP_OPTION="nmonths"
./xmlchange STOP_N="${nmonths}"
./xmlchange RESUBMIT="${resubmit}"
./xmlchange GET_REFCASE=FALSE
./xmlchange REST_OPTION="nmonths"
./xmlchange REST_N=1
./xmlchange JOB_WALLCLOCK_TIME="${wall_clock_time}" --subgroup case.run
./xmlchange JOB_QUEUE="${queue}" --subgroup case.run
./xmlchange --subgroup case.st_archive JOB_WALLCLOCK_TIME="${wall_clock_time}"
./xmlchange --subgroup case.compress JOB_WALLCLOCK_TIME="${wall_clock_time}"

./case.setup
perror $? "Problem with case.setup"

cat >> user_nl_cam << EOF

Nudge_model = .true.
Nudge_Datapath = '${nudge_datapath}'
Nudge_Meshfile = '${nudge_meshfile}'
Nudge_Filenames =
${nudge_filenames}
Nudge_Data_Year_First = ${start_year}
Nudge_Data_Year_Last = ${end_year}
Nudge_Data_taxmode = 'limit'
Nudge_beg_day = 1
Nudge_beg_month = 1
Nudge_beg_year = ${start_year}
Nudge_end_day = 31
Nudge_end_month = 1
Nudge_end_year = ${end_year}
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

dms_source = 'lana'
dms_source_type = 'CYCLICAL'
dms_cycle_year = 2000
ocean_filename = 'dms-hamocc-dow-taylor_chlor_a-lanaclim_NHIST_f19_tn14_20190710_1995-2005_cycle_version20260209.nc'
ocean_filepath = '\$DIN_LOC_ROOT/noresm-only/atm/cam/camoslo'

EOF

cat > user_nl_clm << EOF
finidat = '${land_ic}'
fates_history_dimlevel = 1,2
EOF

./case.build
perror $? "Problem with case.build"

./case.submit
