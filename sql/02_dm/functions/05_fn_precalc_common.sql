-- 03-01 PreCalc: MTR involvement year, AP factoring, KPD

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_precalc_mtr_involvement_year()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE dm_ufkbrd.mart_mtr_involvement_year;

    INSERT INTO dm_ufkbrd.mart_mtr_involvement_year (data_flag, do_name, period_dt, year_num, amount)
    SELECT
        y.data_flag,
        y.do_name,
        d.period_dt,
        y.year_num,
        y.amount
    FROM (
        SELECT
            data_flag,
            do_name,
            EXTRACT(YEAR FROM period_dt)::integer AS year_num,
            sum(amount) AS amount
        FROM dm_ufkbrd.stg_mtr
        WHERE data_flag IN ('Норматив Расход', 'Норматив Приход')
          AND EXTRACT(YEAR FROM period_dt) > 2020
        GROUP BY data_flag, do_name, EXTRACT(YEAR FROM period_dt)
    ) y
    JOIN (
        SELECT DISTINCT
            EXTRACT(YEAR FROM period_dt)::integer AS year_num,
            period_dt,
            data_flag
        FROM dm_ufkbrd.stg_mtr
        WHERE data_flag IN ('Норматив Расход', 'Норматив Приход')
          AND EXTRACT(YEAR FROM period_dt) > 2020
    ) d ON d.year_num = y.year_num AND d.data_flag = y.data_flag;
END;
$$;

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_precalc_ap_factoring()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE dm_ufkbrd.mart_ap_factoring;

    -- Shelf from 1C ERP
    INSERT INTO dm_ufkbrd.mart_ap_factoring (
        payment_type, do_name, zkhcontr, counterparty_name, gl_account,
        report_dt, year_num, month_num, ap_eop_rub, ap_repay_dt_rub, ap_increase_kt_rub, ap_bop_rub
    )
    SELECT
        'краткосрочный факторинг',
        'Шельф',
        'ИНН' || e.inn,
        e.counterparty_1c,
        e.account_1c,
        dm_ufkbrd.fn_month_end(e.period_dt),
        EXTRACT(YEAR FROM e.period_dt)::integer,
        EXTRACT(MONTH FROM e.period_dt)::integer,
        sum(e.amount_dt_kt),
        sum(e.amount_dt),
        sum(e.amount_kt),
        NULL
    FROM ods.data_1c_erp e
    WHERE e.account_1c = '76.10.1'
      AND e.inn IN ('7727712331', '7729405872', '7802754982')
      AND e.ifrs_entity = 'C1102240'
    GROUP BY e.period_dt, e.inn, e.account_1c, e.counterparty_1c;

    -- Other DOs from ZGRCCP410 (exclude Shelf/Megion)
    INSERT INTO dm_ufkbrd.mart_ap_factoring (
        payment_type, do_name, zkhcontr, counterparty_name, gl_account,
        report_dt, year_num, month_num, ap_eop_rub, ap_repay_dt_rub, ap_increase_kt_rub, ap_bop_rub
    )
    SELECT
        CASE
            WHEN gl_account = '7620639000' THEN 'долгосрочный факторинг'
            WHEN gl_account IN ('7620638000','7620638020','7620638060','7620638010','7620638040','7620638050')
                THEN 'краткосрочный факторинг'
            WHEN gl_account IN ('7620302010','7620302060','7620302080','7620302050','7620302040','7620302020')
                THEN 'комиссия за факторинг'
            ELSE NULL
        END,
        do_name,
        zkhcontr,
        coalesce(c.counterparty_name, zkhcontr),
        gl_account,
        dm_ufkbrd.fn_month_end(period_dt),
        EXTRACT(YEAR FROM period_dt)::integer,
        EXTRACT(MONTH FROM period_dt)::integer,
        sum(deb_cre_lc),
        sum(revenue_turnover),
        sum(debit_turnover),
        NULL
    FROM dm_ufkbrd.stg_zgrccp410_raw r
    LEFT JOIN ods.nsi_counterparties c ON c.zkhcontr = r.zkhcontr
    WHERE gl_account IN (
            '7620639000','7620638000','7620302010','7620302020','7620638020','7620638010',
            '7620638060','7620302060','7620302080','7620638040','7620638050','7620302050','7620302040'
        )
      AND do_name NOT IN ('Не найдено', 'Шельф', 'Мегион')
    GROUP BY
        CASE
            WHEN gl_account = '7620639000' THEN 'долгосрочный факторинг'
            WHEN gl_account IN ('7620638000','7620638020','7620638060','7620638010','7620638040','7620638050')
                THEN 'краткосрочный факторинг'
            WHEN gl_account IN ('7620302010','7620302060','7620302080','7620302050','7620302040','7620302020')
                THEN 'комиссия за факторинг'
            ELSE NULL
        END,
        do_name, zkhcontr, coalesce(c.counterparty_name, zkhcontr), gl_account, period_dt;

    -- Cumulative EOP / BOP from turnover calendar (if available)
    IF EXISTS (SELECT 1 FROM dm_ufkbrd.mart_reserves_calendar LIMIT 1) THEN
        INSERT INTO dm_ufkbrd.mart_ap_factoring (
            payment_type, do_name, zkhcontr, counterparty_name, gl_account,
            report_dt, year_num, month_num, ap_eop_rub, ap_repay_dt_rub, ap_increase_kt_rub, ap_bop_rub
        )
        SELECT
            f.payment_type, f.do_name, f.zkhcontr, f.counterparty_name, f.gl_account,
            c.period_cumulative_dt,
            EXTRACT(YEAR FROM c.period_cumulative_dt)::integer,
            EXTRACT(MONTH FROM c.period_cumulative_dt)::integer,
            abs(sum(f.ap_eop_rub)),
            NULL, NULL, NULL
        FROM dm_ufkbrd.mart_ap_factoring f
        JOIN dm_ufkbrd.mart_reserves_calendar c ON c.period_dt = f.report_dt
        WHERE f.ap_eop_rub IS NOT NULL
        GROUP BY f.payment_type, f.do_name, f.zkhcontr, f.counterparty_name, f.gl_account, c.period_cumulative_dt;

        INSERT INTO dm_ufkbrd.mart_ap_factoring (
            payment_type, do_name, zkhcontr, counterparty_name, gl_account,
            report_dt, year_num, month_num, ap_eop_rub, ap_repay_dt_rub, ap_increase_kt_rub, ap_bop_rub
        )
        SELECT
            f.payment_type, f.do_name, f.zkhcontr, f.counterparty_name, f.gl_account,
            dm_ufkbrd.fn_month_end((c.period_cumulative_dt + INTERVAL '1 month')::date),
            EXTRACT(YEAR FROM (c.period_cumulative_dt + INTERVAL '1 month'))::integer,
            EXTRACT(MONTH FROM (c.period_cumulative_dt + INTERVAL '1 month'))::integer,
            NULL, NULL, NULL,
            abs(sum(f.ap_eop_rub))
        FROM dm_ufkbrd.mart_ap_factoring f
        JOIN dm_ufkbrd.mart_reserves_calendar c ON c.period_dt = f.report_dt
        WHERE f.ap_eop_rub IS NOT NULL
        GROUP BY f.payment_type, f.do_name, f.zkhcontr, f.counterparty_name, f.gl_account, c.period_cumulative_dt;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_precalc_kpd()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE dm_ufkbrd.mart_kpd;

    -- Overdue AR
    INSERT INTO dm_ufkbrd.mart_kpd (
        data_flag, counterparty_inn, contract_number, report_dt, counterparty_name,
        do_name_src, do_name, unit_name, debt_kind, gl_account, comments_txt,
        overdue_debt_rub, reserve_eop_rub, kpd_reserve_rub
    )
    SELECT
        'ДЗ',
        counterparty_inn,
        contract_number,
        dm_ufkbrd.fn_month_start(report_dt),
        counterparty_name,
        do_name_src,
        do_name_src,
        kpd_unit_name,
        debt_kind,
        gl_account,
        comments_txt,
        coalesce(sum(debt_overdue_gt30_rub),0) + coalesce(sum(debt_overdue_5_30_rub),0),
        NULL,
        coalesce(sum(debt_overdue_gt30_rub),0) + coalesce(sum(debt_overdue_5_30_rub),0)
    FROM dm_ufkbrd.stg_arm_kk
    WHERE kpd_unit_name IS NOT NULL
      AND EXTRACT(YEAR FROM report_dt) >= 2024
      AND row_type = 'ДЗ'
      AND (gl_account LIKE '62%' OR (gl_account = '7610609000' AND counterparty_inn = '7725390520'))
      AND (coalesce(debt_overdue_gt30_rub,0) <> 0 OR coalesce(debt_overdue_5_30_rub,0) <> 0)
      AND coalesce(counterparty_type, '') NOT LIKE '%ВЗЛ%'
    GROUP BY
        counterparty_inn, contract_number, dm_ufkbrd.fn_month_start(report_dt),
        counterparty_name, do_name_src, kpd_unit_name, debt_kind, gl_account, comments_txt
    HAVING coalesce(sum(debt_overdue_gt30_rub),0) + coalesce(sum(debt_overdue_5_30_rub),0) <> 0;

    -- Reserves matched to Excel key
    INSERT INTO dm_ufkbrd.mart_kpd (
        data_flag, counterparty_inn, contract_number, report_dt, counterparty_name,
        do_name_src, do_name, unit_name, debt_kind, gl_account, comments_txt,
        overdue_debt_rub, reserve_eop_rub, kpd_reserve_rub
    )
    SELECT
        'Резервы',
        a.counterparty_inn,
        a.contract_number,
        dm_ufkbrd.fn_month_start(a.report_dt),
        a.counterparty_name,
        a.do_name_src,
        a.do_name_src,
        a.kpd_unit_name,
        a.debt_kind,
        a.gl_account,
        a.comments_txt,
        NULL,
        sum(a.reserve_eop_rub),
        sum(a.reserve_eop_rub)
    FROM dm_ufkbrd.stg_arm_kk a
    WHERE a.kpd_unit_name IS NOT NULL
      AND EXTRACT(YEAR FROM a.report_dt) >= 2024
      AND a.row_type = 'Резервы'
      AND coalesce(a.counterparty_type, '') NOT LIKE '%ВЗЛ%'
      AND EXISTS (
            SELECT 1
            FROM ods.nsi_reserves_excel e
            JOIN dm_ufkbrd.ref_do_vok d ON d.do_arm_kk = e.do_name
            WHERE d.do_short_name = a.do_name_src
              AND text(e.counterparty_inn) = text(a.counterparty_inn)
              AND text(e.contract_number) = text(a.contract_number)
              AND round(e.reserve_eop_rub, 2) = round(a.reserve_eop_rub, 2)
      )
    GROUP BY
        a.counterparty_inn, a.contract_number, dm_ufkbrd.fn_month_start(a.report_dt),
        a.counterparty_name, a.do_name_src, a.kpd_unit_name, a.debt_kind, a.gl_account, a.comments_txt;
END;
$$;
