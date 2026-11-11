-- 03-04 PreCalc SAP for UFKBRD: unified VOK UO fact + turnover calendar

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_precalc_vok_uo()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_year integer := dm_ufkbrd.fn_dashboard_year();
    v_today date := dm_ufkbrd.fn_as_of_date();
BEGIN
    TRUNCATE TABLE dm_ufkbrd.mart_vok_uo;

    -- AR EOP / BOP
    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, counterparty_name, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount)
    SELECT source_system, counterparty_name, report_dt, do_name, 'ВОК', 'УО', 'ДЗ на конец',
           sum(debt_total_reval_rub)
    FROM dm_ufkbrd.stg_arm_kk
    WHERE do_name IS NOT NULL AND row_type = 'ДЗ'
    GROUP BY source_system, counterparty_name, report_dt, do_name;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount)
    SELECT source_system, dm_ufkbrd.fn_month_end((report_dt + INTERVAL '1 month')::date), do_name, 'ВОК', 'УО', 'ДЗ на начало',
           sum(debt_total_reval_rub)
    FROM dm_ufkbrd.stg_arm_kk
    WHERE do_name IS NOT NULL AND row_type = 'ДЗ'
    GROUP BY source_system, report_dt, do_name;

    -- Advances
    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount)
    SELECT source_system, report_dt, do_name, 'ВОК', 'УО', 'Авансы на начало', sum(advances_bop_rub)
    FROM dm_ufkbrd.stg_arm_kk WHERE do_name IS NOT NULL AND row_type = 'Авансы'
    GROUP BY source_system, report_dt, do_name;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, counterparty_name, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount, mtr_map_filter_l1)
    SELECT source_system, counterparty_name, report_dt, do_name, 'ВОК', 'УО', 'Авансы на конец', sum(advances_eop_rub), debt_type
    FROM dm_ufkbrd.stg_arm_kk WHERE do_name IS NOT NULL AND row_type = 'Авансы'
    GROUP BY source_system, counterparty_name, report_dt, do_name, debt_type, security_flag;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, counterparty_name, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount)
    SELECT source_system, counterparty_name, report_dt, do_name, 'ВОК', 'УО', 'Авансы необеспеченные', sum(amount_wo_security_rub)
    FROM dm_ufkbrd.stg_arm_kk WHERE do_name IS NOT NULL AND row_type = 'Авансы'
    GROUP BY source_system, counterparty_name, report_dt, do_name;

    -- Overdue AR
    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount)
    SELECT source_system, report_dt, do_name, 'ВОК', 'УО', 'ПДЗ на конец', sum(debt_overdue_reval_rub)
    FROM dm_ufkbrd.stg_arm_kk WHERE do_name IS NOT NULL AND row_type = 'ДЗ'
    GROUP BY source_system, report_dt, do_name;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount)
    SELECT source_system, report_dt, do_name, 'ВОК', 'УО', 'ПДЗ на конец > 30 дней', sum(debt_overdue_gt30_rub)
    FROM dm_ufkbrd.stg_arm_kk WHERE do_name IS NOT NULL AND row_type = 'ДЗ'
    GROUP BY source_system, report_dt, do_name;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, counterparty_name, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount)
    SELECT source_system, counterparty_name, report_dt, do_name, 'ВОК', 'УО', 'ПДЗ на конец > 5 дней',
           coalesce(sum(debt_overdue_gt30_rub),0) + coalesce(sum(debt_overdue_5_30_rub),0)
    FROM dm_ufkbrd.stg_arm_kk WHERE do_name IS NOT NULL AND row_type = 'ДЗ'
    GROUP BY source_system, counterparty_name, report_dt, do_name;

    -- AP
    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount)
    SELECT source_system, report_dt, do_name, 'ВОК', 'УО', 'КЗ на начало', sum(ap_bop_rub)
    FROM dm_ufkbrd.stg_arm_kk WHERE do_name IS NOT NULL AND row_type = 'КЗ'
    GROUP BY source_system, report_dt, do_name;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, counterparty_name, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount, mtr_map_filter_l1)
    SELECT source_system, counterparty_name, report_dt, do_name, 'ВОК', 'УО', 'КЗ на конец', sum(ap_eop_rub), debt_type
    FROM dm_ufkbrd.stg_arm_kk WHERE do_name IS NOT NULL AND row_type = 'КЗ'
    GROUP BY source_system, counterparty_name, report_dt, do_name, debt_type;

    -- Advances to exclude from AP turnover
    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount, mtr_map_filter_l1)
    SELECT source_system, report_dt, do_name, 'ВОК', 'УО', 'Авансы к исключению на начало', sum(ap_bop_rub), debt_type
    FROM dm_ufkbrd.stg_arm_kk
    WHERE do_name IS NOT NULL AND row_type = 'КЗ' AND (gl_account LIKE '62.%' OR gl_account LIKE '624%')
    GROUP BY source_system, report_dt, do_name, debt_type;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount, mtr_map_filter_l1)
    SELECT source_system, report_dt, do_name, 'ВОК', 'УО', 'Авансы к исключению на конец', sum(ap_eop_rub), debt_type
    FROM dm_ufkbrd.stg_arm_kk
    WHERE do_name IS NOT NULL AND row_type = 'КЗ' AND (gl_account LIKE '62.%' OR gl_account LIKE '624%')
    GROUP BY source_system, report_dt, do_name, debt_type;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, counterparty_name, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount)
    SELECT source_system, counterparty_name, report_dt, do_name, 'ВОК', 'УО', 'Авансы Норд в адрес Ямал', sum(ap_eop_rub)
    FROM dm_ufkbrd.stg_arm_kk
    WHERE (row_type = 'КЗ' AND do_name = 'Ямал' AND gl_account LIKE '624%')
       OR (row_type = 'КЗ' AND do_name = 'Ангара' AND gl_account = '62.02' AND counterparty_inn = '7604105513')
    GROUP BY source_system, counterparty_name, report_dt, do_name;

    -- MTR stock / norms / flow (with and without VNA)
    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount, mtr_flag)
    SELECT source_system, period_dt, do_name, 'ВОК', 'УО', 'Запас МТР на начало', sum(amount), 'МТР с учетом ВНА'
    FROM dm_ufkbrd.stg_mtr WHERE amount <> 0 AND data_flag = 'Запас МТР на начало'
    GROUP BY source_system, period_dt, do_name;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount, mtr_flag, vok_project, mtr_map_filter_l1)
    SELECT source_system, period_dt, do_name, 'ВОК', 'УО', 'Запас МТР на конец', sum(amount), 'МТР с учетом ВНА', project_name, mtr_map_filter_l1
    FROM dm_ufkbrd.stg_mtr WHERE amount <> 0 AND data_flag = 'Запас МТР на конец'
    GROUP BY source_system, period_dt, do_name, project_name, mtr_map_filter_l1;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount, mtr_flag)
    SELECT source_system, period_dt, do_name, 'ВОК', 'УО', 'Норматив Запас МТР на начало', sum(amount), 'МТР с учетом ВНА'
    FROM dm_ufkbrd.stg_mtr WHERE amount <> 0 AND data_flag = 'Норматив Запас МТР на начало'
    GROUP BY source_system, period_dt, do_name;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount, mtr_flag, vok_project)
    SELECT source_system, period_dt, do_name, 'ВОК', 'УО', 'Норматив Запас МТР на конец', sum(amount), 'МТР с учетом ВНА', project_name
    FROM dm_ufkbrd.stg_mtr WHERE amount <> 0 AND data_flag = 'Норматив Запас МТР на конец'
    GROUP BY source_system, period_dt, do_name, project_name;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount, nez_flag, mtr_flag)
    SELECT source_system, period_dt, do_name, 'ВОК', 'УО', 'Расход МТР за период', abs(sum(amount)), nez_flag, 'МТР с учетом ВНА'
    FROM dm_ufkbrd.stg_mtr WHERE amount <> 0 AND data_flag = 'РасходКорр'
    GROUP BY source_system, period_dt, do_name, nez_flag;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount, nez_flag, mtr_flag)
    SELECT source_system, period_dt, do_name, 'ВОК', 'УО', 'Расход МТР за период', abs(sum(amount)), nez_flag, 'МТР без учета ВНА'
    FROM dm_ufkbrd.stg_mtr WHERE mtr_vna_flag = 'БЕЗ ВНА' AND amount <> 0 AND data_flag = 'РасходКорр'
    GROUP BY source_system, period_dt, do_name, nez_flag;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount, mtr_flag)
    SELECT 'МТР', period_dt, do_name, 'ВОК', 'УО', 'Расход МТР за период Годовой', amount, 'МТР с учетом ВНА'
    FROM dm_ufkbrd.mart_mtr_involvement_year WHERE data_flag = 'Норматив Расход';

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount, mtr_flag)
    SELECT source_system, period_dt, do_name, 'ВОК', 'УО', 'Норматив Расход МТР за период', abs(sum(amount)), 'МТР с учетом ВНА'
    FROM dm_ufkbrd.stg_mtr WHERE amount <> 0 AND data_flag = 'Норматив Расход'
    GROUP BY source_system, period_dt, do_name;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, data_flag, amount)
    SELECT source_system, period_dt, do_name, 'Норматив Приход МТР за период', sum(amount)
    FROM dm_ufkbrd.stg_mtr
    WHERE amount <> 0 AND data_flag = 'Норматив Приход' AND EXTRACT(YEAR FROM period_dt) > 2020
    GROUP BY source_system, period_dt, do_name;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount, mtr_flag)
    SELECT source_system, period_dt, do_name, 'ВОК', 'УО', 'Приход МТР за период', sum(amount), 'МТР с учетом ВНА'
    FROM dm_ufkbrd.stg_mtr
    WHERE amount <> 0 AND data_flag = 'Приход' AND EXTRACT(YEAR FROM period_dt) > 2020
    GROUP BY source_system, period_dt, do_name;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount, mtr_flag)
    SELECT 'МТР', period_dt, do_name, 'ВОК', 'УО', 'Приход МТР за период Годовой', amount, 'МТР с учетом ВНА'
    FROM dm_ufkbrd.mart_mtr_involvement_year WHERE data_flag = 'Норматив Приход';

    -- NEZ
    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount, mtr_flag, vok_project, nez_gt3y_flag)
    SELECT source_system, period_dt, do_name, 'ВОК', 'УО', 'НЭЗ МТР на конец', sum(amount), 'МТР с учетом ВНА', project_name,
           CASE WHEN nez_storage_term = 'Более трёх' THEN 1 ELSE 0 END
    FROM dm_ufkbrd.stg_mtr
    WHERE nez_flag = 1 AND amount <> 0 AND data_flag = 'Запас МТР на конец'
    GROUP BY source_system, period_dt, do_name, project_name, CASE WHEN nez_storage_term = 'Более трёх' THEN 1 ELSE 0 END;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount, mtr_flag, vok_project, nez_gt3y_flag)
    SELECT source_system, period_dt, do_name, 'ВОК', 'УО', 'НЭЗ МТР на конец', sum(amount), 'МТР без учета ВНА', project_name,
           CASE WHEN nez_storage_term = 'Более трёх' THEN 1 ELSE 0 END
    FROM dm_ufkbrd.stg_mtr
    WHERE mtr_vna_flag = 'БЕЗ ВНА' AND nez_flag = 1 AND amount <> 0 AND data_flag = 'Запас МТР на конец'
    GROUP BY source_system, period_dt, do_name, project_name, CASE WHEN nez_storage_term = 'Более трёх' THEN 1 ELSE 0 END;

    INSERT INTO dm_ufkbrd.mart_vok_uo (period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount)
    SELECT make_date(left(data_slice, 4)::integer, 12, 31), do_name, 'ВОК', 'УО', 'НЭЗ МТР на конец Прогноз', sum(amount)
    FROM dm_ufkbrd.stg_mtr
    WHERE amount <> 0 AND data_flag = 'Прогноз НЭЗ МетодПост'
      AND data_slice IN ('202303. БП', '202403. БП', '202503. БП')
    GROUP BY data_slice, do_name;

    -- MTR without VNA stock
    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount, mtr_flag, vok_project)
    SELECT source_system, period_dt, do_name, 'ВОК', 'УО', 'Запас МТР на конец', sum(amount), 'МТР без учета ВНА', project_name
    FROM dm_ufkbrd.stg_mtr
    WHERE mtr_vna_flag = 'БЕЗ ВНА' AND amount <> 0 AND data_flag = 'Запас МТР на конец'
    GROUP BY source_system, period_dt, do_name, project_name;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount, mtr_flag)
    SELECT source_system, period_dt, do_name, 'ВОК', 'УО', 'Запас МТР на начало', sum(amount), 'МТР без учета ВНА'
    FROM dm_ufkbrd.stg_mtr
    WHERE mtr_vna_flag = 'БЕЗ ВНА' AND amount <> 0 AND data_flag = 'Запас МТР на начало'
    GROUP BY source_system, period_dt, do_name;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount, mtr_flag, vok_project)
    SELECT source_system, period_dt, do_name, 'ВОК', 'УО', 'Норматив Запас МТР на конец', sum(amount), 'МТР без учета ВНА', project_name
    FROM dm_ufkbrd.stg_mtr
    WHERE mtr_vna_flag = 'БЕЗ ВНА' AND amount <> 0 AND data_flag = 'Норматив Запас МТР на конец'
    GROUP BY source_system, period_dt, do_name, project_name;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount, mtr_flag)
    SELECT source_system, period_dt, do_name, 'ВОК', 'УО', 'Норматив Запас МТР на начало', sum(amount), 'МТР без учета ВНА'
    FROM dm_ufkbrd.stg_mtr
    WHERE mtr_vna_flag = 'БЕЗ ВНА' AND amount <> 0 AND data_flag = 'Норматив Запас МТР на начало'
    GROUP BY source_system, period_dt, do_name;

    -- Losses / financing / NVI
    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, material, counterparty_code, counterparty_type, do_name, sheet_name, uo_ifrs_flag, data_flag, amount, expense_flag, losses_vgo_flag)
    SELECT source_system, period_dt, material, counterparty_code, counterparty_type, do_name, 'ВОК', 'УО', 'Потери', sum(amount),
           CASE
               WHEN data_flag LIKE 'Доходы%' THEN 'Реализация МТР кредит'
               WHEN data_flag LIKE 'Стоимость%' THEN 'Реализация МТР дебет'
               ELSE data_flag
           END,
           1
    FROM dm_ufkbrd.stg_mtr
    WHERE amount <> 0
      AND (data_flag IN ('Потери (Инвентаризация)', 'Потери (Списание)', 'Резервы кредит', 'Прочее выбытие МТР')
           OR data_flag LIKE 'Доходы%' OR data_flag LIKE 'Стоимость%')
    GROUP BY source_system, period_dt, material, counterparty_code, counterparty_type, do_name, data_flag;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, data_flag, period_dt, do_name, sheet_name, uo_ifrs_flag, amount)
    SELECT source_system, data_flag, period_dt, do_name, 'ВОК', 'УО',
           (sum(amount) - sum(amount) * min(share_in_gpn)) * (-1)
    FROM dm_ufkbrd.stg_mtr
    WHERE amount <> 0 AND data_flag = 'Финансирование'
    GROUP BY source_system, data_flag, do_name, be_code, period_dt, counterparty_dds_code, counterparty_kps, share_in_gpn;

    INSERT INTO dm_ufkbrd.mart_vok_uo (data_slice, source_system, data_flag, period_dt, do_name, sheet_name, uo_ifrs_flag, amount)
    SELECT data_slice, source_system, data_flag, dm_ufkbrd.fn_year_end(v_today), do_name, 'ВОК', 'УО', sum(amount)
    FROM dm_ufkbrd.stg_mtr
    WHERE amount <> 0 AND data_flag = 'Лимит финансирования СИП на МТО'
      AND data_slice IN ('БП/СИП 2023', 'БП/СИП 2024')
    GROUP BY data_slice, source_system, data_flag, do_name, period_dt;

    INSERT INTO dm_ufkbrd.mart_vok_uo (data_slice, source_system, data_flag, period_dt, do_name, sheet_name, uo_ifrs_flag, amount)
    SELECT data_slice, source_system, data_flag, dm_ufkbrd.fn_year_end(v_today), do_name, 'ВОК', 'УО', sum(amount)
    FROM dm_ufkbrd.stg_mtr
    WHERE amount <> 0
      AND data_flag = 'Потребность в МТР под программу БП/СИП'
      AND data_slice IN ('БП/СИП 2023', 'БП/СИП 2024')
      AND mtr_map_filter_l1 IN ('OPEX', 'CAPEX')
    GROUP BY data_slice, source_system, do_name, data_flag, period_dt;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount, mtr_flag)
    SELECT source_system, period_dt, do_name, 'ВОК', 'УО', 'Запас МТР на конец НВИ', sum(amount), 'МТР с учетом ВНА'
    FROM dm_ufkbrd.stg_mtr
    WHERE amount <> 0 AND stock_category_code IN ('NV','NL') AND data_flag = 'Запас МТР на конец'
    GROUP BY source_system, period_dt, do_name;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount, mtr_flag)
    SELECT source_system, period_dt, do_name, 'ВОК', 'УО', 'Запас МТР на конец НВИ', sum(amount), 'МТР без учета ВНА'
    FROM dm_ufkbrd.stg_mtr
    WHERE mtr_vna_flag = 'БЕЗ ВНА' AND amount <> 0 AND stock_category_code IN ('NV','NL') AND data_flag = 'Запас МТР на конец'
    GROUP BY source_system, period_dt, do_name;

    -- Revenue
    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount)
    SELECT 'SAP витрина ZGRCCP410', period_dt, do_name, 'ВОК', 'УО', 'Выручка за период', abs(sum(revenue_turnover))
    FROM dm_ufkbrd.stg_zgrccp410_revenue
    WHERE yamal_ka_flag = 0
    GROUP BY do_name, period_dt;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount)
    SELECT 'SAP витрина ZKHDCP056_QRY001',
           dm_ufkbrd.fn_month_end(make_date(substring(fiscal_year_period from 5 for 4)::integer, right(fiscal_year_period, 2)::integer, 1)),
           'Мегион', 'ВОК', 'УО', 'Выручка за период', abs(sum(amount_dt_kt))
    FROM ods.sap_zkhdcp056_qry001
    WHERE account_1c LIKE '90.01%'
    GROUP BY substring(fiscal_year_period from 5 for 4), right(fiscal_year_period, 2);

    -- DDS outgoing
    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount, bdds_group2)
    SELECT 'АРМ БДДС', report_dt, do_name, 'ВОК', 'УО', 'Исходящие платежи ДДС', amount, bdds_group2
    FROM dm_ufkbrd.mart_dds_for_vok;

    -- Tax AP
    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount)
    SELECT 'ZKHDCP050', period_dt, do_name, 'ВОК', 'УО', 'КЗ налоги на конец', abs(amount_eop)
    FROM dm_ufkbrd.stg_zkhdcp050_taxes
    WHERE amount_eop <> 0;

    -- Benchmark SPO
    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount)
    SELECT 'СПО', report_dt, do_short_name, 'ВОК', 'УО', 'EBITDA СПО', amount FROM dm_ufkbrd.mart_spo_ebitda;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount)
    SELECT 'СПО', report_dt, do_short_name, 'ВОК', 'УО', 'Финансирование CAPEX СПО', (-1) * amount FROM dm_ufkbrd.mart_spo_capex_fin;

    INSERT INTO dm_ufkbrd.mart_vok_uo (source_system, period_dt, do_name, sheet_name, uo_ifrs_flag, data_flag, amount)
    SELECT 'СПО', report_dt, do_short_name, 'ВОК', 'УО', 'Добыча УВ, тыс.тнэ', amount FROM dm_ufkbrd.mart_spo_production;

    -- Factoring
    INSERT INTO dm_ufkbrd.mart_vok_uo (
        sheet_name, uo_ifrs_flag, data_flag, do_name, period_dt, counterparty_name, amount,
        factoring_payment_type, factoring_gl_account, factoring_ap_repay, factoring_ap_increase,
        factoring_ap_bop, factoring_ap_eop
    )
    SELECT 'ВОК', 'УО', 'Факторинг', do_name, report_dt, counterparty_name, sum(ap_eop_rub),
           payment_type, gl_account, sum(ap_repay_dt_rub), sum(ap_increase_kt_rub), sum(ap_bop_rub), sum(ap_eop_rub)
    FROM dm_ufkbrd.mart_ap_factoring
    GROUP BY do_name, report_dt, counterparty_name, payment_type, gl_account
    HAVING coalesce(sum(ap_repay_dt_rub),0) <> 0
        OR coalesce(sum(ap_increase_kt_rub),0) <> 0
        OR coalesce(sum(ap_bop_rub),0) <> 0
        OR coalesce(sum(ap_eop_rub),0) <> 0;

    -- Enrich do_type / formula group / filter year
    UPDATE dm_ufkbrd.mart_vok_uo v
    SET do_type = d.do_type,
        vok_formula_group = CASE
            WHEN v.data_flag = 'Запас МТР на конец' AND v.mtr_flag = 'МТР с учетом ВНА' THEN 'МТР'
            WHEN v.data_flag = 'КЗ на конец' THEN 'КЗ'
            WHEN v.data_flag = 'Авансы на конец' THEN 'Авансы'
            WHEN v.data_flag = 'ДЗ на конец' THEN 'ДЗ'
            WHEN v.data_flag = 'Факторинг' THEN 'Факторинг'
            ELSE NULL
        END
    FROM dm_ufkbrd.ref_do_vok d
    WHERE d.do_short_name = v.do_name;

    DELETE FROM dm_ufkbrd.mart_vok_uo WHERE EXTRACT(YEAR FROM period_dt) < v_year;

    -- Days in month + turnover calendar
    TRUNCATE TABLE dm_ufkbrd.mart_days_in_month;
    INSERT INTO dm_ufkbrd.mart_days_in_month (period_dt, days_in_month)
    SELECT DISTINCT period_dt, EXTRACT(DAY FROM dm_ufkbrd.fn_month_end(period_dt))::integer
    FROM dm_ufkbrd.mart_vok_uo
    WHERE period_dt <= dm_ufkbrd.fn_year_end((v_today + INTERVAL '1 year')::date);

    TRUNCATE TABLE dm_ufkbrd.mart_calendar_turnover;
    INSERT INTO dm_ufkbrd.mart_calendar_turnover (
        period_dt, ytm_flag, month_counter, ytd_flag, year_start_flag, calendar_flag,
        turnover_dt, period_end_flag, period_start_flag
    )
    SELECT
        a.period_dt,
        CASE WHEN b.period_dt <= v_today THEN 1 ELSE 0 END,
        floor((b.period_dt - (a.period_dt - 5)) / 30.0)::integer,
        CASE WHEN a.period_dt >= dm_ufkbrd.fn_year_start(b.period_dt) THEN 1 ELSE 0 END,
        CASE WHEN EXTRACT(MONTH FROM a.period_dt) = 1 THEN 1 ELSE 0 END,
        'ДЗ_КЗ',
        b.period_dt,
        CASE WHEN a.period_dt = b.period_dt THEN 1 ELSE 0 END,
        CASE WHEN a.period_dt = dm_ufkbrd.fn_month_end((b.period_dt - INTERVAL '11 months')::date) THEN 1 ELSE 0 END
    FROM dm_ufkbrd.mart_days_in_month a
    JOIN dm_ufkbrd.mart_days_in_month b ON b.period_dt >= a.period_dt;
END;
$$;
