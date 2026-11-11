-- ODS: Excel NSI master (from 01-01 Extract XLS master)
-- Source workbook: NSI UFK BRD.xlsx and related Excel extracts

DROP TABLE IF EXISTS ods.nsi_do_sp CASCADE;
CREATE TABLE ods.nsi_do_sp (
    block_name              varchar(100),
    be_code                 varchar(20),
    ifrs_code_mvd0o0o       varchar(50),
    do_full_name            varchar(255),
    do_short_name           varchar(100),
    do_type                 varchar(50),
    do_sp_flag              varchar(50),
    flag_vok                smallint,
    flag_reserves           smallint,
    flag_bdds               smallint,
    flag_mtr                smallint,
    flag_nzs                smallint,
    do_arm_kk               varchar(255),
    vok_kpd_tab             varchar(255),
    do_atlas                varchar(255),
    do_atlas_2              varchar(255),
    do_atlas_3              varchar(255),
    corr_type               varchar(50),
    sap_number              varchar(50),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (be_code);

COMMENT ON TABLE ods.nsi_do_sp IS 'NSI sheet Список ДО_СП (block=BRD)';

DROP TABLE IF EXISTS ods.nsi_do_oe_ka CASCADE;
CREATE TABLE ods.nsi_do_oe_ka (
    counterparty_number     varchar(50),
    do_full_name            varchar(255),
    transfer_to_sp_dt       date,
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (counterparty_number);

COMMENT ON TABLE ods.nsi_do_oe_ka IS 'NSI sheet ДО_ОЕ_ка - VGO counterparties';

DROP TABLE IF EXISTS ods.nsi_oa_types CASCADE;
CREATE TABLE ods.nsi_oa_types (
    account_name_as_is      varchar(255),
    valuation_type_to_be    varchar(255),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED RANDOMLY;

COMMENT ON TABLE ods.nsi_oa_types IS 'NSI sheet Виды ОА - estimated reserves mapping';

DROP TABLE IF EXISTS ods.nsi_kpi_dd CASCADE;
CREATE TABLE ods.nsi_kpi_dd (
    be_code                 varchar(20),
    year_num                integer,
    month_code              varchar(10),
    amount_mln              numeric(18,6),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (be_code);

COMMENT ON TABLE ods.nsi_kpi_dd IS 'NSI sheet КПЭ ДД (crosstab months, mln RUB)';

DROP TABLE IF EXISTS ods.nsi_kpi_uro CASCADE;
CREATE TABLE ods.nsi_kpi_uro (
    be_code                 varchar(20),
    year_num                integer,
    month_code              varchar(10),
    amount_mln              numeric(18,6),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (be_code);

COMMENT ON TABLE ods.nsi_kpi_uro IS 'NSI sheet КПЭ УРО';

DROP TABLE IF EXISTS ods.nsi_account_exclusions CASCADE;
CREATE TABLE ods.nsi_account_exclusions (
    gl_account              varchar(50),
    be_code                 varchar(20),
    flag_value              varchar(50),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (be_code);

COMMENT ON TABLE ods.nsi_account_exclusions IS 'NSI sheet постановка счетов SAP (crosstab by BE)';

DROP TABLE IF EXISTS ods.nsi_mtr_accounts CASCADE;
CREATE TABLE ods.nsi_mtr_accounts (
    mtr_map_account         varchar(50),
    mtr_type                varchar(100),
    bb_account              varchar(50),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED RANDOMLY;

COMMENT ON TABLE ods.nsi_mtr_accounts IS 'NSI sheet счета МТР';

DROP TABLE IF EXISTS ods.nsi_atlas_advances_raw CASCADE;
CREATE TABLE ods.nsi_atlas_advances_raw (
    scenario_name           varchar(100),
    year_num                integer,
    oe_name                 varchar(255),
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
    period_label            varchar(50),
    amount                  numeric(18,6),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (year_num, do_full_name);

COMMENT ON TABLE ods.nsi_atlas_advances_raw IS 'Atlas Excel advances export (fin/osv monthly columns unpivoted)';

DROP TABLE IF EXISTS ods.nsi_reserves_excel CASCADE;
CREATE TABLE ods.nsi_reserves_excel (
    do_name                 varchar(255),
    contract_number         varchar(255),
    counterparty_inn        varchar(20),
    reserve_eop_rub         numeric(18,2),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (do_name);

COMMENT ON TABLE ods.nsi_reserves_excel IS 'Excel Резервы 62 счет (KPD)';

DROP TABLE IF EXISTS ods.nsi_scenarios CASCADE;
CREATE TABLE ods.nsi_scenarios (
    scenario_value          varchar(20),
    scenario_order          integer,
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED RANDOMLY;

COMMENT ON TABLE ods.nsi_scenarios IS 'BDDS scenarios справочник Сценарии';

DROP TABLE IF EXISTS ods.nsi_algoritm_depos_spo CASCADE;
CREATE TABLE ods.nsi_algoritm_depos_spo (
    pl_line                 varchar(255),
    data_shift              varchar(100),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED RANDOMLY;

COMMENT ON TABLE ods.nsi_algoritm_depos_spo IS 'ALGORITM_DEPOS_SPO - CAPEX lines outside algorithm';

DROP TABLE IF EXISTS ods.nsi_do_short_atlas CASCADE;
CREATE TABLE ods.nsi_do_short_atlas (
    legal_entity_name       varchar(255),
    do_short_name           varchar(100),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (legal_entity_name);

COMMENT ON TABLE ods.nsi_do_short_atlas IS 'ДО_кратко_Атлас mapping';

DROP TABLE IF EXISTS ods.nsi_counterparties CASCADE;
CREATE TABLE ods.nsi_counterparties (
    zkhcontr                varchar(50),
    counterparty_name       varchar(255),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (zkhcontr);

COMMENT ON TABLE ods.nsi_counterparties IS 'Контрагенты dictionary for ZKHCONTR';
