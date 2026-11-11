-- Orchestration: full UFKBRD VOK rebuild for Greenplum 6.22 / PostgreSQL 9.4.26
-- Set parameters before run:
--   UPDATE dm_ufkbrd.pipeline_params SET param_value = '2022' WHERE param_name = 'dashboard_year';
--   UPDATE dm_ufkbrd.pipeline_params SET param_value = to_char(current_date,'YYYY-MM-DD') WHERE param_name = 'as_of_date';

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_run_pipeline()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    -- 01 Extract XLS master -> refs/stg
    PERFORM dm_ufkbrd.fn_load_refs();

    -- 02 Transforms
    PERFORM dm_ufkbrd.fn_transform_advances();
    PERFORM dm_ufkbrd.fn_transform_zgrccp410();
    PERFORM dm_ufkbrd.fn_transform_zkhdcp050();
    PERFORM dm_ufkbrd.fn_transform_arm_kk();
    PERFORM dm_ufkbrd.fn_transform_mtr();

    -- 03 PreCalc
    PERFORM dm_ufkbrd.fn_precalc_mtr_involvement_year();
    PERFORM dm_ufkbrd.fn_precalc_reserves();          -- calendar needed for factoring cumulative
    PERFORM dm_ufkbrd.fn_precalc_ap_factoring();
    PERFORM dm_ufkbrd.fn_precalc_kpd();
    PERFORM dm_ufkbrd.fn_precalc_bdds();
    PERFORM dm_ufkbrd.fn_precalc_vok_uo();
    PERFORM dm_ufkbrd.fn_precalc_forecast_advances();
    PERFORM dm_ufkbrd.fn_precalc_forecast_ar();
    PERFORM dm_ufkbrd.fn_precalc_forecast_ap();
    PERFORM dm_ufkbrd.fn_precalc_forecast_mtr();
END;
$$;

COMMENT ON FUNCTION dm_ufkbrd.fn_run_pipeline() IS
'Rebuilds dm_ufkbrd marts from ods.* sources. Equivalent of Qlik extract/transform/precalc chain for UFKBRD VOK.';
