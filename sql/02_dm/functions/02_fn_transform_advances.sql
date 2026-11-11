-- 02-01 Transform XLS advances forecast

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_transform_advances()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE dm_ufkbrd.stg_advances_forecast;

    -- Historical Excel path: 2024 scenario 0+12
    INSERT INTO dm_ufkbrd.stg_advances_forecast (
        scenario_name, year_num, do_name, do_name_src, capex_opex, kp_name,
        contractor_name, inn, contracting_status, contract_number,
        advance_full_repay_term, bg_flag, other_security, advance_category,
        advance_type, justification, flow_flag, planned_issue_rub, planned_repay_rub, period_dt
    )
    SELECT
        h.scenario_name,
        h.year_num,
        coalesce(m.do_short_name, h.do_full_name),
        h.do_full_name,
        CASE WHEN upper(h.capex_opex) IN ('САРЕХ', 'CAPEX') THEN 'САРЕХ' ELSE h.capex_opex END,
        h.kp_name,
        h.contractor_name,
        h.inn,
        h.contracting_status,
        CASE
            WHEN h.contract_number LIKE '%7282/02 от 09.10.2020%' THEN '7282/02 от 09.10.2020 года'
            ELSE ltrim(h.contract_number)
        END,
        h.advance_full_repay_term,
        coalesce(bg.tgt_value, 'Не указано'),
        h.other_security,
        h.advance_category,
        h.advance_type,
        h.justification,
        NULL,
        h.planned_issue_rub,
        h.planned_repay_rub,
        dm_ufkbrd.fn_month_end(h.period_dt)
    FROM ods.atlas_advances_hist h
    LEFT JOIN dm_ufkbrd.ref_do_name_map m ON m.src_name = h.do_full_name
    LEFT JOIN dm_ufkbrd.ref_bg_flag_map bg ON bg.src_value = h.bg_flag
    WHERE h.year_num = 2024 AND h.scenario_name = '0+12';

    -- Atlas Excel extract (current)
    INSERT INTO dm_ufkbrd.stg_advances_forecast (
        scenario_name, year_num, do_name, do_name_src, capex_opex, kp_name,
        contractor_name, inn, contracting_status, contract_number,
        advance_full_repay_term, bg_flag, other_security, advance_category,
        advance_type, justification, flow_flag, planned_issue_rub, planned_repay_rub, period_dt
    )
    SELECT
        a.scenario_name,
        a.year_num,
        CASE
            WHEN a.do_name_src LIKE 'ОАО Славнефть-Мегионнефтегаз%'
                 AND a.oe_name = 'ОЕ СН-Мегионнефтегаз' THEN 'Мегион'
            WHEN a.do_name_src LIKE 'ОАО Славнефть-Мегионнефтегаз%'
                 AND a.oe_name = 'ОЕ МУБР' THEN 'МУБР'
            ELSE coalesce(m.do_short_name, a.do_name)
        END,
        a.do_name_src,
        a.capex_opex,
        a.kp_name,
        a.contractor_name,
        a.inn,
        a.contracting_status,
        a.contract_number,
        a.advance_full_repay_term,
        a.bg_flag,
        a.other_security,
        a.advance_category,
        a.advance_type,
        a.justification,
        a.flow_flag,
        a.planned_issue_rub,
        a.planned_repay_rub,
        a.period_dt
    FROM dm_ufkbrd.stg_atlas_advances a
    LEFT JOIN dm_ufkbrd.ref_do_name_map m ON m.src_name = a.do_name;

    -- Dense fill of zero-ish placeholders across same-year dates (Qlik Cartesian join)
    -- Keep original rows; add cross-period stubs with 0.1 for missing dates of same year
    INSERT INTO dm_ufkbrd.stg_advances_forecast (
        scenario_name, year_num, do_name, do_name_src, capex_opex, kp_name,
        contractor_name, inn, contracting_status, contract_number,
        advance_full_repay_term, bg_flag, other_security, advance_category,
        advance_type, justification, flow_flag, planned_issue_rub, planned_repay_rub, period_dt
    )
    SELECT
        f.scenario_name,
        f.year_num,
        f.do_name,
        f.do_name_src,
        f.capex_opex,
        f.kp_name,
        f.contractor_name,
        f.inn,
        f.contracting_status,
        f.contract_number,
        f.advance_full_repay_term,
        f.bg_flag,
        f.other_security,
        f.advance_category,
        f.advance_type,
        f.justification,
        f.flow_flag,
        0.1,
        0.1,
        d.period_dt
    FROM dm_ufkbrd.stg_advances_forecast f
    JOIN (
        SELECT DISTINCT year_num, period_dt FROM dm_ufkbrd.stg_advances_forecast
    ) d ON d.year_num = f.year_num AND d.period_dt <> f.period_dt
    WHERE NOT EXISTS (
        SELECT 1
        FROM dm_ufkbrd.stg_advances_forecast x
        WHERE x.scenario_name = f.scenario_name
          AND x.year_num = f.year_num
          AND x.do_name = f.do_name
          AND coalesce(x.contract_number,'') = coalesce(f.contract_number,'')
          AND coalesce(x.inn,'') = coalesce(f.inn,'')
          AND x.period_dt = d.period_dt
    );

    -- Fact/etalon scenario pairs
    TRUNCATE TABLE dm_ufkbrd.stg_advances_scenario_fact_etalon;
    INSERT INTO dm_ufkbrd.stg_advances_scenario_fact_etalon (
        year_num, scenario_fact, order_fact, scenario_etalon, order_etalon
    )
    SELECT
        f.year_num,
        f.scenario_fact,
        f.order_fact,
        s.scenario_value,
        s.scenario_order
    FROM (
        SELECT DISTINCT
            year_num,
            scenario_name AS scenario_fact,
            coalesce((
                SELECT so.scenario_order
                FROM dm_ufkbrd.ref_scenario_order so
                WHERE so.scenario_value = scenario_name
            ), 0) AS order_fact
        FROM dm_ufkbrd.stg_advances_forecast
    ) f
    JOIN dm_ufkbrd.ref_scenario_order s ON s.scenario_order >= f.order_fact
    JOIN (
        SELECT year_num, scenario_value AS scenario_etalon, max(order_fact) AS max_order_fact
        FROM (
            SELECT DISTINCT
                a.year_num,
                a.scenario_name AS scenario_fact,
                coalesce(so.scenario_order, 0) AS order_fact,
                s2.scenario_value
            FROM dm_ufkbrd.stg_advances_forecast a
            LEFT JOIN dm_ufkbrd.ref_scenario_order so ON so.scenario_value = a.scenario_name
            CROSS JOIN dm_ufkbrd.ref_scenario_order s2
            WHERE s2.scenario_order >= coalesce(so.scenario_order, 0)
        ) q
        GROUP BY year_num, scenario_value
    ) mx ON mx.year_num = f.year_num
        AND mx.scenario_etalon = s.scenario_value
        AND mx.max_order_fact = f.order_fact;

END;
$$;
