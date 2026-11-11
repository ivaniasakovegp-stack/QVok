-- 01-01 Extract XLS master -> ref / stg tables

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_load_refs()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_year integer := dm_ufkbrd.fn_dashboard_year();
    v_today date := dm_ufkbrd.fn_as_of_date();
    v_start date;
    v_end date;
BEGIN
    v_start := make_date(v_year, 1, 1);
    v_end := dm_ufkbrd.fn_year_end(v_today);

    -- DO / SP list: Prirazlomnoe -> Shelf
    TRUNCATE TABLE dm_ufkbrd.ref_do_vok;
    INSERT INTO dm_ufkbrd.ref_do_vok (
        corr_type, sap_number, be_code, ifrs_code, do_type, do_sp_flag,
        flag_vok, flag_reserves, flag_bdds, flag_mtr, flag_nzs,
        do_arm_kk, vok_kpd_tab, do_atlas, do_atlas_2, do_atlas_3,
        do_short_name, do_full_name
    )
    SELECT DISTINCT
        corr_type,
        sap_number,
        be_code,
        ifrs_code_mvd0o0o,
        do_type,
        do_sp_flag,
        flag_vok,
        flag_reserves,
        flag_bdds,
        flag_mtr,
        flag_nzs,
        do_arm_kk,
        vok_kpd_tab,
        do_atlas,
        do_atlas_2,
        do_atlas_3,
        CASE WHEN do_short_name = 'Приразломное' THEN 'Шельф' ELSE do_short_name END,
        CASE WHEN do_full_name = 'ГПН-Приразломное' THEN 'ГПН-Шельф' ELSE do_full_name END
    FROM ods.nsi_do_sp
    WHERE block_name = 'БРД';

    -- Multi-alias DO name map
    TRUNCATE TABLE dm_ufkbrd.ref_do_name_map;
    INSERT INTO dm_ufkbrd.ref_do_name_map (src_name, do_short_name)
    SELECT DISTINCT do_full_name, do_short_name FROM dm_ufkbrd.ref_do_vok WHERE do_full_name IS NOT NULL AND do_full_name <> ''
    UNION
    SELECT DISTINCT do_atlas, do_short_name FROM dm_ufkbrd.ref_do_vok WHERE do_atlas IS NOT NULL AND do_atlas <> ''
    UNION
    SELECT DISTINCT do_atlas_2, do_short_name FROM dm_ufkbrd.ref_do_vok WHERE do_atlas_2 IS NOT NULL AND do_atlas_2 <> ''
    UNION
    SELECT DISTINCT do_atlas_3, do_short_name FROM dm_ufkbrd.ref_do_vok WHERE do_atlas_3 IS NOT NULL AND do_atlas_3 <> ''
    UNION
    SELECT DISTINCT legal_entity_name, do_short_name FROM ods.nsi_do_short_atlas;

    -- VGO counterparties with leading zeros
    TRUNCATE TABLE dm_ufkbrd.ref_vgo_counterparties;
    INSERT INTO dm_ufkbrd.ref_vgo_counterparties (counterparty_number, do_full_name, transfer_to_sp_dt)
    SELECT DISTINCT
        dm_ufkbrd.fn_pad10(counterparty_number),
        do_full_name,
        transfer_to_sp_dt
    FROM ods.nsi_do_oe_ka;

    TRUNCATE TABLE dm_ufkbrd.ref_oa_types;
    INSERT INTO dm_ufkbrd.ref_oa_types (account_name_as_is, valuation_type_to_be)
    SELECT account_name_as_is, valuation_type_to_be FROM ods.nsi_oa_types;

    -- KPI DD / URO unpivoted months
    TRUNCATE TABLE dm_ufkbrd.stg_kpi_dd;
    INSERT INTO dm_ufkbrd.stg_kpi_dd (be_code, period_dt, amount)
    SELECT
        k.be_code,
        dm_ufkbrd.fn_month_end(make_date(k.year_num, m.month_num, 1)),
        round(k.amount_mln, 3)
    FROM ods.nsi_kpi_dd k
    JOIN dm_ufkbrd.ref_month_map m ON lower(m.month_code) = lower(k.month_code);

    TRUNCATE TABLE dm_ufkbrd.stg_kpi_uro;
    INSERT INTO dm_ufkbrd.stg_kpi_uro (be_code, period_dt, amount)
    SELECT
        k.be_code,
        dm_ufkbrd.fn_month_end(make_date(k.year_num, m.month_num, 1)),
        round(k.amount_mln, 3)
    FROM ods.nsi_kpi_uro k
    JOIN dm_ufkbrd.ref_month_map m ON lower(m.month_code) = lower(k.month_code);

    -- Period calendar
    TRUNCATE TABLE dm_ufkbrd.ref_periods;
    INSERT INTO dm_ufkbrd.ref_periods (year_num, period_dt)
    SELECT DISTINCT
        EXTRACT(YEAR FROM d)::integer,
        dm_ufkbrd.fn_month_end(d)
    FROM generate_series(v_start, v_end, '1 day'::interval) gs(d);

    -- Atlas advances: finance vs utilization
    TRUNCATE TABLE dm_ufkbrd.stg_atlas_advances;
    INSERT INTO dm_ufkbrd.stg_atlas_advances (
        scenario_name, year_num, oe_name, do_name, do_name_src, capex_opex,
        kp_name, contractor_name, inn, contracting_status, contract_number,
        advance_full_repay_term, bg_flag, other_security, advance_category,
        advance_type, justification, flow_flag, planned_issue_rub, planned_repay_rub, period_dt
    )
    SELECT
        r.scenario_name,
        r.year_num,
        r.oe_name,
        r.do_full_name,
        r.do_name_src,
        CASE WHEN upper(r.capex_opex) IN ('САРЕХ', 'CAPEX') THEN 'САРЕХ' ELSE r.capex_opex END,
        coalesce(r.kp_name, 'Не указано'),
        r.contractor_name,
        r.inn,
        r.contracting_status,
        r.contract_number,
        coalesce(r.advance_full_repay_term, 'Не указано'),
        coalesce(r.bg_flag, 'Не указано'),
        coalesce(r.other_security, 'Не указано'),
        r.advance_category,
        coalesce(r.advance_type, 'Не указано'),
        r.justification,
        CASE WHEN r.period_label LIKE '%фин' THEN 'Финансирование' ELSE 'Освоение' END,
        CASE WHEN r.period_label LIKE '%фин' THEN r.amount * 1000000 ELSE 0 END,
        CASE WHEN r.period_label LIKE '%осв' THEN r.amount * 1000000 ELSE 0 END,
        dm_ufkbrd.fn_month_end(
            make_date(
                r.year_num,
                coalesce((
                    SELECT mm.month_num
                    FROM dm_ufkbrd.ref_month_map mm
                    WHERE lower(mm.month_code) = lower(left(replace(replace(r.period_label, ' фин', ''), ' осв', ''), 3))
                    LIMIT 1
                ), 1),
                1
            )
        )
    FROM ods.nsi_atlas_advances_raw r
    WHERE coalesce(r.amount, 0) <> 0;

END;
$$;
