-- 03-09 AR forecast / 03-10 AP forecast / 03-11 MTR forecast

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_precalc_forecast_ar()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_today date := dm_ufkbrd.fn_as_of_date();
    v_qty integer;
    v_dt_bal date;
    v_dt_boy date;
    v_year integer;
BEGIN
    -- Opening balance generation (Nov-Jan window)
    IF EXTRACT(MONTH FROM v_today) >= 11 OR EXTRACT(MONTH FROM v_today) = 1 THEN
        IF EXTRACT(MONTH FROM v_today) >= 11 THEN v_qty := 0; ELSE v_qty := 1; END IF;
        v_dt_bal := make_date(EXTRACT(YEAR FROM v_today)::integer - v_qty, 9, 30);
        v_dt_boy := make_date(EXTRACT(YEAR FROM v_today)::integer - v_qty + 1, 1, 1);
        v_year := EXTRACT(YEAR FROM v_dt_bal)::integer;

        TRUNCATE TABLE dm_ufkbrd.mart_ar_bop_forecast;
        INSERT INTO dm_ufkbrd.mart_ar_bop_forecast (data_flag, do_name, forecast_dt, forecast_amount)
        SELECT data_flag, do_name, make_date(v_year + 1, 1, 1), sum(amount)
        FROM (
            SELECT 'ДЗ' AS data_flag, do_name, sum(debt_total_reval_rub) AS amount
            FROM dm_ufkbrd.stg_arm_kk
            WHERE row_type = 'ДЗ' AND report_dt = v_dt_bal
              AND EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = do_name AND r.flag_vok = 1)
            GROUP BY do_name
            UNION ALL
            SELECT 'ДЗ', do_short_name, sum(amount_plan_fact * 1000000) * (-1)
            FROM ods.bdds_dashboard_data
            WHERE report_period = '9+3'
              AND do_short_name <> 'БРД'
              AND dm_ufkbrd.fn_month_end(period_dt) > v_dt_bal
              AND dm_ufkbrd.fn_month_end(period_dt) < v_dt_boy
              AND group2 IN (
                    'Поступления от реализации - прочие (3и лица)',
                    'Поступления от реализации газа (3и лица)',
                    'Поступления от реализации нефти (3и лица)',
                    'Поступления от реализации н/п (3и лица)'
                  )
              AND EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = do_short_name AND r.flag_vok = 1)
            GROUP BY do_short_name
            UNION ALL
            SELECT 'ДЗ', entity_alias2, abs(sum(amount * 1000) * 1.2)
            FROM ods.spo_forecast_src
            WHERE scenario = 'SCN_FORECAST_09'
              AND dm_ufkbrd.fn_month_end(report_dt) > v_dt_bal
              AND dm_ufkbrd.fn_month_end(report_dt) < v_dt_boy
              AND EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = entity_alias2 AND r.flag_vok = 1)
              AND (
                    (ka_vgo_flag = 'KA'
                     AND counterparty_code NOT IN ('CT_TOTAL','CT_TOTAL_ALT')
                     AND account_alias LIKE 'Выручка%'
                     AND (account_alias = 'Выручка от реализации ТМЦ' OR coalesce(account_code,'') NOT LIKE 'ACC_PL_17%'))
                    OR
                    (account_alias LIKE 'Выручка%'
                     AND counterparty_alias = 'ОЕ Поставка нефти_ГПН (к)'
                     AND entity_alias2 IN ('Томскнефть','Мессояха','Мегион'))
                  )
            GROUP BY entity_alias2
        ) q
        GROUP BY data_flag, do_name;
    END IF;

    TRUNCATE TABLE dm_ufkbrd.mart_forecast_ar;

    INSERT INTO dm_ufkbrd.mart_forecast_ar (scenario_name, do_name, year_num, forecast_dt, forecast_amount)
    WITH base AS (
        SELECT
            '0+12'::varchar AS scenario_name,
            do_name,
            EXTRACT(YEAR FROM (forecast_dt + 1))::integer AS year_num,
            dm_ufkbrd.fn_month_end((forecast_dt + 1)::date) AS forecast_dt,
            round(forecast_amount) AS opening_amount,
            0::numeric AS receipts,
            0::numeric AS revenue,
            0 AS fact_present_flag
        FROM dm_ufkbrd.mart_ar_bop_forecast
        UNION ALL
        SELECT
            EXTRACT(MONTH FROM report_dt)::integer::text || '+' || (12 - EXTRACT(MONTH FROM report_dt)::integer)::text,
            do_name,
            EXTRACT(YEAR FROM (report_dt + INTERVAL '1 month'))::integer,
            dm_ufkbrd.fn_month_end((report_dt + INTERVAL '1 month')::date),
            sum(debt_total_reval_rub),
            0, 0, 0
        FROM dm_ufkbrd.stg_arm_kk
        WHERE row_type = 'ДЗ'
          AND EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = do_name AND r.flag_vok = 1)
        GROUP BY do_name, report_dt
        HAVING EXTRACT(MONTH FROM report_dt)::integer <> 12
    ),
    grid AS (
        SELECT DISTINCT
            d.do_name,
            s.scenario_value AS scenario_name,
            p.period_dt AS forecast_dt,
            p.year_num,
            CASE WHEN coalesce(so.scenario_order,0) >= EXTRACT(MONTH FROM p.period_dt)::integer THEN 1 ELSE 0 END AS fact_present_flag
        FROM (SELECT DISTINCT do_name FROM base) d
        CROSS JOIN dm_ufkbrd.ref_scenario_order s
        CROSS JOIN dm_ufkbrd.ref_periods p
    ),
    receipts AS (
        SELECT
            do_short_name AS do_name,
            report_period AS scenario_name,
            dm_ufkbrd.fn_month_end(period_dt) AS forecast_dt,
            CASE
                WHEN group2 = 'Поступления от реализации нефти (3и лица)'
                     AND do_short_name IN ('Томскнефть','Мессояха','Мегион')
                THEN abs(sum(amount_plan_fact * 1000000)) / 2.0
                ELSE abs(sum(amount_plan_fact * 1000000))
            END AS receipts
        FROM ods.bdds_dashboard_data
        WHERE do_short_name <> 'БРД'
          AND year_num >= 2022
          AND report_period <> '0+12 акт'
          AND group2 IN (
                'Поступления от реализации - прочие (3и лица)',
                'Поступления от реализации газа (3и лица)',
                'Поступления от реализации нефти (3и лица)',
                'Поступления от реализации н/п (3и лица)'
              )
          AND EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = do_short_name AND r.flag_vok = 1)
        GROUP BY do_short_name, report_period, period_dt, group2
    ),
    revenue AS (
        SELECT
            m.scenario_etalon AS scenario_name,
            s.entity_alias2 AS do_name,
            dm_ufkbrd.fn_month_end(s.report_dt) AS forecast_dt,
            abs(sum(s.amount) * 1000) * 1.2 AS revenue
        FROM ods.spo_forecast_src s
        JOIN ods.scenario_mapping m
          ON m.year_num = s.year_num AND m.scenario_spo_src = s.scenario
        WHERE s.year_num >= 2022
          AND s.ka_vgo_flag = 'KA'
          AND s.counterparty_code NOT IN ('CT_TOTAL','CT_TOTAL_ALT')
          AND s.account_alias LIKE 'Выручка%'
          AND (s.account_alias = 'Выручка от реализации ТМЦ' OR coalesce(s.account_code,'') NOT LIKE 'ACC_PL_17%')
          AND EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = s.entity_alias2 AND r.flag_vok = 1)
        GROUP BY m.scenario_etalon, s.entity_alias2, s.report_dt
    ),
    joined AS (
        SELECT
            g.scenario_name,
            g.do_name,
            g.year_num,
            g.forecast_dt,
            g.fact_present_flag,
            coalesce(b.opening_amount, 0) AS opening_amount,
            coalesce(r.receipts, 0) AS receipts,
            coalesce(v.revenue, 0) AS revenue
        FROM grid g
        LEFT JOIN base b
               ON b.do_name = g.do_name AND b.scenario_name = g.scenario_name AND b.forecast_dt = g.forecast_dt
        LEFT JOIN receipts r
               ON r.do_name = g.do_name AND r.scenario_name = g.scenario_name AND r.forecast_dt = g.forecast_dt
        LEFT JOIN revenue v
               ON v.do_name = g.do_name AND v.scenario_name = g.scenario_name AND v.forecast_dt = g.forecast_dt
        WHERE g.fact_present_flag = 0
    )
    SELECT scenario_name, do_name, year_num, forecast_dt, forecast_amount
    FROM (
        SELECT
            scenario_name, do_name, year_num, forecast_dt,
            sum(opening_amount + revenue - receipts) OVER (
                PARTITION BY do_name, scenario_name, year_num
                ORDER BY forecast_dt
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS forecast_amount
        FROM joined
    ) t
    WHERE forecast_amount <> 0;
END;
$$;

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_precalc_forecast_ap()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_today date := dm_ufkbrd.fn_as_of_date();
    v_qty integer;
    v_dt_bal date;
    v_dt_boy date;
    v_year integer;
BEGIN
    IF EXTRACT(MONTH FROM v_today) >= 10 OR EXTRACT(MONTH FROM v_today) = 1 THEN
        IF EXTRACT(MONTH FROM v_today) >= 11 THEN v_qty := 0; ELSE v_qty := 1; END IF;
        v_dt_bal := make_date(EXTRACT(YEAR FROM v_today)::integer - v_qty, 9, 30);
        v_dt_boy := make_date(EXTRACT(YEAR FROM v_today)::integer - v_qty + 1, 1, 1);
        v_year := EXTRACT(YEAR FROM v_dt_bal)::integer;

        TRUNCATE TABLE dm_ufkbrd.mart_ap_bop_forecast;
        INSERT INTO dm_ufkbrd.mart_ap_bop_forecast (data_flag, do_name, forecast_dt, forecast_amount)
        SELECT 'КЗ', do_name, make_date(v_year + 1, 1, 1), sum(amount)
        FROM (
            SELECT do_name, sum(ap_eop_rub) AS amount
            FROM dm_ufkbrd.stg_arm_kk
            WHERE row_type = 'КЗ' AND report_dt = v_dt_bal
              AND EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = do_name AND r.flag_vok = 1)
            GROUP BY do_name
            UNION ALL
            SELECT entity_alias2, abs(sum(amount * 1000) * 1.2)
            FROM ods.spo_forecast_src
            WHERE scenario = 'SCN_FORECAST_09'
              AND ka_vgo_flag = 'KA'
              AND counterparty_code NOT IN ('CT_TOTAL','CT_TOTAL_ALT')
              AND dm_ufkbrd.fn_month_end(report_dt) > v_dt_bal
              AND dm_ufkbrd.fn_month_end(report_dt) < v_dt_boy
              AND account_alias2 IN ('Прочие платежи (3и лица)', 'Энерго и теплообеспечение производства (3и лица)')
              AND EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = entity_alias2 AND r.flag_vok = 1)
            GROUP BY entity_alias2
            UNION ALL
            SELECT entity_alias2, abs(sum(amount * 1000 * 1.2))
            FROM ods.spo_forecast_src s
            WHERE scenario = 'SCN_FORECAST_09'
              AND ka_vgo_flag = 'KA'
              AND counterparty_code NOT IN ('CT_TOTAL','CT_TOTAL_ALT')
              AND dm_ufkbrd.fn_month_end(report_dt) > v_dt_bal
              AND dm_ufkbrd.fn_month_end(report_dt) < v_dt_boy
              AND EXISTS (SELECT 1 FROM ods.nsi_algoritm_depos_spo a WHERE a.pl_line = s.account_alias AND a.data_shift = 'вне алгоритма')
              AND EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = entity_alias2 AND r.flag_vok = 1)
            GROUP BY entity_alias2
            UNION ALL
            SELECT do_short_name, sum(amount_plan_fact * 1000000)
            FROM ods.bdds_dashboard_data
            WHERE report_period = '9+3' AND do_short_name <> 'БРД'
              AND dm_ufkbrd.fn_month_end(period_dt) > v_dt_bal
              AND dm_ufkbrd.fn_month_end(period_dt) < v_dt_boy
              AND group2 IN ('Прочие платежи (3и лица)', 'Энерго и теплообеспечение производства (3и лица)')
              AND EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = do_short_name AND r.flag_vok = 1)
            GROUP BY do_short_name
            UNION ALL
            SELECT do_short_name, sum(amount_plan_fact * 1000000)
            FROM ods.bdds_dashboard_data
            WHERE report_period = '9+3' AND do_short_name <> 'БРД'
              AND dm_ufkbrd.fn_month_end(period_dt) > v_dt_bal
              AND dm_ufkbrd.fn_month_end(period_dt) < v_dt_boy
              AND group2 = 'Платежи по Инвестиционной Программе с учетом отсрочек по факторингу (3и лица)'
              AND EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = do_short_name AND r.flag_vok = 1)
            GROUP BY do_short_name
            UNION ALL
            SELECT do_name,
                   CASE WHEN data_flag = 'Норматив Расход' THEN sum(amount * 1.2) * (-1) ELSE sum(amount * 1.2) END
            FROM dm_ufkbrd.stg_mtr
            WHERE data_flag IN ('Норматив Приход', 'Норматив Расход')
              AND dm_ufkbrd.fn_month_end(period_dt) > v_dt_bal
              AND dm_ufkbrd.fn_month_end(period_dt) < v_dt_boy
              AND mtr_map_filter_l1 = 'CAPEX'
            GROUP BY do_name, data_flag
        ) q
        GROUP BY do_name;
    END IF;

    TRUNCATE TABLE dm_ufkbrd.mart_forecast_ap;
    INSERT INTO dm_ufkbrd.mart_forecast_ap (
        scenario_name, do_name, year_num, forecast_dt, forecast_wo_factoring, forecast_amount, lt_factoring_block
    )
    WITH opening AS (
        SELECT
            '0+12'::varchar AS scenario_name,
            do_name,
            EXTRACT(YEAR FROM (forecast_dt + 1))::integer AS year_num,
            dm_ufkbrd.fn_month_end((forecast_dt + 1)::date) AS forecast_dt,
            CASE WHEN do_name = 'Ямал' AND EXTRACT(YEAR FROM (forecast_dt + 1)) = 2023
                 THEN round(forecast_amount) - 78008455163
                 ELSE round(forecast_amount) END AS opening_amount
        FROM dm_ufkbrd.mart_ap_bop_forecast
    ),
    fact AS (
        SELECT
            EXTRACT(MONTH FROM report_dt)::integer::text || '+' || (12 - EXTRACT(MONTH FROM report_dt)::integer)::text AS scenario_name,
            do_name,
            EXTRACT(YEAR FROM (report_dt + INTERVAL '1 month'))::integer AS year_num,
            dm_ufkbrd.fn_month_end((report_dt + INTERVAL '1 month')::date) AS forecast_dt,
            sum(ap_eop_rub) AS opening_amount
        FROM dm_ufkbrd.stg_arm_kk
        WHERE row_type = 'КЗ'
          AND report_dt >= DATE '2022-01-31'
          AND EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = do_name AND r.flag_vok = 1)
        GROUP BY do_name, report_dt
        HAVING EXTRACT(MONTH FROM report_dt)::integer <> 12
    ),
    drivers AS (
        SELECT
            m.scenario_etalon AS scenario_name,
            t.do_name,
            t.forecast_dt,
            sum(t.opex_exp) AS opex_exp,
            sum(t.opex_pay) AS opex_pay,
            sum(t.capex_exp) AS capex_exp,
            sum(t.capex_pay) AS capex_pay,
            sum(t.capex_mtr) AS capex_mtr
        FROM (
            SELECT entity_alias2 AS do_name, dm_ufkbrd.fn_month_end(report_dt) AS forecast_dt, year_num, scenario,
                   abs(sum(amount * 1000) * 1.2) AS opex_exp, 0::numeric AS opex_pay, 0::numeric AS capex_exp,
                   0::numeric AS capex_pay, 0::numeric AS capex_mtr
            FROM ods.spo_forecast_src
            WHERE ka_vgo_flag = 'KA' AND counterparty_code NOT IN ('CT_TOTAL','CT_TOTAL_ALT')
              AND account_alias2 IN ('Прочие платежи (3и лица)', 'Энерго и теплообеспечение производства (3и лица)')
              AND year_num >= 2022
              AND EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = entity_alias2 AND r.flag_vok = 1)
            GROUP BY entity_alias2, report_dt, year_num, scenario
            UNION ALL
            SELECT do_short_name, dm_ufkbrd.fn_month_end(period_dt), year_num, report_period,
                   0, abs(sum(amount_plan_fact * 1000000)), 0, 0, 0
            FROM ods.bdds_dashboard_data
            WHERE do_short_name <> 'БРД' AND year_num >= 2022 AND report_period <> '0+12 акт'
              AND group2 IN ('Прочие платежи (3и лица)', 'Энерго и теплообеспечение производства (3и лица)')
              AND EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = do_short_name AND r.flag_vok = 1)
            GROUP BY do_short_name, period_dt, year_num, report_period
            UNION ALL
            SELECT entity_alias2, dm_ufkbrd.fn_month_end(report_dt), year_num, scenario,
                   0, 0, abs(sum(amount * 1000 * 1.2)), 0, 0
            FROM ods.spo_forecast_src s
            WHERE ka_vgo_flag = 'KA' AND counterparty_code NOT IN ('CT_TOTAL','CT_TOTAL_ALT') AND year_num >= 2022
              AND EXISTS (SELECT 1 FROM ods.nsi_algoritm_depos_spo a WHERE a.pl_line = s.account_alias AND a.data_shift = 'вне алгоритма')
              AND EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = entity_alias2 AND r.flag_vok = 1)
            GROUP BY entity_alias2, report_dt, year_num, scenario
            UNION ALL
            SELECT do_short_name, dm_ufkbrd.fn_month_end(period_dt), year_num, report_period,
                   0, 0, 0, abs(sum(amount_plan_fact * 1000000)), 0
            FROM ods.bdds_dashboard_data
            WHERE do_short_name <> 'БРД' AND year_num >= 2022 AND report_period <> '0+12 акт'
              AND group2 = 'Платежи по Инвестиционной Программе с учетом отсрочек по факторингу (3и лица)'
              AND EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = do_short_name AND r.flag_vok = 1)
            GROUP BY do_short_name, period_dt, year_num, report_period
            UNION ALL
            SELECT do_name, dm_ufkbrd.fn_month_end(period_dt), EXTRACT(YEAR FROM period_dt)::integer, NULL,
                   0, 0, 0, 0,
                   sum(amount * CASE WHEN data_flag = 'Норматив Расход' THEN -1.2 ELSE 1.2 END)
            FROM dm_ufkbrd.stg_mtr
            WHERE data_flag IN ('Норматив Приход', 'Норматив Расход')
              AND EXTRACT(YEAR FROM period_dt) >= 2022
              AND mtr_map_filter_l1 = 'CAPEX'
            GROUP BY do_name, period_dt
        ) t
        LEFT JOIN ods.scenario_mapping m
               ON m.year_num = t.year_num AND (m.scenario_spo_src = t.scenario OR m.scenario_etalon = t.scenario)
        GROUP BY m.scenario_etalon, t.do_name, t.forecast_dt
    ),
    base AS (
        SELECT * FROM opening
        UNION ALL
        SELECT * FROM fact
    ),
    joined AS (
        SELECT
            coalesce(b.scenario_name, d.scenario_name) AS scenario_name,
            coalesce(b.do_name, d.do_name) AS do_name,
            coalesce(b.year_num, EXTRACT(YEAR FROM d.forecast_dt)::integer) AS year_num,
            coalesce(b.forecast_dt, d.forecast_dt) AS forecast_dt,
            coalesce(b.opening_amount, 0) AS opening_amount,
            coalesce(d.opex_exp,0) AS opex_exp,
            coalesce(d.opex_pay,0) AS opex_pay,
            coalesce(d.capex_exp,0) AS capex_exp,
            coalesce(d.capex_pay,0) AS capex_pay,
            coalesce(d.capex_mtr,0) AS capex_mtr,
            CASE WHEN coalesce((
                SELECT so.scenario_order FROM dm_ufkbrd.ref_scenario_order so
                WHERE so.scenario_value = coalesce(b.scenario_name, d.scenario_name)
            ),0) >= EXTRACT(MONTH FROM coalesce(b.forecast_dt, d.forecast_dt))::integer THEN 1 ELSE 0 END AS fact_present_flag
        FROM base b
        FULL OUTER JOIN drivers d
          ON d.do_name = b.do_name AND d.scenario_name = b.scenario_name AND d.forecast_dt = b.forecast_dt
    ),
    run AS (
        SELECT
            scenario_name, do_name, year_num, forecast_dt,
            sum(opening_amount + opex_exp - opex_pay + capex_exp - capex_pay + capex_mtr) OVER (
                PARTITION BY do_name, scenario_name, year_num
                ORDER BY forecast_dt
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS forecast_amount
        FROM joined
        WHERE fact_present_flag = 0
          AND scenario_name IS NOT NULL
          AND do_name IS NOT NULL
    ),
    block_factoring AS (
        SELECT
            dm_ufkbrd.fn_month_end(period_dt) AS forecast_dt,
            year_num,
            report_period AS scenario_name,
            sum(limit_amount * 1000000) * (-1.2) AS lt_factoring_block
        FROM ods.atlas_limits_fin_osv
        WHERE category_name = 'Сверхнормативная рассрочка платежей'
          AND legal_entity = 'ПАО Газпром нефть'
          AND cons_principle = 'Финансирование'
          AND year_num >= 2023
          AND report_period <> '0+12 акт'
          AND coalesce((
                SELECT so.scenario_order FROM dm_ufkbrd.ref_scenario_order so
                WHERE so.scenario_value = report_period
              ),0) < EXTRACT(MONTH FROM period_dt)::integer
        GROUP BY period_dt, year_num, report_period
    )
    SELECT
        r.scenario_name,
        r.do_name,
        r.year_num,
        r.forecast_dt,
        r.forecast_amount,
        r.forecast_amount,
        b.lt_factoring_block
    FROM run r
    LEFT JOIN block_factoring b
           ON b.scenario_name = r.scenario_name
          AND b.year_num = r.year_num
          AND b.forecast_dt = r.forecast_dt;

    -- Factoring forecast mart
    TRUNCATE TABLE dm_ufkbrd.mart_forecast_ap_factoring;
    INSERT INTO dm_ufkbrd.mart_forecast_ap_factoring (
        do_name, payment_type, factoring_type, factoring_dt, report_period, factoring_year,
        forecast_name_atlas, ap_eop_rub, turnover_dt, same_period_flag
    )
    SELECT
        f.do_name,
        f.payment_type,
        'Факт',
        CASE WHEN EXTRACT(MONTH FROM f.report_dt) = 12
             THEN dm_ufkbrd.fn_month_end(make_date(EXTRACT(YEAR FROM f.report_dt)::integer + 1, 1, 1))
             ELSE f.report_dt END,
        CASE WHEN EXTRACT(MONTH FROM f.report_dt) = 12 THEN '0+12'
             ELSE EXTRACT(MONTH FROM f.report_dt)::integer::text || '+' || (12 - EXTRACT(MONTH FROM f.report_dt)::integer)::text END,
        CASE WHEN EXTRACT(MONTH FROM f.report_dt) = 12 THEN f.year_num + 1 ELSE f.year_num END,
        NULL,
        sum(f.ap_eop_rub),
        NULL,
        NULL
    FROM dm_ufkbrd.mart_ap_factoring f
    WHERE f.report_dt > DATE '2023-12-01'
      AND f.payment_type IN ('краткосрочный факторинг', 'долгосрочный факторинг', 'комиссия за факторинг')
      AND EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = f.do_name AND r.flag_vok = 1)
    GROUP BY f.do_name, f.payment_type, f.report_dt, f.year_num;

    INSERT INTO dm_ufkbrd.mart_forecast_ap_factoring (
        do_name, payment_type, factoring_type, factoring_dt, report_period, factoring_year,
        forecast_name_atlas, ap_eop_rub, turnover_dt, same_period_flag
    )
    SELECT
        a.do_short_name,
        CASE
            WHEN a.category_name LIKE 'Проценты за факторинг%' THEN 'комиссия за факторинг'
            WHEN a.category_name IN ('Факторинг 3 года', 'Факторинг 7 лет') THEN 'долгосрочный факторинг'
            ELSE 'краткосрочный факторинг'
        END,
        'Прогноз',
        date_trunc('day', a.period_dt)::date,
        a.report_period,
        a.year_num,
        a.forecast_name_atlas,
        CASE
            WHEN EXTRACT(MONTH FROM a.period_dt) < coalesce((
                    SELECT so.scenario_order FROM dm_ufkbrd.ref_scenario_order so WHERE so.scenario_value = a.report_period
                 ),0) + 1 THEN 0
            WHEN a.category_name LIKE 'Проценты за факторинг%' THEN sum(a.amount) * 1000000
            ELSE sum(a.amount) * (-1000000)
        END,
        NULL,
        NULL
    FROM ods.atlas_factoring_forecast a
    WHERE a.year_num >= 2023
      AND EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = a.do_short_name AND r.flag_vok = 1)
    GROUP BY
        a.do_short_name, a.category_name, a.period_dt, a.report_period, a.year_num, a.forecast_name_atlas;
END;
$$;

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_precalc_forecast_mtr()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE dm_ufkbrd.mart_forecast_mtr;

    INSERT INTO dm_ufkbrd.mart_forecast_mtr (
        year_num, scenario_name, do_name, forecast_dt, forecast_amount_mtr, fact_present_flag
    )
    SELECT
        m.year_num,
        m.scenario_etalon,
        t.do_name,
        t.forecast_dt,
        t.amount,
        CASE WHEN coalesce(so.scenario_order,0) >= EXTRACT(MONTH FROM t.forecast_dt)::integer THEN 1 ELSE 0 END
    FROM (
        SELECT
            EXTRACT(YEAR FROM period_dt)::integer AS year_num,
            do_name,
            dm_ufkbrd.fn_month_end(period_dt) AS forecast_dt,
            sum(amount) AS amount
        FROM dm_ufkbrd.stg_mtr
        WHERE (
                (EXTRACT(YEAR FROM period_dt) <= 2023
                 AND ((do_name IN ('Шельф','Мегион') AND data_flag = 'Запас')
                      OR (do_name NOT IN ('Шельф','Мегион') AND data_flag = 'Норматив Запас МТР на конец')))
                OR (EXTRACT(YEAR FROM period_dt) >= 2024 AND data_flag = 'Запас')
              )
        GROUP BY do_name, period_dt
    ) t
    JOIN ods.scenario_mapping m ON m.year_num = t.year_num
    LEFT JOIN dm_ufkbrd.ref_scenario_order so ON so.scenario_value = m.scenario_etalon
    WHERE CASE WHEN coalesce(so.scenario_order,0) >= EXTRACT(MONTH FROM t.forecast_dt)::integer THEN 1 ELSE 0 END = 0;
END;
$$;
