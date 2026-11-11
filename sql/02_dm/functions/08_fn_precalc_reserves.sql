-- 03-05 PreCalc SAP reserves

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_precalc_reserves()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE dm_ufkbrd.mart_reserves;

    INSERT INTO dm_ufkbrd.mart_reserves (
        reserve_kind, do_name, reserves_period_dt, counterparty_name, reserve_amount, reserve_balance_mln
    )
    SELECT
        'Резерв по СД',
        do_name,
        report_dt,
        counterparty_name,
        coalesce(reserve_writeoff_wo_neg, 0) * (-1)
            + coalesce(reserve_repay_wo_neg, 0) * (-1)
            + coalesce(reserve_accrual_wo_neg, 0),
        reserve_eop_wo_neg / 1000000.0
    FROM dm_ufkbrd.stg_arm_kk_reserves r
    WHERE EXISTS (SELECT 1 FROM dm_ufkbrd.ref_vok_do_list l WHERE l.do_short_name = r.do_name);

    -- Article-account-section join
    TRUNCATE TABLE dm_ufkbrd.mart_reserves_article_account;
    INSERT INTO dm_ufkbrd.mart_reserves_article_account (
        period_code, comp_code, gl_account, parent_ergsl, key_410, account_name_src, account_name
    )
    SELECT
        a.period_code,
        a.comp_code,
        a.gl_account,
        a.parent_ergsl,
        a.comp_code || '_' || a.gl_account,
        d.account_name,
        CASE
            WHEN d.account_name LIKE '%ARO%' THEN 'ARO'
            ELSE coalesce(m.valuation_type_to_be, 'не найдено_' || d.account_name)
        END
    FROM ods.sap_article_account_section a
    LEFT JOIN ods.sap_accounts_dict d ON d.gl_account_key = a.gl_account_key
    LEFT JOIN dm_ufkbrd.ref_oa_types m ON m.account_name_as_is = d.account_name
    WHERE a.parent_ergsl LIKE '121%' OR a.parent_ergsl IN ('1430', '1540');

    TRUNCATE TABLE dm_ufkbrd.mart_reserves_z410;
    INSERT INTO dm_ufkbrd.mart_reserves_z410 (
        do_name, comp_code, gl_account, period_dt, deb_cre_lc, credit_lc, debit_lc, key_410
    )
    SELECT
        do_name, comp_code, gl_account, period_dt, deb_cre_lc, credit_lc, debit_lc,
        comp_code || '_' || gl_account
    FROM dm_ufkbrd.stg_zgrccp410_raw r
    WHERE EXISTS (
        SELECT 1 FROM dm_ufkbrd.mart_reserves_article_account a
        WHERE a.key_410 = r.comp_code || '_' || r.gl_account
    );

    -- Cumulative calendar for last 2 years of periods
    TRUNCATE TABLE dm_ufkbrd.mart_reserves_calendar;
    INSERT INTO dm_ufkbrd.mart_reserves_calendar (period_dt, period_cumulative_dt)
    SELECT a.period_dt, b.period_dt
    FROM (SELECT DISTINCT period_dt FROM dm_ufkbrd.mart_reserves_z410) a
    JOIN (SELECT DISTINCT period_dt FROM dm_ufkbrd.mart_reserves_z410) b
      ON b.period_dt >= a.period_dt
     AND EXTRACT(YEAR FROM b.period_dt) >= EXTRACT(YEAR FROM current_date) - 1;
END;
$$;
