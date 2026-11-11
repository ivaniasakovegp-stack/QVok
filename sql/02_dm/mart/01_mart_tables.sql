-- DM final mart tables (tier3 precalc results)

DROP TABLE IF EXISTS dm_ufkbrd.mart_mtr_involvement_year CASCADE;
CREATE TABLE dm_ufkbrd.mart_mtr_involvement_year (
    data_flag               varchar(100),
    do_name                 varchar(100),
    period_dt               date,
    year_num                integer,
    amount                  numeric(18,2)
)
DISTRIBUTED BY (do_name, period_dt);

DROP TABLE IF EXISTS dm_ufkbrd.mart_ap_factoring CASCADE;
CREATE TABLE dm_ufkbrd.mart_ap_factoring (
    payment_type            varchar(100),
    do_name                 varchar(100),
    zkhcontr                varchar(50),
    counterparty_name       varchar(255),
    gl_account              varchar(50),
    report_dt               date,
    year_num                integer,
    month_num               integer,
    ap_eop_rub              numeric(18,2),
    ap_repay_dt_rub         numeric(18,2),
    ap_increase_kt_rub      numeric(18,2),
    ap_bop_rub              numeric(18,2)
)
DISTRIBUTED BY (do_name, report_dt);

DROP TABLE IF EXISTS dm_ufkbrd.mart_kpd CASCADE;
CREATE TABLE dm_ufkbrd.mart_kpd (
    data_flag               varchar(50),
    counterparty_inn        varchar(20),
    contract_number         varchar(255),
    report_dt               date,
    counterparty_name       varchar(255),
    do_name_src             varchar(255),
    do_name                 varchar(255),
    unit_name               varchar(255),
    debt_kind               varchar(100),
    gl_account              varchar(50),
    comments_txt            text,
    overdue_debt_rub        numeric(18,2),
    reserve_eop_rub         numeric(18,2),
    kpd_reserve_rub         numeric(18,2)
)
DISTRIBUTED BY (do_name, report_dt);

DROP TABLE IF EXISTS dm_ufkbrd.mart_bdds_data CASCADE;
CREATE TABLE dm_ufkbrd.mart_bdds_data (
    dds_flag                varchar(100),
    do_type                 varchar(50),
    do_short_name           varchar(100),
    dds_period_dt           date,
    month_num               integer,
    report_period           varchar(50),
    dds_amount              numeric(18,2),
    dds_lvf_year            integer
)
DISTRIBUTED BY (do_short_name, dds_period_dt);

DROP TABLE IF EXISTS dm_ufkbrd.mart_bdds_kpi CASCADE;
CREATE TABLE dm_ufkbrd.mart_bdds_kpi (
    dds_amount              numeric(18,2),
    do_name                 varchar(100),
    do_dds                  varchar(100),
    dds_flag                varchar(100),
    dds_year                integer
)
DISTRIBUTED BY (do_name);

DROP TABLE IF EXISTS dm_ufkbrd.mart_dds_for_vok CASCADE;
CREATE TABLE dm_ufkbrd.mart_dds_for_vok (
    report_dt               date,
    do_name                 varchar(100),
    amount                  numeric(18,2),
    bdds_group2             varchar(255)
)
DISTRIBUTED BY (do_name, report_dt);

DROP TABLE IF EXISTS dm_ufkbrd.mart_spo_ebitda CASCADE;
CREATE TABLE dm_ufkbrd.mart_spo_ebitda (
    year_num                integer,
    scenario                varchar(50),
    do_short_name           varchar(100),
    report_dt               date,
    amount                  numeric(18,2)
)
DISTRIBUTED BY (do_short_name, report_dt);

DROP TABLE IF EXISTS dm_ufkbrd.mart_spo_capex_fin CASCADE;
CREATE TABLE dm_ufkbrd.mart_spo_capex_fin (
    year_num                integer,
    scenario                varchar(50),
    do_short_name           varchar(100),
    report_dt               date,
    amount                  numeric(18,2)
)
DISTRIBUTED BY (do_short_name, report_dt);

DROP TABLE IF EXISTS dm_ufkbrd.mart_spo_production CASCADE;
CREATE TABLE dm_ufkbrd.mart_spo_production (
    year_num                integer,
    scenario                varchar(50),
    do_short_name           varchar(100),
    report_dt               date,
    amount                  numeric(18,2)
)
DISTRIBUTED BY (do_short_name, report_dt);

DROP TABLE IF EXISTS dm_ufkbrd.mart_vok_uo CASCADE;
CREATE TABLE dm_ufkbrd.mart_vok_uo (
    data_slice              varchar(100),
    source_system           varchar(100),
    counterparty_name       varchar(255),
    period_dt               date,
    do_name                 varchar(100),
    do_type                 varchar(50),
    sheet_name              varchar(50),
    material                varchar(100),
    counterparty_code       varchar(50),
    counterparty_type       varchar(50),
    nez_flag                smallint,
    vok_project             varchar(255),
    uo_ifrs_flag            varchar(20),
    data_flag               varchar(100),
    amount                  numeric(18,2),
    mtr_flag                varchar(50),
    bdds_group2             varchar(255),
    expense_flag            varchar(100),
    losses_vgo_flag         smallint,
    mtr_map_filter_l1       varchar(50),
    nez_gt3y_flag           smallint,
    factoring_payment_type  varchar(100),
    factoring_gl_account    varchar(50),
    factoring_ap_repay      numeric(18,2),
    factoring_ap_increase   numeric(18,2),
    factoring_ap_bop        numeric(18,2),
    factoring_ap_eop        numeric(18,2),
    vok_formula_group       varchar(50)
)
DISTRIBUTED BY (do_name, period_dt);

DROP TABLE IF EXISTS dm_ufkbrd.mart_calendar_turnover CASCADE;
CREATE TABLE dm_ufkbrd.mart_calendar_turnover (
    period_dt               date,
    ytm_flag                smallint,
    month_counter           integer,
    ytd_flag                smallint,
    year_start_flag         smallint,
    calendar_flag           varchar(20),
    turnover_dt             date,
    period_end_flag         smallint,
    period_start_flag       smallint
)
DISTRIBUTED BY (period_dt);

DROP TABLE IF EXISTS dm_ufkbrd.mart_days_in_month CASCADE;
CREATE TABLE dm_ufkbrd.mart_days_in_month (
    period_dt               date,
    days_in_month           integer
)
DISTRIBUTED BY (period_dt);

DROP TABLE IF EXISTS dm_ufkbrd.mart_reserves CASCADE;
CREATE TABLE dm_ufkbrd.mart_reserves (
    reserve_kind            varchar(100),
    do_name                 varchar(100),
    reserves_period_dt      date,
    counterparty_name       varchar(255),
    reserve_amount          numeric(18,2),
    reserve_balance_mln     numeric(18,6)
)
DISTRIBUTED BY (do_name, reserves_period_dt);

DROP TABLE IF EXISTS dm_ufkbrd.mart_reserves_calendar CASCADE;
CREATE TABLE dm_ufkbrd.mart_reserves_calendar (
    period_dt               date,
    period_cumulative_dt    date
)
DISTRIBUTED BY (period_dt);

DROP TABLE IF EXISTS dm_ufkbrd.mart_reserves_z410 CASCADE;
CREATE TABLE dm_ufkbrd.mart_reserves_z410 (
    do_name                 varchar(100),
    comp_code               varchar(10),
    gl_account              varchar(50),
    period_dt               date,
    deb_cre_lc              numeric(18,2),
    credit_lc               numeric(18,2),
    debit_lc                numeric(18,2),
    key_410                 varchar(100)
)
DISTRIBUTED BY (comp_code, period_dt);

DROP TABLE IF EXISTS dm_ufkbrd.mart_reserves_article_account CASCADE;
CREATE TABLE dm_ufkbrd.mart_reserves_article_account (
    period_code             varchar(20),
    comp_code               varchar(10),
    gl_account              varchar(50),
    parent_ergsl            varchar(50),
    key_410                 varchar(100),
    account_name_src        varchar(255),
    account_name            varchar(255)
)
DISTRIBUTED BY (comp_code, gl_account);

DROP TABLE IF EXISTS dm_ufkbrd.mart_forecast_advances CASCADE;
CREATE TABLE dm_ufkbrd.mart_forecast_advances (
    movement_flag           smallint,
    scenario_etalon         varchar(20),
    scenario_name           varchar(20),
    year_num                integer,
    do_name_src             varchar(255),
    do_name                 varchar(100),
    do_name_table           varchar(255),
    in_vok_perimeter_flag   smallint,
    forecast_dt             date,
    source_system           varchar(50),
    inn                     varchar(20),
    contractor_name         varchar(255),
    contract_number         varchar(255),
    paid_fact_rub           numeric(18,2),
    repaid_fact_rub         numeric(18,2),
    issue_plan_rub          numeric(18,2),
    repay_plan_rub          numeric(18,2),
    issue_delta_rub         numeric(18,2),
    repay_delta_rub         numeric(18,2),
    bop_forecast_rub        numeric(18,2),
    bop_fact_rub            numeric(18,2),
    eop_rub                 numeric(18,2),
    eop_for_variance_rub    numeric(18,2),
    scenario_order          integer,
    fact_present_flag       smallint,
    new_contract_flag       varchar(255)
)
DISTRIBUTED BY (do_name, forecast_dt);

DROP TABLE IF EXISTS dm_ufkbrd.mart_forecast_advances_dds CASCADE;
CREATE TABLE dm_ufkbrd.mart_forecast_advances_dds (
    do_name                 varchar(100),
    issue_plan_rub          numeric(18,2),
    repay_plan_rub          numeric(18,2),
    forecast_dt             date,
    scenario_etalon         varchar(20),
    capex_opex              varchar(50),
    scenario_name           varchar(20),
    year_num                integer
)
DISTRIBUTED BY (do_name, forecast_dt);

DROP TABLE IF EXISTS dm_ufkbrd.mart_forecast_advances_summary CASCADE;
CREATE TABLE dm_ufkbrd.mart_forecast_advances_summary (
    scenario_name           varchar(20),
    in_vok_perimeter_flag   smallint,
    do_name                 varchar(100),
    year_num                integer,
    forecast_dt             date,
    forecast_amount         numeric(18,2)
)
DISTRIBUTED BY (do_name, forecast_dt);

DROP TABLE IF EXISTS dm_ufkbrd.mart_forecast_ar CASCADE;
CREATE TABLE dm_ufkbrd.mart_forecast_ar (
    scenario_name           varchar(20),
    do_name                 varchar(100),
    year_num                integer,
    forecast_dt             date,
    forecast_amount         numeric(18,2)
)
DISTRIBUTED BY (do_name, forecast_dt);

DROP TABLE IF EXISTS dm_ufkbrd.mart_forecast_ap CASCADE;
CREATE TABLE dm_ufkbrd.mart_forecast_ap (
    scenario_name           varchar(20),
    do_name                 varchar(100),
    year_num                integer,
    forecast_dt             date,
    forecast_wo_factoring   numeric(18,2),
    forecast_amount         numeric(18,2),
    lt_factoring_block      numeric(18,2)
)
DISTRIBUTED BY (do_name, forecast_dt);

DROP TABLE IF EXISTS dm_ufkbrd.mart_forecast_ap_factoring CASCADE;
CREATE TABLE dm_ufkbrd.mart_forecast_ap_factoring (
    do_name                 varchar(100),
    payment_type            varchar(100),
    factoring_type          varchar(50),
    factoring_dt            date,
    report_period           varchar(50),
    factoring_year          integer,
    forecast_name_atlas     varchar(255),
    ap_eop_rub              numeric(18,2),
    turnover_dt             date,
    same_period_flag        smallint
)
DISTRIBUTED BY (do_name, factoring_dt);

DROP TABLE IF EXISTS dm_ufkbrd.mart_forecast_mtr CASCADE;
CREATE TABLE dm_ufkbrd.mart_forecast_mtr (
    year_num                integer,
    scenario_name           varchar(20),
    do_name                 varchar(100),
    forecast_dt             date,
    forecast_amount_mtr     numeric(18,2),
    fact_present_flag       smallint
)
DISTRIBUTED BY (do_name, forecast_dt);

DROP TABLE IF EXISTS dm_ufkbrd.mart_ar_bop_forecast CASCADE;
CREATE TABLE dm_ufkbrd.mart_ar_bop_forecast (
    data_flag               varchar(50),
    do_name                 varchar(100),
    forecast_dt             date,
    forecast_amount         numeric(18,2)
)
DISTRIBUTED BY (do_name);

DROP TABLE IF EXISTS dm_ufkbrd.mart_ap_bop_forecast CASCADE;
CREATE TABLE dm_ufkbrd.mart_ap_bop_forecast (
    data_flag               varchar(50),
    do_name                 varchar(100),
    forecast_dt             date,
    forecast_amount         numeric(18,2)
)
DISTRIBUTED BY (do_name);

DROP TABLE IF EXISTS dm_ufkbrd.mart_advances_bop_forecast CASCADE;
CREATE TABLE dm_ufkbrd.mart_advances_bop_forecast (
    scenario_name           varchar(20),
    bop_amount_rub          numeric(18,2),
    inn                     varchar(20),
    report_dt               date,
    contract_number         varchar(255),
    do_name_table           varchar(255),
    do_name                 varchar(100),
    do_name_src             varchar(255)
)
DISTRIBUTED BY (do_name);

-- Pipeline parameters
DROP TABLE IF EXISTS dm_ufkbrd.pipeline_params CASCADE;
CREATE TABLE dm_ufkbrd.pipeline_params (
    param_name              varchar(50),
    param_value             varchar(100)
)
DISTRIBUTED RANDOMLY;

INSERT INTO dm_ufkbrd.pipeline_params (param_name, param_value) VALUES
('dashboard_year', '2022'),
('as_of_date', to_char(current_date, 'YYYY-MM-DD'));
