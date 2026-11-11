-- 02-04 ARM KK / 02-05 MTR transforms

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_parse_repay_date(p_raw varchar)
RETURNS date
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_clean varchar;
    v_mon integer;
    v_yy varchar;
BEGIN
    IF p_raw IS NULL OR trim(p_raw) = '' THEN
        RETURN NULL;
    END IF;
    -- Excel serial (~5 digits)
    IF length(ltrim(regexp_replace(p_raw, '[^0-9]', '', 'g'))) = 5
       AND p_raw ~ '^[0-9]+(\.0+)?$' THEN
        RETURN DATE '1899-12-30' + (floor(p_raw::numeric))::integer;
    END IF;
    v_clean := replace(trim(p_raw), chr(160), '');
    IF left(v_clean, 10) ~ '^[0-9]{2}\.[0-9]{2}\.[0-9]{4}$' THEN
        RETURN to_date(left(v_clean, 10), 'DD.MM.YYYY');
    END IF;
    -- e.g. янв'25
    IF position(chr(39) in v_clean) > 0 THEN
        SELECT month_num INTO v_mon
        FROM dm_ufkbrd.ref_month_map
        WHERE lower(month_code) = lower(split_part(trim(v_clean), chr(39), 1))
        LIMIT 1;
        v_yy := split_part(trim(v_clean), chr(39), 2);
        IF v_mon IS NOT NULL AND v_yy ~ '^[0-9]{2}$' THEN
            RETURN make_date(('20' || v_yy)::integer, v_mon, 1);
        END IF;
    END IF;
    RETURN NULL;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_transform_arm_kk()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_year integer := dm_ufkbrd.fn_dashboard_year();
BEGIN
    TRUNCATE TABLE dm_ufkbrd.stg_arm_kk;

    INSERT INTO dm_ufkbrd.stg_arm_kk (
        gl_account, contract_number, counterparty_inn, counterparty_code_aus,
        debt_type, debt_kind, security_flag, counterparty_name, comments_txt,
        counterparty_type, source_system, do_name, do_name_src, do_name_reserves,
        kpd_unit_name, report_dt, row_type, block_name,
        advances_paid_dt_rub, advances_bop_rub, advances_paid_wo_neg, advances_repaid_wo_neg,
        advances_eop_src, advances_eop_rub, debt_total_reval_rub, amount_wo_security_rub,
        debt_current_reval_rub, ap_bop_rub, ap_eop_rub, ap_repay_dt_wo_neg, ap_increase_kt_wo_neg,
        ap_repay_dt_rub, ap_increase_kt_rub, reserve_eop_rub, reserve_bop_wo_neg,
        reserve_eop_wo_neg, reserve_accrual_wo_neg, reserve_writeoff_wo_neg, reserve_repay_wo_neg,
        debt_overdue_reval_rub, block_code, do_code, debt_overdue_gt30_rub, debt_overdue_5_30_rub,
        repay_date_src, repay_dt, payment_type
    )
    SELECT
        a.gl_account,
        a.contract_number,
        a.counterparty_inn,
        a.counterparty_code_aus,
        a.debt_type,
        a.debt_kind,
        a.security_flag,
        a.counterparty_name,
        a.comments_txt,
        a.counterparty_type,
        'АРМ КК',
        d_vok.do_short_name,
        coalesce(d_full.do_short_name, a.do_name),
        d_res.do_short_name,
        d_kpd.vok_kpd_tab,
        a.report_dt,
        a.row_type,
        a.block_name,
        a.advances_paid_dt_rub,
        a.advances_bop_rub,
        a.advances_paid_wo_neg,
        a.advances_repaid_wo_neg,
        a.advances_eop_wo_neg,
        a.advances_net_reserves,
        CASE WHEN a.debt_total_reval_rub > 0 THEN a.debt_total_reval_rub ELSE 0 END,
        a.amount_wo_security_rub,
        a.debt_current_reval_rub,
        a.ap_bop_rub,
        a.ap_eop_rub,
        a.ap_repay_dt_wo_neg,
        a.ap_increase_kt_wo_neg,
        a.ap_repay_dt_rub,
        a.ap_increase_kt_rub,
        a.reserve_eop_rub,
        a.reserve_bop_wo_neg,
        a.reserve_eop_wo_neg,
        a.reserve_accrual_wo_neg,
        a.reserve_writeoff_wo_neg,
        a.reserve_repay_wo_neg,
        CASE WHEN a.debt_total_reval_rub > 0 THEN a.debt_overdue_reval_rub ELSE 0 END,
        a.block_code,
        a.do_code,
        CASE WHEN a.debt_total_reval_rub > 0 THEN a.debt_overdue_gt30_rub ELSE 0 END,
        CASE WHEN a.debt_total_reval_rub > 0 THEN a.debt_overdue_5_30_rub ELSE 0 END,
        a.repay_date_raw,
        dm_ufkbrd.fn_parse_repay_date(a.repay_date_raw),
        CASE
            WHEN a.gl_account = '7620639000' THEN 'долгосрочный факторинг'
            WHEN a.gl_account = '7620638000' THEN 'краткосрочный факторинг'
            WHEN a.gl_account = '7620302010' THEN 'комиссия за факторинг'
            ELSE NULL
        END
    FROM ods.arm_kk_hybrid_final a
    LEFT JOIN dm_ufkbrd.ref_do_vok d_vok
           ON d_vok.do_arm_kk = a.do_name AND d_vok.flag_vok = 1
    LEFT JOIN dm_ufkbrd.ref_do_vok d_full
           ON d_full.do_arm_kk = a.do_name
    LEFT JOIN dm_ufkbrd.ref_do_vok d_res
           ON d_res.do_arm_kk = a.do_name AND d_res.flag_reserves = 1
    LEFT JOIN dm_ufkbrd.ref_do_vok d_kpd
           ON d_kpd.do_arm_kk = a.do_name AND d_kpd.vok_kpd_tab IS NOT NULL
    WHERE EXTRACT(YEAR FROM a.report_dt) >= v_year;

    TRUNCATE TABLE dm_ufkbrd.stg_arm_kk_reserves;
    INSERT INTO dm_ufkbrd.stg_arm_kk_reserves (
        counterparty_name, report_dt, block_name, do_name, debt_kind, debt_type,
        reserve_bop_wo_neg, reserve_eop_wo_neg, reserve_accrual_wo_neg,
        reserve_writeoff_wo_neg, reserve_repay_wo_neg
    )
    SELECT
        counterparty_name,
        report_dt,
        block_name,
        do_name_reserves,
        debt_kind,
        debt_type,
        sum(reserve_bop_wo_neg),
        sum(reserve_eop_wo_neg),
        sum(reserve_accrual_wo_neg),
        sum(reserve_writeoff_wo_neg),
        sum(reserve_repay_wo_neg)
    FROM dm_ufkbrd.stg_arm_kk
    WHERE do_name_reserves IS NOT NULL
      AND row_type = 'Резервы'
      AND block_name IN (
            'БРД ДГиЭ ГПН',
            'БРД ДО/Дирекция ГРР',
            'БРД ДО/Дирекция по добыче',
            'БРД ДО/Дирекция по крупным проектам',
            'БРД ДО/Дирекция по технологиям',
            'БРД ДО/Иностранные проекты',
            'БРД ДО/Нефтесервисы',
            'БРД подр-я ГПН',
            'БРШП ДО'
      )
    GROUP BY
        counterparty_name, report_dt, block_name, do_name_reserves, debt_kind, debt_type;
END;
$$;

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_transform_mtr()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_year integer := dm_ufkbrd.fn_dashboard_year();
BEGIN
    TRUNCATE TABLE dm_ufkbrd.stg_mtr;

    INSERT INTO dm_ufkbrd.stg_mtr (
        source_system, do_name, data_flag, period_dt, material, counterparty_code,
        counterparty_type, project_name, nez_flag, stock_category_code, amount,
        main_account, be_code, mtr_vna_flag, mtr_map_filter_l1, nez_storage_term,
        data_slice, counterparty_dds_code, counterparty_kps, share_in_gpn
    )
    SELECT
        'Контроль МТР',
        d.do_short_name,
        m.data_flag,
        m.period_dt,
        m.material,
        m.counterparty_code,
        m.counterparty_type,
        m.project_name,
        m.nez_flag,
        m.stock_category_code,
        m.amount,
        m.main_account,
        m.be_code,
        CASE
            WHEN m.main_account LIKE '#/10%' OR m.main_account LIKE '#/41%' THEN 'БЕЗ ВНА'
            ELSE 'Остальное'
        END,
        m.mtr_map_filter_l1,
        m.nez_storage_term,
        m.data_slice,
        m.counterparty_dds_code,
        m.counterparty_kps,
        m.share_in_gpn
    FROM ods.mtr_to_vok m
    LEFT JOIN dm_ufkbrd.ref_do_vok d
           ON d.be_code = m.be_code AND d.flag_vok = 1
    WHERE d.do_short_name IS NOT NULL
      AND (EXTRACT(YEAR FROM m.period_dt) >= v_year OR coalesce(m.data_slice, '') <> '');
END;
$$;
