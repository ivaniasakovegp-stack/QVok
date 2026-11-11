-- DM staging / intermediate tables (tier2 transforms)

DROP TABLE IF EXISTS dm_ufkbrd.stg_kpi_dd CASCADE;
CREATE TABLE dm_ufkbrd.stg_kpi_dd (
    be_code                 varchar(20),
    period_dt               date,
    amount                  numeric(18,3)
)
DISTRIBUTED BY (be_code);

DROP TABLE IF EXISTS dm_ufkbrd.stg_kpi_uro CASCADE;
CREATE TABLE dm_ufkbrd.stg_kpi_uro (
    be_code                 varchar(20),
    period_dt               date,
    amount                  numeric(18,3)
)
DISTRIBUTED BY (be_code);

DROP TABLE IF EXISTS dm_ufkbrd.stg_atlas_advances CASCADE;
CREATE TABLE dm_ufkbrd.stg_atlas_advances (
    scenario_name           varchar(100),
    year_num                integer,
    oe_name                 varchar(255),
    do_name                 varchar(255),
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
    flow_flag               varchar(50),
    planned_issue_rub       numeric(18,2),
    planned_repay_rub       numeric(18,2),
    period_dt               date
)
DISTRIBUTED BY (year_num, do_name);

DROP TABLE IF EXISTS dm_ufkbrd.stg_advances_forecast CASCADE;
CREATE TABLE dm_ufkbrd.stg_advances_forecast (
    scenario_name           varchar(100),
    year_num                integer,
    do_name                 varchar(255),
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
    flow_flag               varchar(50),
    planned_issue_rub       numeric(18,2),
    planned_repay_rub       numeric(18,2),
    period_dt               date
)
DISTRIBUTED BY (year_num, do_name);

DROP TABLE IF EXISTS dm_ufkbrd.stg_advances_scenario_fact_etalon CASCADE;
CREATE TABLE dm_ufkbrd.stg_advances_scenario_fact_etalon (
    year_num                integer,
    scenario_fact           varchar(20),
    order_fact              integer,
    scenario_etalon         varchar(20),
    order_etalon            integer
)
DISTRIBUTED BY (year_num);

DROP TABLE IF EXISTS dm_ufkbrd.stg_zgrccp410_raw CASCADE;
CREATE TABLE dm_ufkbrd.stg_zgrccp410_raw (
    counterparty_type       varchar(50),
    counterparty_vgo_flag   smallint,
    do_name                 varchar(100),
    zkhcontr                varchar(50),
    customer                varchar(50),
    comp_code               varchar(10),
    doc_date                date,
    revenue_turnover        numeric(18,2),
    credit_lc               numeric(18,2),
    gl_account              varchar(50),
    period_dt               date,
    period_filter           varchar(20),
    fiscper                 varchar(20),
    debit_turnover          numeric(18,2),
    debit_lc                numeric(18,2),
    deb_cre_lc              numeric(18,2),
    material                varchar(50),
    quantity                numeric(18,6),
    zkhkglacc               varchar(50)
)
DISTRIBUTED BY (comp_code, period_dt);

DROP TABLE IF EXISTS dm_ufkbrd.stg_zgrccp410_revenue CASCADE;
CREATE TABLE dm_ufkbrd.stg_zgrccp410_revenue (
    do_name                 varchar(100),
    revenue_turnover        numeric(18,2),
    period_dt               date,
    yamal_ka_flag           smallint
)
DISTRIBUTED BY (do_name, period_dt);

DROP TABLE IF EXISTS dm_ufkbrd.stg_zkhdcp050_liquidity CASCADE;
CREATE TABLE dm_ufkbrd.stg_zkhdcp050_liquidity (
    data_flag               varchar(10),
    amount                  numeric(18,2),
    do_name                 varchar(100),
    period_dt               date,
    amount_flag             varchar(50),
    fs_line                 varchar(20)
)
DISTRIBUTED BY (do_name, period_dt);

DROP TABLE IF EXISTS dm_ufkbrd.stg_zkhdcp050_taxes CASCADE;
CREATE TABLE dm_ufkbrd.stg_zkhdcp050_taxes (
    period_dt               date,
    do_name                 varchar(100),
    amount_eop              numeric(18,2)
)
DISTRIBUTED BY (do_name, period_dt);

DROP TABLE IF EXISTS dm_ufkbrd.stg_arm_kk CASCADE;
CREATE TABLE dm_ufkbrd.stg_arm_kk (
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
    source_system           varchar(50),
    do_name                 varchar(100),
    do_name_src             varchar(255),
    do_name_reserves        varchar(100),
    kpd_unit_name           varchar(255),
    report_dt               date,
    row_type                varchar(50),
    block_name              varchar(255),
    advances_paid_dt_rub    numeric(18,2),
    advances_bop_rub        numeric(18,2),
    advances_paid_wo_neg    numeric(18,2),
    advances_repaid_wo_neg  numeric(18,2),
    advances_eop_src        numeric(18,2),
    advances_eop_rub        numeric(18,2),
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
    repay_date_src          varchar(100),
    repay_dt                date,
    payment_type            varchar(100)
)
DISTRIBUTED BY (do_name, report_dt);

DROP TABLE IF EXISTS dm_ufkbrd.stg_arm_kk_reserves CASCADE;
CREATE TABLE dm_ufkbrd.stg_arm_kk_reserves (
    counterparty_name       varchar(255),
    report_dt               date,
    block_name              varchar(255),
    do_name                 varchar(100),
    debt_kind               varchar(100),
    debt_type               varchar(100),
    reserve_bop_wo_neg      numeric(18,2),
    reserve_eop_wo_neg      numeric(18,2),
    reserve_accrual_wo_neg  numeric(18,2),
    reserve_writeoff_wo_neg numeric(18,2),
    reserve_repay_wo_neg    numeric(18,2)
)
DISTRIBUTED BY (do_name, report_dt);

DROP TABLE IF EXISTS dm_ufkbrd.stg_mtr CASCADE;
CREATE TABLE dm_ufkbrd.stg_mtr (
    source_system           varchar(50),
    do_name                 varchar(100),
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
    mtr_vna_flag            varchar(50),
    mtr_map_filter_l1       varchar(50),
    nez_storage_term        varchar(100),
    data_slice              varchar(100),
    counterparty_dds_code   varchar(50),
    counterparty_kps        varchar(100),
    share_in_gpn            numeric(18,6)
)
DISTRIBUTED BY (do_name, period_dt);
