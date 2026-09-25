#!/bin/bash
# AeroCom Phase 4 control experiment, NFHIST with FATES-NCFB (nor30b24.521),
# ERA5-nudged 2000-2022, land from the N1850 piControl with 1850 land use.

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
# ~7.5-9 h per model year on 4 nodes (2-node DMS test: ~14.6 h/yr); max 96 h
wall_clock_time="60:00:00"

start_year=2000
end_year=2022   # last year with AMIP SSTs (see sstice_file)
runStartDate="${start_year}-01-01"
# Jobs of years_per_job years (5,5,5,5,3): the prerun script below shortens the last job
# so the run ends on $((end_year + 1))-01-01 (STOP_DATE is ignored with nyears).
years_per_job=5
nyears_total=$(( end_year - start_year + 1 ))
resubmit=$(( (nyears_total + years_per_job - 1) / years_per_job - 1 ))

# Provides the AeroCom/COSP diagnostics (user_nl_cam) and appends -cosp to CAM_CONFIG_OPTS
user_mods_dir="/cluster/work/users/ovewh/CAM/cime_config/usermods_dirs/CMIP7_HistoryAerocom"

# Startup run; only the land starts from the spun-up N1850 piControl. A hybrid
# run from this case is not practical: the restart set has no rpointer files
# (needed to stage a refcase) and no MOSART restart, and its CICE restart is on
# the tn14 ocean grid while the ice here runs on ne16pg3.
land_ic_case="n1850GaxgGHG.LM.nor30b24.525.20260923"
land_ic_date="1556-01-01-00000"
land_ic="/cluster/work/users/ovewh/restarts/${land_ic_case}/${land_ic_date}/${land_ic_case}.clm2.r.${land_ic_date}.nc"
if [ ! -r "${land_ic}" ]; then
    echo "ERROR: Could not find CLM restart file ${land_ic}"
    exit 1
fi

# Land use is held at the piControl's 1850 steady state (as in the N1850 spin-up)
# instead of the transient LUH3 default for HIST, which would apply 2000-2022
# transition rates to the 1850 land-use state in the restart.
fluh_timeseries="/cluster/shared/noresm/inputdata/lnd/clm2/surfdata_esmf/ctsm5.4.0/fates_LU_data_CMIP7/LUH3_1850_steadystate_ne16np4_c260508.nc"

# CMIP7 AMIP SST/sea ice (PCMDI-AMIP-1-1-10), Jan 1870 - Dec 2022, on the same
# 1x1 grid as the default HadOIBl file, which ends in Dec 2021. The DOCN stream
# cycles, so model dates past the file end would get 1870 SSTs.
sstice_file="/cluster/shared/noresm/inputdata/atm/cam/sst/sst_input4MIPs_SSTsAndSeaIce_CMIP_PCMDI-AMIP-1-1-10_gn_187001-202212_c20260924.nc"
sstice_year_start=1870
sstice_year_end=2022

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
./xmlchange SSTICE_DATA_FILENAME="${sstice_file}"
./xmlchange SSTICE_YEAR_ALIGN=${sstice_year_start},SSTICE_YEAR_START=${sstice_year_start},SSTICE_YEAR_END=${sstice_year_end}
./xmlchange STOP_OPTION="nyears"
./xmlchange STOP_N="${years_per_job}"
./xmlchange RESUBMIT="${resubmit}"
./xmlchange GET_REFCASE=FALSE
# Yearly restarts, so a failed job loses at most one year
./xmlchange REST_OPTION="nyears"
./xmlchange REST_N=1
./xmlchange JOB_WALLCLOCK_TIME="${wall_clock_time}" --subgroup case.run
./xmlchange JOB_QUEUE="${queue}" --subgroup case.run
./xmlchange --subgroup case.st_archive JOB_WALLCLOCK_TIME='03:00:00'
./xmlchange --subgroup case.compress JOB_WALLCLOCK_TIME='03:00:00'

cat > prerun_stop_n.sh << EOF
#!/bin/bash
# Run by case.run (PRERUN_SCRIPT) with the case root as \$1, before the
# namelists are generated. Shortens the coming job so the run stops on
# $((end_year + 1))-01-01.
set -eu
cd "\$1"

stop_year=$((end_year + 1))
years_per_job=${years_per_job}

if [ "\$(./xmlquery --value CONTINUE_RUN)" = "TRUE" ]; then
    rundir=\$(./xmlquery --value RUNDIR)
    rpointer=\$(ls "\${rundir}"/rpointer.cpl.* | sort | tail -n 1)
    date=\${rpointer##*rpointer.cpl.}
else
    date="\$(./xmlquery --value RUN_STARTDATE)-00000"
fi
if [ "\${date#*-}" != "01-01-00000" ]; then
    echo "ERROR: job does not start on 1 January: \${date}"
    exit 1
fi
year=\$((10#\${date%%-*}))

if [ "\${year}" -ge "\${stop_year}" ]; then
    echo "ERROR: run already reached \${stop_year}"
    exit 1
fi
nyears=\$(( stop_year - year ))
if [ "\${nyears}" -gt "\${years_per_job}" ]; then
    nyears=\${years_per_job}
fi

echo "Job starts \${date}: STOP_N=\${nyears}"
./xmlchange STOP_N=\${nyears}
EOF
chmod +x prerun_stop_n.sh
./xmlchange PRERUN_SCRIPT="${case_dir}/${case_name}/prerun_stop_n.sh"

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

! DMS and ocean POM (chlor_a) climatology from N1850 #517, years 1496-1525
! (D. Olivie, 2026-09-24). The file is dated 1850, so both cycle years are 1850.
dms_source = 'lana'
dms_source_type = 'CYCLICAL'
dms_cycle_year = 1850
opom_cycle_year = 1850
ocean_filename = 'dms-hamocc-dow-taylor_chlor_a-lanaclim_n1850GaxgGHG.LM.n30b24.517.20260911_1496-1525_cycle_version20260924.nc'
ocean_filepath = '\$DIN_LOC_ROOT/noresm-only/atm/cam/camoslo'

EOF

# FATES does not support use_init_interp, so finidat must already be on the target grid/surfdata
cat > user_nl_clm << EOF
finidat = '${land_ic}'
fluh_timeseries = '${fluh_timeseries}'
fates_history_dimlevel = 1,2
EOF

./case.build
perror $? "Problem with case.build"

./case.submit