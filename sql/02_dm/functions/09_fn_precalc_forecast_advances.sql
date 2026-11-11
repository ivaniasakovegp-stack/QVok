-- 03-08 PreCalc advances forecast

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_precalc_forecast_advances()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_today date := dm_ufkbrd.fn_as_of_date();
    v_year_fact integer;
    v_year_fcst integer;
BEGIN
    v_year_fact := EXTRACT(YEAR FROM v_today)::integer;
    v_year_fcst := v_year_fact + 1;

    -- Core fact/plan fact table
    TRUNCATE TABLE dm_ufkbrd.mart_forecast_advances;

    INSERT INTO dm_ufkbrd.mart_forecast_advances (
        movement_flag, scenario_etalon, scenario_name, year_num, do_name_src, do_name,
        do_name_table, in_vok_perimeter_flag, forecast_dt, source_system, inn, contractor_name,
        contract_number, paid_fact_rub, repaid_fact_rub, issue_plan_rub, repay_plan_rub,
        issue_delta_rub, repay_delta_rub, bop_forecast_rub, bop_fact_rub, eop_rub,
        eop_for_variance_rub, scenario_order, fact_present_flag, new_contract_flag
    )
    WITH excel AS (
        SELECT
            f.scenario_name,
            f.year_num,
            f.do_name_src,
            CASE WHEN EXISTS (
                    SELECT 1 FROM dm_ufkbrd.ref_do_vok r
                    WHERE r.do_short_name = f.do_name AND r.flag_vok = 1
                 ) THEN f.do_name ELSE NULL END AS do_name,
            CASE WHEN EXISTS (
                    SELECT 1 FROM dm_ufkbrd.ref_do_vok r
                    WHERE r.do_short_name = f.do_name AND r.flag_vok = 1
                 ) THEN f.do_name ELSE f.do_name || ' (вне ВОК)' END AS do_name_table,
            CASE WHEN f.inn IS NULL THEN 'Не указано'
                 WHEN f.inn = '7838112072' THEN 'ИНН 22'
                 WHEN f.inn = '7813647735' THEN 'ИНН 51'
                 ELSE text(f.inn) END AS inn,
            CASE WHEN text(f.contract_number) = 'ОВ/К-39638-01-01'
                 THEN 'Договор лизинга ППА_БУ_2024_спец_1'
                 ELSE text(f.contract_number) END AS contract_number,
            f.period_dt,
            sum(f.planned_issue_rub) AS planned_issue_rub,
            sum(f.planned_repay_rub) AS planned_repay_rub,
            coalesce((
                SELECT so.scenario_order FROM dm_ufkbrd.ref_scenario_order so
                WHERE so.scenario_value = f.scenario_name
            ), 0) AS scenario_order
        FROM dm_ufkbrd.stg_advances_forecast f
        GROUP BY
            f.scenario_name, f.year_num, f.do_name_src, f.do_name, f.inn, f.contract_number, f.period_dt
    ),
    arm AS (
        SELECT
            CASE WHEN EXTRACT(MONTH FROM report_dt) = 12 THEN NULL
                 ELSE EXTRACT(MONTH FROM report_dt)::integer::text || '+' ||
                      (12 - EXTRACT(MONTH FROM report_dt)::integer)::text
            END AS scenario_name,
            sum(advances_bop_rub) AS advances_bop_rub,
            sum(advances_eop_rub) AS advances_eop_rub,
            sum(advances_paid_wo_neg) AS advances_paid_rub,
            sum(advances_repaid_wo_neg) AS advances_repaid_rub,
            CASE WHEN counterparty_inn IS NULL THEN 'Не указано' ELSE text(counterparty_inn) END AS inn,
            report_dt AS period_dt,
            EXTRACT(YEAR FROM report_dt)::integer AS year_num,
            CASE WHEN text(contract_number) = 'ОВ/К-39638-01-01'
                 THEN 'Договор лизинга ППА_БУ_2024_спец_1'
                 ELSE ltrim(text(contract_number)) END AS contract_number,
            do_name_src
        FROM dm_ufkbrd.stg_arm_kk
        WHERE row_type = 'Авансы'
          AND report_dt >= make_date(dm_ufkbrd.fn_dashboard_year(), 1, 1)
          AND (do_name IS NOT NULL OR do_name_src IN (
                'Ангара','Автоматизация','ННГГФ','Энергосистемы','Томскнефть ВНК','Гарант Сервис','SPD','ИТ Сервис'
              ))
        GROUP BY
            report_dt, counterparty_inn, contract_number, do_name_src, do_name
    )
    SELECT
        1,
        e.scenario_name,
        e.scenario_name,
        e.year_num,
        e.do_name_src,
        e.do_name,
        e.do_name_table,
        CASE WHEN e.do_name_table LIKE '%вне ВОК%' THEN 0 ELSE 1 END,
        e.period_dt,
        'Excel',
        e.inn,
        coalesce((
            SELECT max(a2.counterparty_name)
            FROM dm_ufkbrd.stg_arm_kk a2
            WHERE text(ltrim(a2.counterparty_inn)) = e.inn
        ), 'Не указано'),
        e.contract_number,
        sum(a.advances_paid_rub),
        sum(a.advances_repaid_rub),
        sum(CASE WHEN e.planned_issue_rub < 10 THEN 0 ELSE e.planned_issue_rub END),
        round(sum(CASE WHEN e.planned_repay_rub < 10 THEN 0 ELSE e.planned_repay_rub END)),
        CASE
            WHEN abs(coalesce(sum(a.advances_paid_rub),0) - sum(CASE WHEN e.planned_issue_rub < 10 OR e.contract_number = 'Не законтрактован' THEN 0 ELSE e.planned_issue_rub END)) < 2
            THEN 0
            ELSE round(coalesce(sum(a.advances_paid_rub),0) - sum(CASE WHEN e.planned_issue_rub < 10 OR e.contract_number = 'Не законтрактован' THEN 0 ELSE e.planned_issue_rub END))
        END,
        CASE
            WHEN abs(sum(CASE WHEN e.planned_repay_rub < 10 OR e.contract_number = 'Не законтрактован' THEN 0 ELSE e.planned_repay_rub END) - coalesce(sum(a.advances_repaid_rub),0)) < 2
            THEN 0
            ELSE round(sum(CASE WHEN e.planned_repay_rub < 10 OR e.contract_number = 'Не законтрактован' THEN 0 ELSE e.planned_repay_rub END) - coalesce(sum(a.advances_repaid_rub),0))
        END,
        NULL,
        sum(a.advances_bop_rub),
        CASE WHEN e.scenario_order = EXTRACT(MONTH FROM e.period_dt)::integer THEN sum(a.advances_eop_rub) ELSE 0 END,
        sum(a.advances_eop_rub),
        e.scenario_order,
        CASE WHEN e.scenario_order >= EXTRACT(MONTH FROM e.period_dt)::integer THEN 1 ELSE 0 END,
        NULL
    FROM excel e
    LEFT JOIN arm a
           ON a.inn = e.inn
          AND a.period_dt = e.period_dt
          AND a.year_num = e.year_num
          AND a.contract_number = e.contract_number
          AND a.do_name_src = e.do_name_src
    GROUP BY
        e.scenario_name, e.year_num, e.do_name_table, e.period_dt, e.do_name_src,
        e.do_name, e.inn, e.contract_number, e.scenario_order;

    -- BOP forecast for 0+12 (Sep-Dec window)
    IF EXTRACT(MONTH FROM v_today) >= 9 THEN
        TRUNCATE TABLE dm_ufkbrd.mart_advances_bop_forecast;
        INSERT INTO dm_ufkbrd.mart_advances_bop_forecast (
            scenario_name, bop_amount_rub, inn, report_dt, contract_number, do_name_table, do_name, do_name_src
        )
        SELECT
            '0+12',
            coalesce(sum(CASE WHEN src = 'bal' THEN amt ELSE 0 END),0)
              + coalesce(sum(CASE WHEN src = 'mov' THEN amt ELSE 0 END),0)
              + coalesce(sum(CASE WHEN src = 'repay' THEN amt ELSE 0 END),0),
            inn,
            dm_ufkbrd.fn_month_end(make_date(v_year_fcst, 1, 1)),
            contract_number,
            do_name_table,
            do_name,
            do_name_src
        FROM (
            SELECT 'bal' AS src, advances_eop_rub AS amt,
                   CASE WHEN counterparty_inn IS NULL THEN 'Не указано' ELSE text(counterparty_inn) END AS inn,
                   CASE WHEN text(contract_number) = 'ОВ/К-39638-01-01'
                        THEN 'Договор лизинга ППА_БУ_2024_спец_1' ELSE ltrim(text(contract_number)) END AS contract_number,
                   CASE WHEN do_name IS NULL THEN do_name_src || ' (вне ВОК)' ELSE do_name_src END AS do_name_table,
                   do_name, do_name_src
            FROM dm_ufkbrd.stg_arm_kk
            WHERE row_type = 'Авансы'
              AND EXTRACT(YEAR FROM report_dt) = v_year_fact
              AND EXTRACT(MONTH FROM report_dt) = 8
              AND EXTRACT(DAY FROM report_dt) = 31
            UNION ALL
            SELECT 'mov', planned_issue_rub, inn, contract_number,
                   CASE WHEN EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = do_name AND r.flag_vok = 1)
                        THEN do_name ELSE do_name || ' (вне ВОК)' END,
                   do_name, do_name_src
            FROM dm_ufkbrd.stg_advances_forecast
            WHERE EXTRACT(MONTH FROM period_dt) > 8
              AND year_num = v_year_fact
              AND scenario_name = '8+4'
              AND (planned_issue_rub <> 0 OR planned_repay_rub <> 0)
            UNION ALL
            SELECT 'repay', -planned_repay_rub, inn, contract_number,
                   CASE WHEN EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = do_name AND r.flag_vok = 1)
                        THEN do_name ELSE do_name || ' (вне ВОК)' END,
                   do_name, do_name_src
            FROM dm_ufkbrd.stg_advances_forecast
            WHERE EXTRACT(MONTH FROM period_dt) > 8
              AND year_num = v_year_fact
              AND scenario_name = '8+4'
              AND (planned_issue_rub <> 0 OR planned_repay_rub <> 0)
        ) q
        GROUP BY inn, contract_number, do_name_table, do_name, do_name_src;
    END IF;

    -- Export for BDDS
    TRUNCATE TABLE dm_ufkbrd.mart_forecast_advances_dds;
    INSERT INTO dm_ufkbrd.mart_forecast_advances_dds (
        do_name, issue_plan_rub, repay_plan_rub, forecast_dt, scenario_etalon, capex_opex, scenario_name, year_num
    )
    SELECT
        do_name,
        sum(planned_issue_rub),
        sum(planned_repay_rub),
        period_dt,
        scenario_name,
        capex_opex,
        scenario_name,
        year_num
    FROM dm_ufkbrd.stg_advances_forecast
    GROUP BY do_name, capex_opex, period_dt, scenario_name, year_num;

    -- Running forecast summary (issue - repay cumulative within scenario/year/DO)
    TRUNCATE TABLE dm_ufkbrd.mart_forecast_advances_summary;
    INSERT INTO dm_ufkbrd.mart_forecast_advances_summary (
        scenario_name, in_vok_perimeter_flag, do_name, year_num, forecast_dt, forecast_amount
    )
    SELECT
        scenario_name,
        in_vok_perimeter_flag,
        do_name,
        year_num,
        forecast_dt,
        forecast_amount
    FROM (
        SELECT
            scenario_name,
            in_vok_perimeter_flag,
            do_name,
            year_num,
            forecast_dt,
            sum(coalesce(issue_plan_rub,0) - coalesce(repay_plan_rub,0) + coalesce(bop_fact_rub,0))
                OVER (
                    PARTITION BY do_name_src, scenario_name, year_num
                    ORDER BY forecast_dt
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                ) AS forecast_amount
        FROM dm_ufkbrd.mart_forecast_advances
        WHERE fact_present_flag = 0
          AND do_name IS NOT NULL
          AND in_vok_perimeter_flag = 1
    ) t
    WHERE forecast_amount <> 0;
END;
$$;
