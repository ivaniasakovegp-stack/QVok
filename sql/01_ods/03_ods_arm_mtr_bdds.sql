-- ODS: ARM KK, MTR control, BDDS, SPO/KLAD, Atlas forecasts

DROP TABLE IF EXISTS ods.arm_kk_hybrid_final CASCADE;
CREATE TABLE ods.arm_kk_hybrid_final (
    gl_account              varchar(50),
    contract_number         varchar(255),
    counterparty_inn        varchar(20),
    counterparty_code_aus   varchar(50),
    debt_type               varchar(100),
    debt_kind               varchar(100),
    security_flag           smallint,
    counterparty_name       varchar(255),
    comments_txt            text,
    counterparty_type       varchar(100),
    do_name                 varchar(255),
    report_dt               date,
    row_type                varchar(50),
    block_name              varchar(255),
    advances_paid_dt_rub    numeric(18,2),
    advances_bop_rub        numeric(18,2),
    advances_paid_wo_neg    numeric(18,2),
    advances_repaid_wo_neg  numeric(18,2),
    advances_eop_wo_neg     numeric(18,2),
    advances_net_reserves   numeric(18,2),
    debt_total_reval_rub    numeric(18,2),
    amount_wo_security_rub  numeric(18,2),
    debt_current_reval_rub  numeric(18,2),
    ap_bop_rub              numeric(18,2),
    ap_eop_rub              numeric(18,2),
    ap_repay_dt_wo_neg      numeric(18,2),
    ap_increase_kt_wo_neg   numeric(18,2),
    ap_repay_dt_rub         numeric(18,2),
    ap_increase_kt_rub      numeric(18,2),
    reserve_eop_rub         numeric(18,2),
    reserve_bop_wo_neg      numeric(18,2),
    reserve_eop_wo_neg      numeric(18,2),
    reserve_accrual_wo_neg  numeric(18,2),
    reserve_writeoff_wo_neg numeric(18,2),
    reserve_repay_wo_neg    numeric(18,2),
    debt_overdue_reval_rub  numeric(18,2),
    block_code              varchar(100),
    do_code                 varchar(100),
    debt_overdue_gt30_rub   numeric(18,2),
    debt_overdue_5_30_rub   numeric(18,2),
    repay_date_raw          varchar(100),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (do_name, report_dt);

COMMENT ON TABLE ods.arm_kk_hybrid_final IS 'Hybrid_FINAL_Main_Data_With_Checks (ARM KK interlayer)';

DROP TABLE IF EXISTS ods.mtr_to_vok CASCADE;
CREATE TABLE ods.mtr_to_vok (
    data_flag               varchar(100),
    period_dt               date,
    material                varchar(100),
    counterparty_code       varchar(50),
    counterparty_type       varchar(50),
    project_name            varchar(255),
    nez_flag                smallint,
    stock_category_code     varchar(20),
    amount                  numeric(18,2),
    main_account            varchar(50),
    be_code                 varchar(20),
    mtr_map_filter_l1       varchar(50),
    nez_storage_term        varchar(100),
    data_slice              varchar(100),
    counterparty_dds_code   varchar(50),
    counterparty_kps        varchar(100),
    share_in_gpn            numeric(18,6),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (be_code, period_dt);

COMMENT ON TABLE ods.mtr_to_vok IS 'FROM_MTR_to_VOK interlayer';

DROP TABLE IF EXISTS ods.bdds_dashboard_data CASCADE;
CREATE TABLE ods.bdds_dashboard_data (
    block_flag              varchar(100),
    article_order           integer,
    do_short_name           varchar(100),
    do_full_name            varchar(255),
    report_period           varchar(50),
    report_order            integer,
    period_sort_order       integer,
    year_num                integer,
    period_dt               date,
    month_num               integer,
    amount_plan_fact        numeric(18,2),
    group_name              varchar(255),
    analytics_name          varchar(255),
    group1                  varchar(255),
    group2                  varchar(255),
    group3                  varchar(255),
    sales_to_third_parties  varchar(10),
    fact_present_flag       smallint,
    key_lvf                 varchar(100),
    key_id                  varchar(100),
    plan_amount             numeric(18,2),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (do_short_name, period_dt);

COMMENT ON TABLE ods.bdds_dashboard_data IS 'Контроль БДДС Дашборд Данные';

DROP TABLE IF EXISTS ods.bdds_lvf CASCADE;
CREATE TABLE ods.bdds_lvf (
    do_short_name           varchar(100),
    year_num                integer,
    report_period           varchar(50),
    debt_boy_rub            numeric(18,2),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (do_short_name);

COMMENT ON TABLE ods.bdds_lvf IS 'LVF2023 inside-group loans - debt at beginning of year';

DROP TABLE IF EXISTS ods.bdds_tax_inefficiency CASCADE;
CREATE TABLE ods.bdds_tax_inefficiency (
    do_short_name           varchar(100),
    tax_inefficiency        numeric(18,2),
    year_num                integer,
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (do_short_name);

COMMENT ON TABLE ods.bdds_tax_inefficiency IS 'НалоговаяНеэффективность';

DROP TABLE IF EXISTS ods.bdds_limits CASCADE;
CREATE TABLE ods.bdds_limits (
    do_short_name           varchar(100),
    period_dt               date,
    limit_amount            numeric(18,2),
    report_period           varchar(50),
    article_order           integer,
    year_num                integer,
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (do_short_name, period_dt);

COMMENT ON TABLE ods.bdds_limits IS 'BDDS Лимиты';

DROP TABLE IF EXISTS ods.bdds_form_corr_do CASCADE;
CREATE TABLE ods.bdds_form_corr_do (
    period_dt               date,
    do_short_name           varchar(100),
    amount_plan_fact        numeric(18,2),
    group2                  varchar(255),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (do_short_name, period_dt);

COMMENT ON TABLE ods.bdds_form_corr_do IS 'Форма_БДДС Корректировки только по ДО';

DROP TABLE IF EXISTS ods.spo_forecast_src CASCADE;
CREATE TABLE ods.spo_forecast_src (
    year_num                integer,
    scenario                varchar(50),
    entity_alias2           varchar(100),
    report_dt               date,
    amount                  numeric(18,6),
    account_alias           varchar(255),
    account_alias2          varchar(255),
    account_code            varchar(100),
    counterparty_alias      varchar(255),
    counterparty_code       varchar(100),
    ka_vgo_flag             varchar(10),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (entity_alias2, report_dt);

COMMENT ON TABLE ods.spo_forecast_src IS 'Данные_spo_Исходник для прогноза (KLAD)';

DROP TABLE IF EXISTS ods.scenario_mapping CASCADE;
CREATE TABLE ods.scenario_mapping (
    year_num                integer,
    scenario_spo_src        varchar(50),
    scenario_etalon         varchar(20),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (year_num);

COMMENT ON TABLE ods.scenario_mapping IS 'ТаблицаСоответствияСценариев';

DROP TABLE IF EXISTS ods.atlas_advances_hist CASCADE;
CREATE TABLE ods.atlas_advances_hist (
    scenario_name           varchar(100),
    year_num                integer,
    do_full_name            varchar(255),
    do_name_src             varchar(255),
    capex_opex              varchar(50),
    kp_name                 varchar(255),
    contractor_name         varchar(255),
    inn                     varchar(20),
    contracting_status      varchar(100),
    contract_number         varchar(255),
    advance_full_repay_term varchar(255),
    bg_flag                 varchar(50),
    other_security          varchar(255),
    advance_category        varchar(255),
    advance_type            varchar(255),
    justification           text,
    planned_issue_rub       numeric(18,2),
    planned_repay_rub       numeric(18,2),
    period_dt               date,
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (year_num, do_full_name);

COMMENT ON TABLE ods.atlas_advances_hist IS 'Historical advances forecast QVD (Excel path, e.g. 0+12 2024)';

DROP TABLE IF EXISTS ods.atlas_factoring_forecast CASCADE;
CREATE TABLE ods.atlas_factoring_forecast (
    period_dt               date,
    year_num                integer,
    report_period           varchar(50),
    forecast_name_atlas     varchar(255),
    do_short_name           varchar(100),
    category_name           varchar(255),
    amount                  numeric(18,6),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (do_short_name, period_dt);

COMMENT ON TABLE ods.atlas_factoring_forecast IS 'Атлас Факторинг_Прогноз';

DROP TABLE IF EXISTS ods.atlas_limits_fin_osv CASCADE;
CREATE TABLE ods.atlas_limits_fin_osv (
    period_dt               date,
    year_num                integer,
    report_period           varchar(50),
    category_name           varchar(255),
    legal_entity            varchar(255),
    cons_principle          varchar(100),
    limit_amount            numeric(18,6),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (year_num, period_dt);

COMMENT ON TABLE ods.atlas_limits_fin_osv IS 'Лимиты_Финансирование_Освоение (long-term factoring block)';
