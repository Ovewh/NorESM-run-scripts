#!/bin/bash
# Land-only FATES-NCFB historical run, 1850-01-01 -> 2000-01-01, forced by
# DATM CRUJRA2024 and LUH3 land use. The 2000-01-01 CLM restart is the land
# initial condition (finidat) for the ERA5-nudged AeroCom control run.
#
#   1850-1900: CRUJRA 1901-1920 cycled (no forcing exists before 1901).
#              Needed so LUH land use evolves from its 1850 state: the
#              starting restart already holds 1850 land use, so FATES will
#              not jump to a later land-use state on its own.
#   1901-1999: transient CRUJRA.
#
# A PRERUN_SCRIPT (written into the case below) switches the DATM years at
# 1901 and cuts each job so that one ends exactly on 1901-01-01 and the last
# ends on 2000-01-01, so the whole run is a single submission.
#
# Usage: ./NorESM3_FATES_DATM_CRUJRA_1850_2000.sh [--no-submit]
#   --no-submit  create and set up the case and preview namelists only

set -u

perror() {
    if [ "$1" -ne 0 ]; then
        echo "ERROR: $2"
        exit "$1"
    fi
}

submit=true
if [ "${1:-}" = "--no-submit" ]; then
    submit=false
fi

# The standalone CAM checkout used by the control run cannot create DATM
# cases. This checkout has the same CTSM source, parameter files and restart
# format (ctsm5.4.042_noresm_v7 vs v4); FATES differs only by the btran/rootr
# weighting fix in EDBtranMod.F90 and extra history fields.
noresm_dir="/cluster/work/users/ovewh/noresm_repo/NorESM"
case_dir="/cluster/work/users/ovewh/cam_cases"

res="ne16pg3_ne16pg3_mtn14"
# CRUJRA2024 (not 2024b): the 2024b forcing on disk lacks 1921-2000.
# %NORESM selects the NorESM CLM/FATES parameter files used by the control run.
compset="HIST_DATM%CRUJRA2024_CLM60%FATES-NCFB%NORESM_SICE_SOCN_SROF_SGLC_SWAV_SESP"
compset_tag="ihist.crujra.fates-ncfb"
tag="AeroComLand1850-2000"

project="nn2345k"
queue="normal"
# ~0.34 h per model year on 9 nodes (beta14 CRUJRA ihist); 17 years ~ 6 h.
nodes=9
years_per_job=17
wall_clock_time="12:00:00"

start_year=1850
transient_year=1901
end_year=2000

# Coupled NorESM3 N1850 restart (1850 land use, FATES-NCFB), also used by the
# control run. FATES does not support init_interp: finidat must be on ne16pg3.
finidat="/cluster/work/users/ovewh/restarts/n1850GaxgGHG.LM.n30b24.517.20260911/1516-01-01-00000/n1850GaxgGHG.LM.n30b24.517.20260911.clm2.r.1516-01-01-00000.nc"

crujra_dir="/cluster/shared/noresm/inputdata/atm/datm7/atm_forcing.datm7.CRUJRA.0.5d.c20241231/three_stream"

if [ ! -r "${finidat}" ]; then
    echo "ERROR: missing finidat: ${finidat}"
    exit 1
fi
missing=0
for year in $(seq "${transient_year}" "$((end_year - 1))"); do
    for stream in Prec Solr TPQWL; do
        file="${crujra_dir}/clmforc.CRUJRAv2.5_0.5x0.5.${stream}.${year}.nc"
        if [ ! -r "${file}" ]; then echo "MISSING: ${file}"; missing=1; fi
    done
done
perror "${missing}" "CRUJRA forcing incomplete in ${crujra_dir}"

jobs_cycle=$(( (transient_year - start_year + years_per_job - 1) / years_per_job ))
jobs_transient=$(( (end_year - transient_year + years_per_job - 1) / years_per_job ))
resubmit=$(( jobs_cycle + jobs_transient - 1 ))

mkdir -p "${case_dir}"
case_name="${compset_tag}.${tag}.$(date +%Y%m%d)"
echo "Case dir: ${case_dir}/${case_name}"
if [ -e "${case_dir}/${case_name}" ]; then
    echo "${case_name} already exists, exiting"
    exit 1
fi

"${noresm_dir}/cime/scripts/create_newcase" \
    --case "${case_dir}/${case_name}" \
    --compset "${compset}" \
    --res "${res}" \
    --mach betzy \
    --compiler intel \
    --project "${project}" \
    --driver nuopc \
    --run-unsupported
perror $? "Problem with creating new case"

cd "${case_dir}/${case_name}" || exit 1

./xmlchange NTASKS=-${nodes}
./xmlchange RUN_TYPE=startup,RUN_STARTDATE="${start_year}-01-01",CALENDAR=GREGORIAN
./xmlchange STOP_OPTION=nyears,STOP_N="${years_per_job}",RESUBMIT="${resubmit}"
./xmlchange REST_OPTION=nyears,REST_N="${years_per_job}"
./xmlchange GET_REFCASE=FALSE
# 1901-1920 cycling to start with; the prerun script raises DATM_YR_END at 1901.
./xmlchange DATM_YR_ALIGN=1901,DATM_YR_START=1901,DATM_YR_END=1920
# The DATM stream restart stores the number of forcing files and aborts if it
# changes, which it does at 1901. DATM restarts only hold stream bookkeeping
# for CLM forcing, so skipping them is safe (CTSM does this in spinups).
./xmlchange DATM_SKIP_RESTART_READ=TRUE
./xmlchange JOB_WALLCLOCK_TIME="${wall_clock_time}" --subgroup case.run
./xmlchange JOB_QUEUE="${queue}" --subgroup case.run
./xmlchange --subgroup case.st_archive JOB_WALLCLOCK_TIME=03:00:00
./xmlchange --subgroup case.compress JOB_WALLCLOCK_TIME=03:00:00

cat > prerun_datm_years.sh << EOF
#!/bin/bash
# Run by case.run (PRERUN_SCRIPT) with the case root as \$1, before the
# namelists are generated. Sets the DATM forcing years and the length of the
# coming job from the model date the job starts at.
set -eu
cd "\$1"

transient_year=${transient_year}
end_year=${end_year}
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

if [ "\${year}" -ge "\${end_year}" ]; then
    echo "ERROR: run already reached \${end_year}"
    exit 1
elif [ "\${year}" -lt "\${transient_year}" ]; then
    datm_yr_end=1920
    boundary=\${transient_year}
else
    datm_yr_end=2023
    boundary=\${end_year}
fi
nyears=\$(( boundary - year ))
if [ "\${nyears}" -gt "\${years_per_job}" ]; then
    nyears=\${years_per_job}
fi

echo "Job starts \${date}: DATM_YR_END=\${datm_yr_end}, STOP_N=\${nyears}"
./xmlchange DATM_YR_END=\${datm_yr_end},STOP_N=\${nyears},REST_N=\${nyears}
EOF
chmod +x prerun_datm_years.sh
./xmlchange PRERUN_SCRIPT="${case_dir}/${case_name}/prerun_datm_years.sh"

./case.setup
perror $? "Problem with case.setup"

# Output is kept to the land state relevant for aerosol emissions: vegetation
# and land use (BVOC, dust), soil moisture and snow (dust). The full default
# FATES output is ~1.6 GB per month at ne16pg3. fates_history_dimlevel(2)=2
# is needed for the land-use-resolved FATES_*_LU fields. MEGAN is diagnostic
# here; its specifier matches CAM-Oslo's so BVOC fluxes compare across stages.
cat > user_nl_clm << EOF
finidat = '${finidat}'
fates_history_dimlevel = 1,2
megan_specifier = 'isoprene = isoprene',
                  'monoterp = myrcene + sabinene + limonene+ carene_3 + ocimene_t_b + pinene_b + pinene_a'
hist_empty_htapes = .true.
hist_fincl1 = 'TLAI', 'TSAI', 'ELAI', 'ESAI', 'HTOP', 'FSNO', 'H2OSNO', 'SNOWDP',
              'H2OSOI', 'SOILWATER_10CM', 'TSOI_10CM', 'TSA', 'RAIN', 'SNOW', 'FSDS',
              'BTRANMN', 'QVEGT', 'QSOIL', 'DSTFLXT', 'LND_FRC_MBLE', 'GWC', 'VAI_OKIN',
              'VOCFLXT', 'MEG_isoprene', 'MEG_pinene_a',
              'FATES_LAI', 'FATES_GPP', 'FATES_NPP', 'FATES_VEGC', 'FATES_FRACTION',
              'FATES_CA_WEIGHTED_HEIGHT', 'FATES_BURNFRAC', 'FATES_NPATCHES', 'FATES_NCOHORTS',
              'FATES_PATCHAREA_LU', 'FATES_VEGC_LU', 'FATES_TRANSITION_MATRIX_LULU',
              'FATES_HARVEST_WOODPROD_C_FLUX', 'FATES_LUCHANGE_WOODPROD_C_FLUX',
              'FATES_NOCOMP_PATCHAREA_PF'
hist_nhtfrq = 0
hist_mfilt = 12
EOF

./preview_namelists
perror $? "Problem with preview_namelists"

if [ "${submit}" = false ]; then
    echo "Case set up without building or submitting: ${case_dir}/${case_name}"
    exit 0
fi

./case.build
perror $? "Problem with case.build"
./case.submit
