-- Master install script for UFKBRD VOK datamart
-- Target: PostgreSQL 9.4.26 / Greenplum 6.22
-- Usage: psql -f sql/00_install_all.sql

\ir 00_schemas/00_create_schemas.sql
\ir 01_ods/01_ods_nsi_excel.sql
\ir 01_ods/02_ods_sap.sql
\ir 01_ods/03_ods_arm_mtr_bdds.sql
\ir 02_dm/ref/01_ref_tables.sql
\ir 02_dm/stg/01_stg_tables.sql
\ir 02_dm/mart/01_mart_tables.sql
\ir 02_dm/functions/00_utils.sql
\ir 02_dm/functions/01_fn_load_refs.sql
\ir 02_dm/functions/02_fn_transform_advances.sql
\ir 02_dm/functions/03_fn_transform_sap.sql
\ir 02_dm/functions/04_fn_transform_arm_mtr.sql
\ir 02_dm/functions/05_fn_precalc_common.sql
\ir 02_dm/functions/06_fn_precalc_bdds.sql
\ir 02_dm/functions/07_fn_precalc_vok_uo.sql
\ir 02_dm/functions/08_fn_precalc_reserves.sql
\ir 02_dm/functions/09_fn_precalc_forecast_advances.sql
\ir 02_dm/functions/10_fn_precalc_forecast_ar_ap_mtr.sql
\ir 03_orchestrate/00_run_pipeline.sql

SELECT 'UFKBRD VOK SQL objects installed' AS status;
