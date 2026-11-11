-- DM reference / mapping tables (built from ODS NSI)

DROP TABLE IF EXISTS dm_ufkbrd.ref_month_map CASCADE;
CREATE TABLE dm_ufkbrd.ref_month_map (
    month_code              varchar(20),
    month_num               integer
)
DISTRIBUTED RANDOMLY;

INSERT INTO dm_ufkbrd.ref_month_map (month_code, month_num) VALUES
('январь',1),('февраль',2),('март',3),('апрель',4),('май',5),('июнь',6),
('июль',7),('август',8),('сентябрь',9),('октябрь',10),('ноябрь',11),('декабрь',12),
('Янв',1),('Фев',2),('Мар',3),('Апр',4),('Май',5),('Июн',6),
('Июл',7),('Авг',8),('Сен',9),('Окт',10),('Ноя',11),('Дек',12),
('янв',1),('фев',2),('февр',2),('мар',3),('март',3),('апр',4),
('май',5),('июн',6),('июнь',6),('июл',7),('июль',7),('авг',8),
('сен',9),('сент',9),('окт',10),('ноя',11),('нояб',11),('дек',12);

DROP TABLE IF EXISTS dm_ufkbrd.ref_scenario_order CASCADE;
CREATE TABLE dm_ufkbrd.ref_scenario_order (
    scenario_value          varchar(20),
    scenario_order          integer
)
DISTRIBUTED RANDOMLY;

INSERT INTO dm_ufkbrd.ref_scenario_order (scenario_value, scenario_order) VALUES
('0+12',0),('1+11',1),('2+10',2),('3+9',3),('4+8',4),('5+7',5),
('6+6',6),('7+5',7),('8+4',8),('9+3',9),('10+2',10),('11+1',11),('12+0',12);

DROP TABLE IF EXISTS dm_ufkbrd.ref_do_vok CASCADE;
CREATE TABLE dm_ufkbrd.ref_do_vok (
    corr_type               varchar(50),
    sap_number              varchar(50),
    be_code                 varchar(20),
    ifrs_code               varchar(50),
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
    do_short_name           varchar(100),
    do_full_name            varchar(255)
)
DISTRIBUTED BY (be_code);

DROP TABLE IF EXISTS dm_ufkbrd.ref_do_name_map CASCADE;
CREATE TABLE dm_ufkbrd.ref_do_name_map (
    src_name                varchar(255),
    do_short_name           varchar(100)
)
DISTRIBUTED BY (src_name);

DROP TABLE IF EXISTS dm_ufkbrd.ref_vgo_counterparties CASCADE;
CREATE TABLE dm_ufkbrd.ref_vgo_counterparties (
    counterparty_number     varchar(50),
    do_full_name            varchar(255),
    transfer_to_sp_dt       date
)
DISTRIBUTED BY (counterparty_number);

DROP TABLE IF EXISTS dm_ufkbrd.ref_oa_types CASCADE;
CREATE TABLE dm_ufkbrd.ref_oa_types (
    account_name_as_is      varchar(255),
    valuation_type_to_be    varchar(255)
)
DISTRIBUTED RANDOMLY;

DROP TABLE IF EXISTS dm_ufkbrd.ref_periods CASCADE;
CREATE TABLE dm_ufkbrd.ref_periods (
    year_num                integer,
    period_dt               date
)
DISTRIBUTED BY (period_dt);

DROP TABLE IF EXISTS dm_ufkbrd.ref_bg_flag_map CASCADE;
CREATE TABLE dm_ufkbrd.ref_bg_flag_map (
    src_value               varchar(20),
    tgt_value               varchar(20)
)
DISTRIBUTED RANDOMLY;

INSERT INTO dm_ufkbrd.ref_bg_flag_map (src_value, tgt_value) VALUES
('да','Да'),('ДА','Да'),('нет','Нет'),('НЕТ','Нет');

DROP TABLE IF EXISTS dm_ufkbrd.ref_atlas_scenario_map CASCADE;
CREATE TABLE dm_ufkbrd.ref_atlas_scenario_map (
    atlas_name              varchar(255),
    etalon_name             varchar(50)
)
DISTRIBUTED RANDOMLY;

INSERT INTO dm_ufkbrd.ref_atlas_scenario_map (atlas_name, etalon_name) VALUES
('Авансы 2+10 2024 (с НДС)','2024_2+10'),
('Авансы 6+6 2024 (с НДС)','2024_6+6'),
('Авансы 8+4 2024 и БП 2025 (с НДС)','2024_8+4');

DROP TABLE IF EXISTS dm_ufkbrd.ref_vok_do_list CASCADE;
CREATE TABLE dm_ufkbrd.ref_vok_do_list (
    do_short_name           varchar(100)
)
DISTRIBUTED RANDOMLY;

INSERT INTO dm_ufkbrd.ref_vok_do_list (do_short_name) VALUES
('Восток'),('ГЕО'),('ННГ'),('Оренбург'),('Развитие'),('Хантос'),
('Ямал'),('Меретояха'),('Мессояха'),('Мегион'),('Шельф'),('Заполярье');

DROP TABLE IF EXISTS dm_ufkbrd.ref_zero_balance_contracts CASCADE;
CREATE TABLE dm_ufkbrd.ref_zero_balance_contracts (
    contract_number         varchar(255)
)
DISTRIBUTED RANDOMLY;

INSERT INTO dm_ufkbrd.ref_zero_balance_contracts (contract_number) VALUES
('ННГ-22/07000/00214/Р'),
('ННГ-22/07000/00211/Р'),
('ННГ-22/07000/00213/Р'),
('ННГ-22/07000/00212/Р');
