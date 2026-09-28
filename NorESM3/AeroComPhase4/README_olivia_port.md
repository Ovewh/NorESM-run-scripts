# Porting the AeroCom CTRL run from Betzy to Olivia

Handover notes for an agent adapting `NorESM3_AeroCom_CTRL_FATES_NCFB.sh`
(in this directory) to run on Olivia. The script is finished and tested on
Betzy; it is being moved only because the Betzy queue is long. Written
2026-09-25.

## Goal and ground rules

Produce an Olivia version of the script that gives the **same simulation**.
Change only machine-specific settings: paths, machine name, queue, task
layout, and wall time. Do not change any of the science settings listed below
without asking the owner (Ove, `oveh@met.no`); each was a deliberate choice.
Ask the owner rather than guessing when something below says "ask".

## What the simulation is

AeroCom Phase 4 control run: CAM-Oslo nudged to ERA5 (U and V only;
temperature and surface pressure are not nudged), with FATES-NCFB land, from
2000-01-01 to 2023-01-01 (model years 2000–2022).

- Compset: `HIST_CAM70%LT%NORESM%CAMoslo_CLM60%FATES-NCFB%NORESM_CICE%PRES_DOCN%DOM_MOSART_DGLC%NOEVOLVE_SWAV_SESP`
- Resolution: `ne16pg3_ne16pg3_mtn14`
- Driver: nuopc; `--run-unsupported`; user mods `CMIP7_HistoryAerocom`
  (AeroCom/COSP output; its `shell_commands` adds `-cosp` to `CAM_CONFIG_OPTS`).

Science settings to keep as they are:

| Setting | Value | Why |
|---|---|---|
| `RUN_TYPE` | `startup`, `RUN_STARTDATE=2000-01-01`, Gregorian calendar | A hybrid run is not possible: the restart set has no `rpointer` files, no MOSART restart, and its CICE restart is on the tn14 ocean grid. |
| CLM `finidat` | `n1850GaxgGHG.LM.nor30b24.525.20260923.clm2.r.1556-01-01-00000.nc` | Only the land starts from the N1850 piControl (#525, year 1556). FATES has no `init_interp`, so this file must be used as is. |
| CLM `fluh_timeseries` | `LUH3_1850_steadystate_ne16np4_c260508.nc` | Land use held at the piControl's 1850 state. The HIST default (transient LUH3) would apply 2000–2022 transitions to an 1850 land-use state. The file has 500 years; later model years reuse the last one (the piControl itself runs at year 1500+). |
| SST/sea ice | `sst_input4MIPs_SSTsAndSeaIce_CMIP_PCMDI-AMIP-1-1-10_gn_187001-202212_c20260924.nc`, `SSTICE_YEAR_ALIGN=START=1870`, `END=2022` | CMIP7 AMIP data to Dec 2022. DOCN cycles the file, so model time past its end silently gets 1870 SSTs; this is why the run stops after 2022. |
| DMS/ocean POM | `ocean_filename = dms-hamocc-dow-taylor_chlor_a-lanaclim_n1850GaxgGHG.LM.n30b24.517.20260911_1496-1525_cycle_version20260924.nc`, `dms_cycle_year = 1850`, `opom_cycle_year = 1850` | Climatology from N1850 #517 by Dirk Olivié. The file is dated 1850, so both cycle years must be 1850. |
| FATES balance check | SourceMod: `EDMainMod.F90` copied to `SourceMods/src.clm/`, limit at line 1040 raised from `10e-6_r8` to `1.0e-4_r8` (the script does this) | Not a namelist option. Under 2000 conditions the check fails right after seedling recruitment at three dry sites on 2000-01-30 (errors 1.2-2.1e-5). |
| Nudging | ERA5 `era5_UVPS_58levels_YYYY/era5_UVPS_58levels_YYYYMM.nc`, 2000–2022 (276 files) | Needs the source change described under "Model code" below. |

Job structure (keep): jobs of 5 model years (5,5,5,5,3; `RESUBMIT=4`),
yearly restarts. A `PRERUN_SCRIPT` that the script writes into the case
(`prerun_stop_n.sh`) shortens the last job, because the driver ignores
`STOP_DATE` when `STOP_OPTION=nyears`. It reads the start date from the
newest `rpointer.cpl.YYYY-MM-DD-SSSSS` in `RUNDIR` and stops with an error
if a job would start after 2022. It uses only `xmlquery` and `xmlchange`, so
it should work unchanged on Olivia.

## Model code

The script builds from NorESM CAM on branch `noresm_aerocom_test` of the
owner's fork, `https://github.com/Ovewh/CAM`, commit `c32ac099`. This commit
includes the nudging file limit raised from 100 to 1000; without it, the 276
nudging files fail at build-namelist with "nudge_filenames has exceeded the
dimension size". It also includes the `CMIP7_HistoryAerocom` user mods and
`oslo_aero_3_0a019`.

```bash
git clone -b noresm_aerocom_test https://github.com/Ovewh/CAM.git CAM
cd CAM && git checkout c32ac099
./bin/git-fleximod update
```

Check the component tags (`git -C <path> describe --tags`). These must match
the tested Betzy build:

| Submodule | Tag |
|---|---|
| `src/chemistry/oslo_aero` | `oslo_aero_3_0a019` |
| `components/clm` | `ctsm5.4.042_noresm_v4` |
| `components/clm/src/fates` | `sci.1.92.5_api.46.0.0_nor_sci7_api2` |
| `components/cdeps` | `cdeps1.0.94_noresm_v1` |
| `components/cice` | `noresm_cice6_6_1_20251129_v2` |
| `components/mosart` | `mosart1.1.12_noresm_v3` |

`cime`, `ccs_config` and `components/cmeps` will come out newer than on
Betzy (`cime6.5.12_noresm_v1`, `ccs_config_noresm0.0.75`,
`cmeps1.1.57_noresm_v5` instead of `cime6.1.173_noresm_v0`,
`ccs_config_noresm0.0.72`, `cmeps1.1.57_noresm_v0`). The owner has accepted
this; keep the `.gitmodules` versions. The Olivia machine details below come
from `ccs_config_noresm0.0.72`, so re-check them in
`ccs_config/machines/olivia/` after cloning.

## What to change for Olivia

From `ccs_config/machines/olivia/` (read from `ccs_config_noresm0.0.72` on Betzy; re-check in your clone):

| Item | Betzy (current script) | Olivia |
|---|---|---|
| `--mach` | `betzy` | `olivia` |
| `--compiler` | `intel` | `intel` is available (MPI libraries `oneapi` or `openmpi`); `gnu` is too. Keep intel unless it fails to build. |
| Cores per node | 128 | 256 (`MAX_MPITASKS_PER_NODE`) |
| `NTASKS` | `-8` = 1024 tasks | `-4` (1024 tasks, the same count). The SE dycore has 1536 elements, so dynamics only speeds up at 768 and 1536 tasks; prefer 3, 4 or 6 Olivia nodes. |
| Queue | `normal` | `large` for 2 or more nodes (`small` = 1 node; `devel` = 1 node, at most 1:59). |
| Max wall time | 96 h | 144 h |
| Input data root | `/cluster/shared/noresm/inputdata` | `/cluster/work/projects/nn9560k/inputdata` (`DIN_LOC_ROOT`) |
| Output root | `/cluster/work/users/ovewh/noresm` | `/cluster/work/projects/$PROJECT/$USER/noresm`; archive in `.../$USER/archive/$CASE` |
| `--project` | `nn2345k` | Ask the owner which account has Olivia CPU hours. |

Hard-coded Betzy paths in the script to replace:

- `cam_dir`, `case_dir`: set to the Olivia locations.
- `user_mods_dir`: currently an absolute Betzy path; use
  `${cam_dir}/cime_config/usermods_dirs/CMIP7_HistoryAerocom`.
- `land_ic`, `fluh_timeseries`, `sstice_file`, `nudge_datapath`,
  `nudge_meshfile`: see the next section. (`ocean_filepath` already uses
  `$DIN_LOC_ROOT` and is portable.)

## Input files: check Olivia first, copy only what is missing

Verify each file on Olivia by size (and md5 where given) before using it.

| File | Betzy path | Size (bytes) | Olivia |
|---|---|---|---|
| CLM restart | `/cluster/work/users/ovewh/restarts/n1850GaxgGHG.LM.nor30b24.525.20260923/1556-01-01-00000/…clm2.r.1556-01-01-00000.nc` | 20408917722 | Run #525 was made on Olivia by `adagj`; the original is probably in their archive (`…/adagj/archive/n1850GaxgGHG.LM.nor30b24.525.20260923/rest/1556-01-01-00000/`). Otherwise copy it from Betzy. |
| LUH 1850 steady state | `$DIN/lnd/clm2/surfdata_esmf/ctsm5.4.0/fates_LU_data_CMIP7/LUH3_1850_steadystate_ne16np4_c260508.nc` | 10617084544 | Very likely present; the piControl uses it. |
| AMIP SST | `$DIN/atm/cam/sst/sst_input4MIPs_SSTsAndSeaIce_CMIP_PCMDI-AMIP-1-1-10_gn_187001-202212_c20260924.nc` | 1903599916, md5 `45f946189d7828784d7818306ca687c3` | New (made 2026-09-24 by mvertens); may be missing. |
| SST mesh | `$DIN/atm/cam/sst/sst_HadOIBl_bc_1x1_clim_c101029_ESMFmesh_120520.nc` | 4154168 | Default file; likely present. Same 1x1 grid as the AMIP file. |
| DMS/OPOM climatology | `$DIN/noresm-only/atm/cam/camoslo/dms-hamocc-dow-taylor_chlor_a-lanaclim_n1850GaxgGHG.LM.n30b24.517.20260911_1496-1525_cycle_version20260924.nc` | 1328996, md5 `77699e3fda8c3eeda8736606bb9322e6` | Dirk confirmed it is on Olivia at `/cluster/work/projects/nn9560k/inputdata/noresm-only/atm/cam/camoslo/`. |
| ERA5 nudging mesh | `$DIN/noresm-only/inputForNudging/era5_UVPS_ESMF_Mesh_cdf5.nc` | 7065332 | Check. |
| ERA5 nudging data | `$DIN/noresm-only/inputForNudging/era5/era5_UVPS_58levels_{2000..2022}/` (12 monthly files per year) | **3.2 TB in total** | Check first. If it is missing, ask the owner before transferring. The first job needs only 2000–2004, so the rest can be copied while the run is going. |

(`$DIN` is `/cluster/shared/noresm/inputdata` on Betzy and
`/cluster/work/projects/nn9560k/inputdata` on Olivia.)

After `case.setup`, run `./check_input_data` in the case to list any other
missing default inputs (such as CMIP7 emissions on ne16pg3, `version20260209`),
and copy them from the same relative path under `$DIN` on Betzy.

## Suggested order of work

1. Clone the CAM branch and check that the submodule tags match (see "Model
   code").
2. Make an Olivia copy of the script (for example
   `NorESM3_AeroCom_CTRL_FATES_NCFB_olivia.sh`) with the machine changes above.
   Consider adding a `--no-submit` option that stops after `preview_namelists`,
   as in `NorESM3_FATES_DATM_CRUJRA_1850_2000.sh`.
3. Set up the case without building and check the generated files in
   `CaseDocs/`:
   - `lnd_in`: `finidat` (the 1556 restart), `fluh_timeseries` (the 1850
     steady-state file), `use_fates_luh = .true.`,
     `fates_harvest_mode = 'luhdata_area'`.
   - `atm_in`: `dms_cycle_year = 1850`, `opom_cycle_year = 1850`, the new
     `ocean_filename`, 276 nudging files ending `…202212.nc`.
   - `docn.streams.xml` and `ice_in`: the AMIP file, years 1870–2022,
     `year_align` 1870.
   - `./xmlquery STOP_N,RESUBMIT,PRERUN_SCRIPT,JOB_WALLCLOCK_TIME`: 5, 4,
     the case's `prerun_stop_n.sh`, and your wall time.
4. Run a short test first: a copy of the case with `STOP_OPTION=nmonths`,
   `STOP_N=1`, `RESUBMIT=0`, `PRERUN_SCRIPT` unset (the hook assumes year-long
   jobs), and nudging files for January 2000 only. Use the `devel` queue with
   `NTASKS=-1`, or 2 nodes on `large`.
   `NorESM3_AeroCom_CTRL_FATES_NCFB_DMS_test.sh` is the Betzy version of this
   test. Measure model days per wall hour.
5. Set `wall_clock_time` from the measured throughput: 5 model years plus
   about 30% margin, at most 144 h. On Betzy, the 1-month test on 4 nodes
   (512 tasks) ran at 68.1 s per model day (6.9 h per model year); the Betzy
   script uses 32 h for 5 years on 8 nodes (an estimate, not yet measured).
6. Build and submit the full run. Report to the owner: case name, number of
   nodes, measured throughput, and anything you changed beyond this list.

## Known pitfalls

- An old case directory `nfhist.LM.nor30b24.521.AeroComCTRL.20260923` on
  Betzy predates the DMS, SST and LUH settings. Do not copy or reuse it.
- `perror $?` after a pipeline tests the last command in the pipeline; check
  files with `[ -r file ]` instead, as the script now does.
- Do not start from the older `n1850GaxgGHG.LM.n30b24.517.20260911` 1516
  restart; the owner chose the #525 1556 restart.
- If `fluh_timeseries` is left at the HIST default (transient
  `LUH3_timeseries_850-2024…`), FATES tries to move the restart's 1850 land
  use to the year-2000 state in one day. The log shows "See luc mortalities"
  values above 1, then the run crashes within minutes at
  `EDPatchDynamicsMod.F90` line 1667 ("Buffer patch still has area"; Betzy job
  1747058). The 1850 steady-state file avoids this.
  `NorESM3_AeroCom_CTRL_FATES_NCFB_DMS_test.sh` uses the same land and SST
  settings as the CTRL script.
- The CRUJRA land-only script in this directory
  (`NorESM3_FATES_DATM_CRUJRA_1850_2000.sh`) is a separate, optional workflow
  for a present-day land state. It is not part of this task.
