-- 02-02 Transform SAP ZGRCCP410 / ZKHDCP050

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_transform_zgrccp410()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_year integer := dm_ufkbrd.fn_dashboard_year();
BEGIN
    TRUNCATE TABLE dm_ufkbrd.stg_zgrccp410_raw;

    INSERT INTO dm_ufkbrd.stg_zgrccp410_raw (
        counterparty_type, counterparty_vgo_flag, do_name, zkhcontr, customer,
        comp_code, doc_date, revenue_turnover, credit_lc, gl_account, period_dt,
        period_filter, fiscper, debit_turnover, debit_lc, deb_cre_lc,
        material, quantity, zkhkglacc
    )
    SELECT
        CASE
            WHEN s.zkhcontr = '0000008602' THEN 'ВГО'
            ELSE coalesce(v.counterparty_type, 'Сторонний')
        END,
        CASE
            WHEN s.zkhcontr = '0000008602' THEN 1
            WHEN vgo.counterparty_code IS NOT NULL THEN 1
            ELSE 0
        END,
        coalesce(d.do_short_name, 'Не найдено'),
        s.zkhcontr,
        s.customer,
        s.comp_code,
        s.doc_date,
        s.credit_lc,
        s.credit_lc,
        s.gl_account,
        dm_ufkbrd.fn_fiscper_to_date(s.fiscper),
        s.fiscper,
        s.fiscper,
        s.debit_lc,
        s.debit_lc,
        s.deb_cre_lc,
        s.material,
        s.quantity,
        s.zkhkglacc
    FROM ods.sap_zgrccp410 s
    LEFT JOIN dm_ufkbrd.ref_do_vok d
           ON d.be_code = s.comp_code AND d.flag_vok = 1
    LEFT JOIN ods.sap_vgo_vzl_dict v
           ON dm_ufkbrd.fn_pad10(v.counterparty_code) = dm_ufkbrd.fn_pad10(s.zkhcontr)
          AND v.period_dt = dm_ufkbrd.fn_fiscper_to_date(s.fiscper)
    LEFT JOIN LATERAL (
        SELECT v2.counterparty_code
        FROM ods.sap_vgo_vzl_dict v2
        LEFT JOIN dm_ufkbrd.ref_vgo_counterparties sp
               ON sp.counterparty_number = dm_ufkbrd.fn_pad10(v2.counterparty_code)
        WHERE dm_ufkbrd.fn_pad10(v2.counterparty_code) = dm_ufkbrd.fn_pad10(s.zkhcontr)
          AND v2.period_dt = dm_ufkbrd.fn_fiscper_to_date(s.fiscper)
          AND (
                CASE
                    WHEN sp.transfer_to_sp_dt IS NOT NULL
                         AND sp.transfer_to_sp_dt > dm_ufkbrd.fn_fiscper_to_date(s.fiscper)
                        THEN 'ВГО'
                    WHEN sp.transfer_to_sp_dt IS NOT NULL
                         AND sp.transfer_to_sp_dt <= dm_ufkbrd.fn_fiscper_to_date(s.fiscper)
                        THEN 'Сторонний'
                    ELSE coalesce(
                        (SELECT corr_type FROM dm_ufkbrd.ref_do_vok r WHERE r.sap_number = s.zkhcontr LIMIT 1),
                        v2.counterparty_type
                    )
                END
              ) = 'ВГО'
        LIMIT 1
    ) vgo ON TRUE;

    TRUNCATE TABLE dm_ufkbrd.stg_zgrccp410_revenue;
    INSERT INTO dm_ufkbrd.stg_zgrccp410_revenue (do_name, revenue_turnover, period_dt, yamal_ka_flag)
    SELECT
        do_name,
        round(sum(revenue_turnover), 2),
        period_dt,
        CASE
            WHEN zkhcontr = '0000087992' AND do_name = 'Ямал' AND period_dt = DATE '2022-12-31' THEN 1
            ELSE 0
        END
    FROM dm_ufkbrd.stg_zgrccp410_raw
    WHERE gl_account LIKE '901%'
      AND counterparty_vgo_flag = 0
      AND zkhcontr IS NOT NULL
      AND zkhcontr <> ''
      AND EXTRACT(YEAR FROM period_dt) >= v_year
      AND do_name <> 'Не найдено'
    GROUP BY
        do_name,
        period_dt,
        CASE
            WHEN zkhcontr = '0000087992' AND do_name = 'Ямал' AND period_dt = DATE '2022-12-31' THEN 1
            ELSE 0
        END;
END;
$$;

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_transform_zkhdcp050()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_year integer := dm_ufkbrd.fn_dashboard_year();
BEGIN
    TRUNCATE TABLE dm_ufkbrd.stg_zkhdcp050_liquidity;

    -- Primary: INFOPROV ZKHDDP102 / STAT 03A
    INSERT INTO dm_ufkbrd.stg_zkhdcp050_liquidity (
        data_flag, amount, do_name, period_dt, amount_flag, fs_line
    )
    SELECT
        '03A',
        sum(s.zkhsalend),
        coalesce(d.do_short_name, 'Не найдено'),
        dm_ufkbrd.fn_fiscper_to_date(s.fiscper),
        CASE
            WHEN s.gl_fsitem IN ('1236','1238') THEN '1236_1238'
            WHEN s.gl_fsitem IN ('1521','1522') THEN '1521_1522'
            WHEN s.gl_fsitem IN ('1523','1524') THEN '1523_1524'
            WHEN s.gl_fsitem IN ('1510','1410') THEN '1510_1410'
            WHEN s.gl_fsitem = '1529' THEN '1529'
            WHEN s.gl_fsitem IN ('1241','1250') THEN 'Остатки на начало'
            ELSE NULL
        END,
        s.gl_fsitem
    FROM ods.sap_zkhdcp050 s
    LEFT JOIN dm_ufkbrd.ref_do_vok d ON d.be_code = s.comp_code AND d.flag_vok = 1
    WHERE s.infoprov = 'ZKHDDP102'
      AND s.zkhdstat = '03A'
    GROUP BY
        coalesce(d.do_short_name, 'Не найдено'),
        dm_ufkbrd.fn_fiscper_to_date(s.fiscper),
        CASE
            WHEN s.gl_fsitem IN ('1236','1238') THEN '1236_1238'
            WHEN s.gl_fsitem IN ('1521','1522') THEN '1521_1522'
            WHEN s.gl_fsitem IN ('1523','1524') THEN '1523_1524'
            WHEN s.gl_fsitem IN ('1510','1410') THEN '1510_1410'
            WHEN s.gl_fsitem = '1529' THEN '1529'
            WHEN s.gl_fsitem IN ('1241','1250') THEN 'Остатки на начало'
            ELSE NULL
        END,
        s.gl_fsitem
    HAVING sum(s.zkhsalend) <> 0
       AND coalesce(d.do_short_name, 'Не найдено') <> 'Не найдено'
       AND EXTRACT(YEAR FROM dm_ufkbrd.fn_fiscper_to_date(s.fiscper)) >= v_year;

    -- Fallback: INFOPROV ZKHDDC117 / STAT 01I for missing DO+period keys
    INSERT INTO dm_ufkbrd.stg_zkhdcp050_liquidity (
        data_flag, amount, do_name, period_dt, amount_flag, fs_line
    )
    SELECT
        '01I',
        sum(s.zkhsalend),
        coalesce(d.do_short_name, 'Не найдено'),
        dm_ufkbrd.fn_fiscper_to_date(s.fiscper),
        CASE
            WHEN s.gl_fsitem IN ('1236','1238') THEN '1236_1238'
            WHEN s.gl_fsitem IN ('1521','1522') THEN '1521_1522'
            WHEN s.gl_fsitem IN ('1523','1524') THEN '1523_1524'
            WHEN s.gl_fsitem IN ('1510','1410') THEN '1510_1410'
            WHEN s.gl_fsitem = '1529' THEN '1529'
            WHEN s.gl_fsitem IN ('1241','1250') THEN 'Остатки на начало'
            ELSE NULL
        END,
        s.gl_fsitem
    FROM ods.sap_zkhdcp050 s
    LEFT JOIN dm_ufkbrd.ref_do_vok d ON d.be_code = s.comp_code AND d.flag_vok = 1
    WHERE s.infoprov = 'ZKHDDC117'
      AND s.zkhdstat = '01I'
      AND NOT EXISTS (
            SELECT 1
            FROM dm_ufkbrd.stg_zkhdcp050_liquidity x
            WHERE x.do_name = coalesce(d.do_short_name, 'Не найдено')
              AND x.period_dt = dm_ufkbrd.fn_fiscper_to_date(s.fiscper)
      )
    GROUP BY
        coalesce(d.do_short_name, 'Не найдено'),
        dm_ufkbrd.fn_fiscper_to_date(s.fiscper),
        CASE
            WHEN s.gl_fsitem IN ('1236','1238') THEN '1236_1238'
            WHEN s.gl_fsitem IN ('1521','1522') THEN '1521_1522'
            WHEN s.gl_fsitem IN ('1523','1524') THEN '1523_1524'
            WHEN s.gl_fsitem IN ('1510','1410') THEN '1510_1410'
            WHEN s.gl_fsitem = '1529' THEN '1529'
            WHEN s.gl_fsitem IN ('1241','1250') THEN 'Остатки на начало'
            ELSE NULL
        END,
        s.gl_fsitem
    HAVING sum(s.zkhsalend) <> 0
       AND coalesce(d.do_short_name, 'Не найдено') <> 'Не найдено'
       AND EXTRACT(YEAR FROM dm_ufkbrd.fn_fiscper_to_date(s.fiscper)) >= v_year;

    TRUNCATE TABLE dm_ufkbrd.stg_zkhdcp050_taxes;
    INSERT INTO dm_ufkbrd.stg_zkhdcp050_taxes (period_dt, do_name, amount_eop)
    SELECT period_dt, do_name, sum(amount)
    FROM dm_ufkbrd.stg_zkhdcp050_liquidity
    WHERE fs_line = '1524'
    GROUP BY period_dt, do_name;
END;
$$;
