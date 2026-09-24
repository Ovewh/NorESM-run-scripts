#!/bin/bash
# AeroCom Phase 4 control experiment, NFHIST with FATES-NCFB (nor30b24.521)

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
tag="AeroComCTRL"

project="nn2345k"
queue="normal"
wall_clock_time="14:59:00"

start_year=2000
end_year=2023
runStartDate="${start_year}-01-01"
nyears=1
resubmit=$(( end_year - start_year ))   # one job per year

# Provides the AeroCom/COSP diagnostics (user_nl_cam) and appends -cosp to CAM_CONFIG_OPTS
user_mods_dir="/cluster/work/users/ovewh/CAM/cime_config/usermods_dirs/CMIP7_HistoryAerocom"

# No refcase; land initial condition taken from a spun-up N1850 case
land_ic_dir="/cluster/work/users/ovewh/restarts/n1850GaxgGHG.LM.n30b24.517.20260911/1516-01-01-00000"
land_ic=$(ls ${land_ic_dir}/*.clm2.r.*.nc 2>/dev/null | head -n 1)
perror $? "Could not find CLM restart file in ${land_ic_dir}"

nudge_datapath="/cluster/shared/noresm/inputdata/noresm-only/inputForNudging/era5"
nudge_meshfile="/cluster/shared/noresm/inputdata/noresm-only/inputForNudging/era5_UVPS_ESMF_Mesh_cdf5.nc"

# Monthly ERA5 files, one subdirectory per year: era5_UVPS_58levels_YYYY/era5_UVPS_58levels_YYYYMM.nc
nudge_filenames=$(
  for year in $(seq ${start_year} ${end_year}); do
    for month in 01 02 03 04 05 06 07 08 09 10 11 12; do
      printf "                  'era5_UVPS_58levels_%s/era5_UVPS_58levels_%s%s.nc',\n" "${year}" "${year}" "${month}"
    done
  done
)
nudge_filenames=${nudge_filenames%,}

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

./xmlchange NTASKS=-4
./xmlchange RUN_TYPE=startup
./xmlchange RUN_STARTDATE="${runStartDate}"
./xmlchange CALENDAR=GREGORIAN
./xmlchange STOP_OPTION="nyears"
./xmlchange STOP_N="${nyears}"
./xmlchange RESUBMIT="${resubmit}"
./xmlchange GET_REFCASE=FALSE
./xmlchange REST_OPTION="nyears"
./xmlchange REST_N=1
./xmlchange JOB_WALLCLOCK_TIME="${wall_clock_time}" --subgroup case.run
./xmlchange JOB_QUEUE="${queue}" --subgroup case.run
./xmlchange --subgroup case.st_archive JOB_WALLCLOCK_TIME='03:00:00'
./xmlchange --subgroup case.compress JOB_WALLCLOCK_TIME='03:00:00'

./case.setup
perror $? "Problem with case.setup"

# Append: the diagnostics part of user_nl_cam comes from the usermods dir
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
Nudge_end_month = 12
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

# FATES does not support use_init_interp, so finidat must already be on the target grid/surfdata
cat > user_nl_clm << EOF
finidat = '${land_ic}'
fates_history_dimlevel = 1,2
EOF

./case.build
perror $? "Problem with case.build"

./case.submit