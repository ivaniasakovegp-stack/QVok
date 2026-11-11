# ODS source tables

Populate these tables before calling `dm_ufkbrd.fn_run_pipeline()`.

## Excel NSI (`01-01`)

| Table | Source |
|-------|--------|
| `ods.nsi_do_sp` | НСИ УФК БРД.xlsx / Список ДО_СП (Блок=БРД) |
| `ods.nsi_do_oe_ka` | ДО_ОЕ_ка |
| `ods.nsi_oa_types` | Виды ОА |
| `ods.nsi_kpi_dd` | КПЭ ДД (unpivoted months) |
| `ods.nsi_kpi_uro` | КПЭ УРО (unpivoted months) |
| `ods.nsi_account_exclusions` | постановка счетов SAP (unpivoted BE) |
| `ods.nsi_mtr_accounts` | счета МТР |
| `ods.nsi_atlas_advances_raw` | Атлас Excel авансы (fin/osv unpivoted) |
| `ods.nsi_reserves_excel` | Резервы 62 счет.xlsx |
| `ods.nsi_scenarios` | Контроль БДДС Сценарии |
| `ods.nsi_algoritm_depos_spo` | ALGORITM_DEPOS_SPO |
| `ods.nsi_do_short_atlas` | ДО_кратко_Атлас |
| `ods.nsi_counterparties` | Контрагенты.qvd |

## SAP (`01-02`)

| Table | Source |
|-------|--------|
| `ods.sap_zgrccp410` | ZGRCCP410 |
| `ods.sap_zkhdcp050` | ZKHDCP050 |
| `ods.sap_zkhdcp056_qry001` | ZKHDCP056_QRY001 (Megion) |
| `ods.sap_vgo_vzl_dict` | МТР Справочник SAP_ВГО_ВЗЛ |
| `ods.sap_article_account_section` | Статья-Счет-Секция |
| `ods.sap_accounts_dict` | Счета |
| `ods.data_1c_erp` | Данные_1CERP (Shelf factoring) |

## Interlayers

| Table | Source |
|-------|--------|
| `ods.arm_kk_hybrid_final` | Hybrid_FINAL_Main_Data_With_Checks |
| `ods.mtr_to_vok` | FROM_MTR_to_VOK |
| `ods.bdds_dashboard_data` | Дашборд Контроль БДДС / Данные |
| `ods.bdds_lvf` | LVF2023 |
| `ods.bdds_tax_inefficiency` | НалоговаяНеэффективность |
| `ods.bdds_limits` | Лимиты |
| `ods.bdds_form_corr_do` | Форма_БДДС Корректировки только по ДО |
| `ods.spo_forecast_src` | Данные_spo_Исходник для прогноза |
| `ods.scenario_mapping` | ТаблицаСоответствияСценариев |
| `ods.atlas_advances_hist` | АвансыПрогноз historical QVD |
| `ods.atlas_factoring_forecast` | Факторинг_Прогноз |
| `ods.atlas_limits_fin_osv` | Лимиты_Финансирование_Освоение |
