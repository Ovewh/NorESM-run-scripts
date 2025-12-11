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
ndays=15
resubmit=0
project="nn2345k"
runStartDate="0001-01-01"
res="ne16pg3_ne16pg3_mtn14"
compset="1850_CAM70%LT%NORESM%CAMoslo_CLM60%SP_CICE%PRES_DOCN%DOM_MOSART_DGLC%NOEVOLVE_SWAV_SESP"
wall_clock_time="00:59:00"
queue="devel"
tag="noresm_beta07_freerun_ref"
compset_tag="NF1850"
case_dir="/cluster/projects/nn2345k/ovewh/Nudging_verifcation"

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
./xmlchange STOP_OPTION="ndays"
./xmlchange --subgroup case.st_archive JOB_WALLCLOCK_TIME='00:45:00'
./xmlchange STOP_N="${ndays}"
./xmlchange RUN_STARTDATE="${runStartDate}"
./xmlchange RUN_TYPE=startup
./xmlchange CALENDAR=NO_LEAP
./xmlchange JOB_WALLCLOCK_TIME="${wall_clock_time}" --subgroup case.run
./xmlchange JOB_QUEUE="${queue}" --subgroup case.run
./case.setup
perror $? "Problem with case.setup"
echo "Setting up namelists"

cat > user_nl_cam << EOF

empty_htapes=.true.
nhtfrq = 0, -6, -1,
mfilt  = 1,  28, 168,
ndens  = 2,  2,  2,
fincl2 = 'PS:I','U:I','V:I','T:I','Q:I'
fincl3 = 'PS:I','U:I','V:I','T:I','Q:I','U850:I','V850:I','T850:I','Z500:I'
fincl3lonlat = '11e_60n'

zmconv_c0_lnd		= 0.0075D0
zmconv_c0_ocn		= 0.0075D0
zmconv_ke               =  5.0E-6
zmconv_ke_lnd           =  1.0E-5
dust_emis_fact = 6.1D0
clim_modal_aero_top_press = 1.D-4
micro_mg_dcs               = 700.D-6
clubb_c8                   =  5.0D0
EOF

perror $? "Problem with writing user_nl_cam"

cd ${case_dir}/${case_name}
./preview_namelists
perror $? "Problem with preview_namelists"
./case.build  
perror $? "Problem with case.build"
echo "Case setup complete: ${case_name}"
./case.submit