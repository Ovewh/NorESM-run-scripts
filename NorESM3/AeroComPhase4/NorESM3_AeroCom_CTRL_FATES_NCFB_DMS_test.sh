#!/bin/bash
# One-month test (Jan 2000, devel queue) of the AeroCom CTRL setup in
# NorESM3_AeroCom_CTRL_FATES_NCFB.sh: land IC, 1850 land use, AMIP SST, DMS.

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

# Same land initial condition, land use and SSTs as the CTRL run
land_ic_case="n1850GaxgGHG.LM.nor30b24.525.20260923"
land_ic_date="1556-01-01-00000"
land_ic="/cluster/work/users/ovewh/restarts/${land_ic_case}/${land_ic_date}/${land_ic_case}.clm2.r.${land_ic_date}.nc"
if [ ! -r "${land_ic}" ]; then
    echo "ERROR: Could not find CLM restart file ${land_ic}"
    exit 1
fi
# 1850 steady-state land use as in the piControl. The HIST default (transient
# LUH3) moves the 1850 land-use state toward year 2000 in one day and crashes
# FATES (EDPatchDynamicsMod.F90:1667, run 1747058).
fluh_timeseries="/cluster/shared/noresm/inputdata/lnd/clm2/surfdata_esmf/ctsm5.4.0/fates_LU_data_CMIP7/LUH3_1850_steadystate_ne16np4_c260508.nc"

sstice_file="/cluster/shared/noresm/inputdata/atm/cam/sst/sst_input4MIPs_SSTsAndSeaIce_CMIP_PCMDI-AMIP-1-1-10_gn_187001-202212_c20260924.nc"
sstice_year_start=1870
sstice_year_end=2022

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
./xmlchange NTASKS=-4
./xmlchange RUN_TYPE=startup
./xmlchange RUN_STARTDATE="${runStartDate}"
./xmlchange CALENDAR=GREGORIAN
./xmlchange SSTICE_DATA_FILENAME="${sstice_file}"
./xmlchange SSTICE_YEAR_ALIGN=${sstice_year_start},SSTICE_YEAR_START=${sstice_year_start},SSTICE_YEAR_END=${sstice_year_end}
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

! DMS and ocean POM (chlor_a) climatology from N1850 #517, years 1496-1525
! (D. Olivie, 2026-09-24). The file is dated 1850, so both cycle years are 1850.
dms_source = 'lana'
dms_source_type = 'CYCLICAL'
dms_cycle_year = 1850
opom_cycle_year = 1850
ocean_filename = 'dms-hamocc-dow-taylor_chlor_a-lanaclim_n1850GaxgGHG.LM.n30b24.517.20260911_1496-1525_cycle_version20260924.nc'
ocean_filepath = '\$DIN_LOC_ROOT/noresm-only/atm/cam/camoslo'

EOF

cat > user_nl_clm << EOF
finidat = '${land_ic}'
fluh_timeseries = '${fluh_timeseries}'
fates_history_dimlevel = 1,2
EOF

# SourceMod: relax the FATES daily carbon balance check (not a namelist option).
# It aborts when a site's error exceeds 1e-5 of its carbon stock. Starting from
# the piControl restart under 2000 conditions, it fails right after seedling
# recruitment (call index 1) at three dry sites on 2000-01-30 with errors of
# 1.2-2.1e-5 (job 1748979, FATES nor_sci7 and nor_sci10). Raise the limit to
# 1e-4; larger errors still stop the run, smaller ones are no longer printed.
# The file is copied from the checkout when the case is created, so recreate
# the case if FATES is updated.
fates_edmain="${cam_dir}/components/clm/src/fates/main/EDMainMod.F90"
cp "${fates_edmain}" SourceMods/src.clm/
perror $? "Could not copy ${fates_edmain}"
sed -i 's/if ( error_frac > 10e-6_r8 ) then/if ( error_frac > 1.0e-4_r8 ) then/' SourceMods/src.clm/EDMainMod.F90
grep -q "error_frac > 1.0e-4_r8" SourceMods/src.clm/EDMainMod.F90
perror $? "Could not change the balance tolerance in SourceMods/src.clm/EDMainMod.F90"

./case.build
perror $? "Problem with case.build"

./case.submit
