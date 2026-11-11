-- 03-03 Precalc BDDS for UFKBRD

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_precalc_bdds()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_today date := dm_ufkbrd.fn_as_of_date();
    v_month integer;
    v_period varchar(50);
BEGIN
    v_month := EXTRACT(MONTH FROM v_today)::integer;

    SELECT s.scenario_value INTO v_period
    FROM ods.bdds_dashboard_data b
    JOIN ods.nsi_scenarios s ON s.scenario_order = b.report_order
    WHERE b.year_num = EXTRACT(YEAR FROM v_today)::integer
      AND b.report_order = v_month
    LIMIT 1;

    IF v_period IS NULL THEN
        SELECT report_period INTO v_period
        FROM ods.bdds_dashboard_data
        WHERE year_num = EXTRACT(YEAR FROM v_today)::integer
        ORDER BY report_order DESC
        LIMIT 1;
    END IF;

    TRUNCATE TABLE dm_ufkbrd.mart_bdds_data;

    -- Factoring MTO effect (article_order=13)
    INSERT INTO dm_ufkbrd.mart_bdds_data (dds_flag, do_type, do_short_name, dds_period_dt, month_num, report_period, dds_amount, dds_lvf_year)
    SELECT
        'Эффект применения схем факторинга МТО',
        d.do_type,
        b.do_short_name,
        dm_ufkbrd.fn_month_end(b.period_dt),
        b.month_num,
        b.report_period,
        round(sum(b.amount_plan_fact) / 1.2 * (-1), 2),
        NULL
    FROM ods.bdds_dashboard_data b
    JOIN dm_ufkbrd.ref_do_vok d ON d.do_short_name = b.do_short_name AND d.flag_bdds = 1
    WHERE b.report_period = v_period
      AND b.year_num = EXTRACT(YEAR FROM v_today)::integer
      AND b.article_order = 13
      AND b.do_short_name <> 'БРД'
    GROUP BY d.do_type, b.do_short_name, b.period_dt, b.month_num, b.report_period;

    -- Factoring IDP effect (14)
    INSERT INTO dm_ufkbrd.mart_bdds_data (dds_flag, do_type, do_short_name, dds_period_dt, month_num, report_period, dds_amount, dds_lvf_year)
    SELECT
        'Эффект применения схем факторинга по ИДП',
        d.do_type,
        b.do_short_name,
        dm_ufkbrd.fn_month_end(b.period_dt),
        b.month_num,
        b.report_period,
        round(sum(b.amount_plan_fact) / 1.2 * (-1), 2),
        NULL
    FROM ods.bdds_dashboard_data b
    JOIN dm_ufkbrd.ref_do_vok d ON d.do_short_name = b.do_short_name AND d.flag_bdds = 1
    WHERE b.report_period = v_period
      AND b.year_num = EXTRACT(YEAR FROM v_today)::integer
      AND b.article_order = 14
      AND b.do_short_name <> 'БРД'
    GROUP BY d.do_type, b.do_short_name, b.period_dt, b.month_num, b.report_period;

    -- Fact for KPI (articles 2..5, third parties)
    INSERT INTO dm_ufkbrd.mart_bdds_data (dds_flag, do_type, do_short_name, dds_period_dt, month_num, report_period, dds_amount, dds_lvf_year)
    SELECT 'Факт', d.do_type, b.do_short_name, dm_ufkbrd.fn_month_end(b.period_dt), b.month_num, b.report_period,
           sum(b.amount_plan_fact), NULL
    FROM ods.bdds_dashboard_data b
    JOIN dm_ufkbrd.ref_do_vok d ON d.do_short_name = b.do_short_name AND d.flag_bdds = 1
    WHERE b.report_period = v_period AND b.year_num = EXTRACT(YEAR FROM v_today)::integer
      AND b.article_order BETWEEN 2 AND 5
      AND b.fact_present_flag = 1
      AND b.sales_to_third_parties = 'Да'
    GROUP BY d.do_type, b.do_short_name, b.period_dt, b.month_num, b.report_period;

    INSERT INTO dm_ufkbrd.mart_bdds_data (dds_flag, do_type, do_short_name, dds_period_dt, month_num, report_period, dds_amount, dds_lvf_year)
    SELECT 'План', d.do_type, b.do_short_name, dm_ufkbrd.fn_month_end(b.period_dt), b.month_num, b.report_period,
           sum(b.plan_amount), NULL
    FROM ods.bdds_dashboard_data b
    JOIN dm_ufkbrd.ref_do_vok d ON d.do_short_name = b.do_short_name AND d.flag_bdds = 1
    WHERE b.report_period = v_period AND b.year_num = EXTRACT(YEAR FROM v_today)::integer
      AND b.article_order BETWEEN 2 AND 5
      AND b.fact_present_flag = 1
      AND b.sales_to_third_parties = 'Да'
    GROUP BY d.do_type, b.do_short_name, b.period_dt, b.month_num, b.report_period;

    INSERT INTO dm_ufkbrd.mart_bdds_data (dds_flag, do_type, do_short_name, dds_period_dt, month_num, report_period, dds_amount, dds_lvf_year)
    SELECT 'СДП', d.do_type, b.do_short_name, dm_ufkbrd.fn_month_end(b.period_dt), b.month_num, b.report_period,
           sum(b.amount_plan_fact), NULL
    FROM ods.bdds_dashboard_data b
    JOIN dm_ufkbrd.ref_do_vok d ON d.do_short_name = b.do_short_name AND d.flag_bdds = 1
    WHERE b.report_period = v_period AND b.year_num = EXTRACT(YEAR FROM v_today)::integer
      AND b.article_order BETWEEN 2 AND 3
    GROUP BY d.do_type, b.do_short_name, b.period_dt, b.month_num, b.report_period;

    INSERT INTO dm_ufkbrd.mart_bdds_data (dds_flag, do_type, do_short_name, dds_period_dt, month_num, report_period, dds_amount, dds_lvf_year)
    SELECT 'Добывающие ДО', d.do_type, b.do_short_name, dm_ufkbrd.fn_month_end(b.period_dt), b.month_num, b.report_period,
           abs(sum(b.amount_plan_fact)), NULL
    FROM ods.bdds_dashboard_data b
    JOIN dm_ufkbrd.ref_do_vok d ON d.do_short_name = b.do_short_name AND d.flag_bdds = 1
    WHERE b.report_period = v_period AND b.year_num = EXTRACT(YEAR FROM v_today)::integer
      AND b.group1 = 'Платежи по инвестиционной деятельности'
      AND d.do_type = 'Добыча'
      AND b.do_short_name <> 'БРД'
    GROUP BY d.do_type, b.do_short_name, b.period_dt, b.month_num, b.report_period;

    INSERT INTO dm_ufkbrd.mart_bdds_data (dds_flag, do_type, do_short_name, dds_period_dt, month_num, report_period, dds_amount, dds_lvf_year)
    SELECT 'Сервисы', d.do_type, b.do_short_name, dm_ufkbrd.fn_month_end(b.period_dt), b.month_num, b.report_period,
           sum(b.amount_plan_fact), NULL
    FROM ods.bdds_dashboard_data b
    JOIN dm_ufkbrd.ref_do_vok d ON d.do_short_name = b.do_short_name AND d.flag_bdds = 1
    WHERE b.report_period = v_period AND b.year_num = EXTRACT(YEAR FROM v_today)::integer
      AND d.do_type = 'Сервисы'
      AND b.article_order BETWEEN 2 AND 3
      AND b.do_short_name <> 'БРД'
    GROUP BY d.do_type, b.do_short_name, b.period_dt, b.month_num, b.report_period;

    INSERT INTO dm_ufkbrd.mart_bdds_data (dds_flag, do_type, do_short_name, dds_period_dt, month_num, report_period, dds_amount, dds_lvf_year)
    SELECT 'ДО ГРР', d.do_type, b.do_short_name, dm_ufkbrd.fn_month_end(b.period_dt), b.month_num, b.report_period,
           sum(CASE WHEN b.article_order = 10 THEN b.amount_plan_fact ELSE b.amount_plan_fact * (-1) END), NULL
    FROM ods.bdds_dashboard_data b
    JOIN dm_ufkbrd.ref_do_vok d ON d.do_short_name = b.do_short_name AND d.flag_bdds = 1
    WHERE b.report_period = v_period AND b.year_num = EXTRACT(YEAR FROM v_today)::integer
      AND d.do_type = 'ГРР'
      AND b.article_order BETWEEN 10 AND 11
      AND b.do_short_name <> 'БРД'
    GROUP BY d.do_type, b.do_short_name, b.period_dt, b.month_num, b.report_period;

    -- Debt BOY / tax inefficiency / loans in-out / ODP/IDP / payments / limit
    INSERT INTO dm_ufkbrd.mart_bdds_data (dds_flag, do_type, do_short_name, dds_period_dt, month_num, report_period, dds_amount, dds_lvf_year)
    SELECT 'Долг на начало года', NULL, l.do_short_name, NULL, NULL, l.report_period, l.debt_boy_rub, l.year_num
    FROM ods.bdds_lvf l
    JOIN dm_ufkbrd.ref_do_vok d ON d.do_short_name = l.do_short_name AND d.flag_bdds = 1
    WHERE l.report_period = v_period
      AND l.year_num = EXTRACT(YEAR FROM v_today)::integer
      AND l.do_short_name <> 'БРД';

    INSERT INTO dm_ufkbrd.mart_bdds_data (dds_flag, do_type, do_short_name, dds_period_dt, month_num, report_period, dds_amount, dds_lvf_year)
    SELECT 'Налоговая неэффективность', NULL, t.do_short_name, NULL, NULL, NULL, t.tax_inefficiency, t.year_num
    FROM ods.bdds_tax_inefficiency t
    JOIN dm_ufkbrd.ref_do_vok d ON d.do_short_name = t.do_short_name AND d.flag_bdds = 1;

    INSERT INTO dm_ufkbrd.mart_bdds_data (dds_flag, do_type, do_short_name, dds_period_dt, month_num, report_period, dds_amount, dds_lvf_year)
    SELECT 'Поступление', d.do_type, b.do_short_name, dm_ufkbrd.fn_month_end(b.period_dt), b.month_num, b.report_period,
           sum(b.amount_plan_fact), EXTRACT(YEAR FROM b.period_dt)::integer
    FROM ods.bdds_dashboard_data b
    JOIN dm_ufkbrd.ref_do_vok d ON d.do_short_name = b.do_short_name AND d.flag_bdds = 1
    WHERE b.report_period = v_period AND b.year_num = EXTRACT(YEAR FROM v_today)::integer
      AND b.group_name = 'Финансовый Денежный Поток (ФДП)'
      AND b.group2 = 'Поступления займов (ВГО)'
      AND b.group3 = 'ОЕ Газпром нефть_КЦ (к)'
      AND b.do_short_name <> 'БРД'
    GROUP BY d.do_type, b.do_short_name, b.period_dt, b.month_num, b.report_period;

    INSERT INTO dm_ufkbrd.mart_bdds_data (dds_flag, do_type, do_short_name, dds_period_dt, month_num, report_period, dds_amount, dds_lvf_year)
    SELECT 'Погашение', d.do_type, b.do_short_name, dm_ufkbrd.fn_month_end(b.period_dt), b.month_num, b.report_period,
           sum(b.amount_plan_fact), EXTRACT(YEAR FROM b.period_dt)::integer
    FROM ods.bdds_dashboard_data b
    JOIN dm_ufkbrd.ref_do_vok d ON d.do_short_name = b.do_short_name AND d.flag_bdds = 1
    WHERE b.report_period = v_period AND b.year_num = EXTRACT(YEAR FROM v_today)::integer
      AND b.group_name = 'Финансовый Денежный Поток (ФДП)'
      AND b.group2 = 'Погашение займов (ВГО)'
      AND b.group3 = 'ОЕ Газпром нефть_КЦ (к)'
      AND b.do_short_name <> 'БРД'
    GROUP BY d.do_type, b.do_short_name, b.period_dt, b.month_num, b.report_period;

    INSERT INTO dm_ufkbrd.mart_bdds_data (dds_flag, do_type, do_short_name, dds_period_dt, month_num, report_period, dds_amount, dds_lvf_year)
    SELECT 'ОДП План', d.do_type, b.do_short_name, dm_ufkbrd.fn_month_end(b.period_dt), b.month_num, b.report_period, sum(b.plan_amount), NULL
    FROM ods.bdds_dashboard_data b
    JOIN dm_ufkbrd.ref_do_vok d ON d.do_short_name = b.do_short_name AND d.flag_bdds = 1
    WHERE b.report_period = v_period AND b.year_num = EXTRACT(YEAR FROM v_today)::integer AND b.article_order = 2
    GROUP BY d.do_type, b.do_short_name, b.period_dt, b.month_num, b.report_period;

    INSERT INTO dm_ufkbrd.mart_bdds_data (dds_flag, do_type, do_short_name, dds_period_dt, month_num, report_period, dds_amount, dds_lvf_year)
    SELECT 'ОДП Факт', d.do_type, b.do_short_name, dm_ufkbrd.fn_month_end(b.period_dt), b.month_num, b.report_period, sum(b.amount_plan_fact), NULL
    FROM ods.bdds_dashboard_data b
    JOIN dm_ufkbrd.ref_do_vok d ON d.do_short_name = b.do_short_name AND d.flag_bdds = 1
    WHERE b.report_period = v_period AND b.year_num = EXTRACT(YEAR FROM v_today)::integer
      AND b.article_order = 2 AND b.fact_present_flag = 1
    GROUP BY d.do_type, b.do_short_name, b.period_dt, b.month_num, b.report_period;

    INSERT INTO dm_ufkbrd.mart_bdds_data (dds_flag, do_type, do_short_name, dds_period_dt, month_num, report_period, dds_amount, dds_lvf_year)
    SELECT 'ИДП План', d.do_type, b.do_short_name, dm_ufkbrd.fn_month_end(b.period_dt), b.month_num, b.report_period, sum(b.plan_amount), NULL
    FROM ods.bdds_dashboard_data b
    JOIN dm_ufkbrd.ref_do_vok d ON d.do_short_name = b.do_short_name AND d.flag_bdds = 1
    WHERE b.report_period = v_period AND b.year_num = EXTRACT(YEAR FROM v_today)::integer AND b.article_order = 3
    GROUP BY d.do_type, b.do_short_name, b.period_dt, b.month_num, b.report_period;

    INSERT INTO dm_ufkbrd.mart_bdds_data (dds_flag, do_type, do_short_name, dds_period_dt, month_num, report_period, dds_amount, dds_lvf_year)
    SELECT 'ИДП Факт', d.do_type, b.do_short_name, dm_ufkbrd.fn_month_end(b.period_dt), b.month_num, b.report_period, sum(b.amount_plan_fact), NULL
    FROM ods.bdds_dashboard_data b
    JOIN dm_ufkbrd.ref_do_vok d ON d.do_short_name = b.do_short_name AND d.flag_bdds = 1
    WHERE b.report_period = v_period AND b.year_num = EXTRACT(YEAR FROM v_today)::integer
      AND b.article_order = 3 AND b.fact_present_flag = 1
    GROUP BY d.do_type, b.do_short_name, b.period_dt, b.month_num, b.report_period;

    INSERT INTO dm_ufkbrd.mart_bdds_data (dds_flag, do_type, do_short_name, dds_period_dt, month_num, report_period, dds_amount, dds_lvf_year)
    SELECT 'Платежи по ИД', d.do_type, b.do_short_name, dm_ufkbrd.fn_month_end(b.period_dt), b.month_num, b.report_period,
           round(sum(CASE WHEN b.article_order IN (8,9) THEN b.amount_plan_fact / 1.2 ELSE b.amount_plan_fact * (-1) END), 2), NULL
    FROM ods.bdds_dashboard_data b
    JOIN dm_ufkbrd.ref_do_vok d ON d.do_short_name = b.do_short_name AND d.flag_bdds = 1
    WHERE b.report_period = v_period AND b.year_num = EXTRACT(YEAR FROM v_today)::integer
      AND b.article_order IN (8,9,15) AND b.do_short_name <> 'БРД'
    GROUP BY d.do_type, b.do_short_name, b.period_dt, b.month_num, b.report_period;

    INSERT INTO dm_ufkbrd.mart_bdds_data (dds_flag, do_type, do_short_name, dds_period_dt, month_num, report_period, dds_amount, dds_lvf_year)
    SELECT 'Лимит', NULL, l.do_short_name, dm_ufkbrd.fn_month_end(l.period_dt), NULL, l.report_period, sum(l.limit_amount),
           EXTRACT(YEAR FROM l.period_dt)::integer
    FROM ods.bdds_limits l
    JOIN dm_ufkbrd.ref_do_vok d ON d.do_short_name = l.do_short_name AND d.flag_bdds = 1
    WHERE l.article_order = 8
      AND l.report_period = v_period
      AND EXTRACT(YEAR FROM l.period_dt) = EXTRACT(YEAR FROM v_today)
      AND l.do_short_name <> 'БРД'
    GROUP BY l.do_short_name, l.period_dt, l.report_period;

    -- KPI slice for VOK perimeter
    TRUNCATE TABLE dm_ufkbrd.mart_bdds_kpi;
    INSERT INTO dm_ufkbrd.mart_bdds_kpi (dds_amount, do_name, do_dds, dds_flag, dds_year)
    SELECT sum(dds_amount), do_short_name, do_short_name, dds_flag, dds_lvf_year
    FROM dm_ufkbrd.mart_bdds_data m
    WHERE dds_flag IN ('Долг на начало года', 'Поступление', 'Погашение', 'Налоговая неэффективность')
      AND EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = m.do_short_name AND r.flag_vok = 1)
    GROUP BY do_short_name, dds_flag, dds_lvf_year
    HAVING sum(dds_amount) <> 0;

    -- Outgoing payments for VOK turnover
    TRUNCATE TABLE dm_ufkbrd.mart_dds_for_vok;
    INSERT INTO dm_ufkbrd.mart_dds_for_vok (report_dt, do_name, amount, bdds_group2)
    SELECT
        dm_ufkbrd.fn_month_end(period_dt),
        do_short_name,
        abs(sum(amount_plan_fact)),
        group2
    FROM ods.bdds_form_corr_do f
    WHERE group2 IN (
            'Транспортные за нефть, н/пр, газ (труба, ж/д, авто, вода) (3и лица)',
            'Приобретение нефти, н/п, газа (3и лица)',
            'Энерго и теплообеспечение производства (3и лица)',
            'Прочие платежи (3и лица)',
            'Платежи по Инвестиционной Программе с учетом отсрочек по факторингу (3и лица)'
        )
      AND EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = f.do_short_name AND r.flag_vok = 1)
    GROUP BY period_dt, do_short_name, group2;

    -- SPO extracts (max scenario current year)
    TRUNCATE TABLE dm_ufkbrd.mart_spo_ebitda;
    INSERT INTO dm_ufkbrd.mart_spo_ebitda (year_num, scenario, do_short_name, report_dt, amount)
    SELECT s.year_num, s.scenario, s.entity_alias2, dm_ufkbrd.fn_month_end(s.report_dt), round(sum(s.amount), 2)
    FROM ods.spo_forecast_src s
    JOIN (
        SELECT year_num, max(scenario) AS scenario
        FROM ods.spo_forecast_src
        WHERE year_num = EXTRACT(YEAR FROM v_today)::integer
        GROUP BY year_num
    ) mx ON mx.year_num = s.year_num AND mx.scenario = s.scenario
    WHERE s.account_alias = 'EBITDA для целей УПЦ'
      AND s.counterparty_alias NOT IN ('Итого контрагенты (к)', 'Итого контрагенты (функц) (к)')
      AND EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = s.entity_alias2 AND r.flag_vok = 1)
    GROUP BY s.year_num, s.scenario, s.entity_alias2, s.report_dt;

    TRUNCATE TABLE dm_ufkbrd.mart_spo_capex_fin;
    INSERT INTO dm_ufkbrd.mart_spo_capex_fin (year_num, scenario, do_short_name, report_dt, amount)
    SELECT s.year_num, s.scenario, s.entity_alias2, dm_ufkbrd.fn_month_end(s.report_dt), round(sum(s.amount), 2)
    FROM ods.spo_forecast_src s
    JOIN (
        SELECT year_num, max(scenario) AS scenario
        FROM ods.spo_forecast_src
        WHERE year_num = EXTRACT(YEAR FROM v_today)::integer
        GROUP BY year_num
    ) mx ON mx.year_num = s.year_num AND mx.scenario = s.scenario
    WHERE s.account_alias LIKE 'Финансирование%'
      AND s.account_alias <> 'Финансирование_Дивестиции (инв)'
      AND s.counterparty_alias NOT IN ('Итого контрагенты (к)', 'Итого контрагенты (функц) (к)')
      AND EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = s.entity_alias2 AND r.flag_vok = 1)
    GROUP BY s.year_num, s.scenario, s.entity_alias2, s.report_dt;

    TRUNCATE TABLE dm_ufkbrd.mart_spo_production;
    INSERT INTO dm_ufkbrd.mart_spo_production (year_num, scenario, do_short_name, report_dt, amount)
    SELECT s.year_num, s.scenario, s.entity_alias2, dm_ufkbrd.fn_month_end(s.report_dt), round(sum(s.amount), 2)
    FROM ods.spo_forecast_src s
    JOIN (
        SELECT year_num, max(scenario) AS scenario
        FROM ods.spo_forecast_src
        WHERE year_num = EXTRACT(YEAR FROM v_today)::integer
        GROUP BY year_num
    ) mx ON mx.year_num = s.year_num AND mx.scenario = s.scenario
    WHERE s.account_alias = 'Добыча УВ (с учётом ЖУВ), тыс.тнэ'
      AND s.counterparty_alias NOT IN ('Итого контрагенты (к)', 'Итого контрагенты (функц) (к)')
      AND EXISTS (SELECT 1 FROM dm_ufkbrd.ref_do_vok r WHERE r.do_short_name = s.entity_alias2 AND r.flag_vok = 1)
    GROUP BY s.year_num, s.scenario, s.entity_alias2, s.report_dt;
END;
$$;
