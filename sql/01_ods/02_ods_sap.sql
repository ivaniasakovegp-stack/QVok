-- ODS: SAP extracts (01-02 Extract SAP ZGRCCP410 / ZKHDCP050)

DROP TABLE IF EXISTS ods.sap_zgrccp410 CASCADE;
CREATE TABLE ods.sap_zgrccp410 (
    comp_code               varchar(10),
    customer                varchar(50),
    zkhcontr                varchar(50),
    doc_date                date,
    fiscper                 varchar(20),
    gl_account              varchar(50),
    credit_lc               numeric(18,2),
    debit_lc                numeric(18,2),
    asset_main              varchar(50),
    deb_cre_lc              numeric(18,2),
    material                varchar(50),
    quantity                numeric(18,6),
    zkhkglacc               varchar(50),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (comp_code, fiscper);

COMMENT ON TABLE ods.sap_zgrccp410 IS 'SAP mart ZGRCCP410 (Form1/Form2 RSBU + KPS accounts)';

DROP TABLE IF EXISTS ods.sap_zkhdcp050 CASCADE;
CREATE TABLE ods.sap_zkhdcp050 (
    calmonth2               varchar(10),
    calyear                 integer,
    comp_code               varchar(10),
    fiscper                 varchar(20),
    zkhsalend               numeric(18,2),
    gl_fsitem               varchar(20),
    infoprov                varchar(50),
    zkhdstat                varchar(20),
    zkhdvtype               varchar(20),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (comp_code, fiscper);

COMMENT ON TABLE ods.sap_zkhdcp050 IS 'SAP mart ZKHDCP050 (quick liquidity / taxes)';

DROP TABLE IF EXISTS ods.sap_zkhdcp056_qry001 CASCADE;
CREATE TABLE ods.sap_zkhdcp056_qry001 (
    fiscal_year_period      varchar(20),
    account_1c              varchar(50),
    amount_dt_kt            numeric(18,2),
    entity_code             varchar(20),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (entity_code);

COMMENT ON TABLE ods.sap_zkhdcp056_qry001 IS 'SAP ZKHDCP056_QRY001 for Megion revenue (1C)';

DROP TABLE IF EXISTS ods.sap_vgo_vzl_dict CASCADE;
CREATE TABLE ods.sap_vgo_vzl_dict (
    counterparty_code       varchar(50),
    period_dt               date,
    counterparty_type       varchar(50),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (counterparty_code);

COMMENT ON TABLE ods.sap_vgo_vzl_dict IS 'МТР Справочник SAP_ВГО_ВЗЛ';

DROP TABLE IF EXISTS ods.sap_article_account_section CASCADE;
CREATE TABLE ods.sap_article_account_section (
    period_code             varchar(20),
    comp_code               varchar(10),
    gl_account              varchar(50),
    parent_ergsl            varchar(50),
    gl_account_key          varchar(50),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (comp_code, gl_account);

COMMENT ON TABLE ods.sap_article_account_section IS 'Балансовая комиссия Статья-Счет-Секция';

DROP TABLE IF EXISTS ods.sap_accounts_dict CASCADE;
CREATE TABLE ods.sap_accounts_dict (
    gl_account_key          varchar(50),
    account_name            varchar(255),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (gl_account_key);

COMMENT ON TABLE ods.sap_accounts_dict IS 'Балансовая комиссия Счета';

DROP TABLE IF EXISTS ods.data_1c_erp CASCADE;
CREATE TABLE ods.data_1c_erp (
    period_dt               date,
    inn                     varchar(20),
    account_1c              varchar(50),
    counterparty_1c         varchar(255),
    ifrs_entity             varchar(50),
    amount_dt               numeric(18,2),
    amount_kt               numeric(18,2),
    amount_dt_kt            numeric(18,2),
    load_dts                timestamp DEFAULT now()
)
DISTRIBUTED BY (ifrs_entity);

COMMENT ON TABLE ods.data_1c_erp IS 'Данные_1CERP for Shelf factoring';
