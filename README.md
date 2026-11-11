# UFKBRD VOK — Qlik → Greenplum / PostgreSQL 9.4

Перенос логики формирования дашборда ВОК (УФК БРД) из Qlik-скриптов в **PostgreSQL 9.4.26 / Greenplum 6.22**.

## Архитектура

| Слой | Схема | Назначение |
|------|--------|------------|
| ODS | `ods` | Таблицы-источники (Excel NSI, SAP, АРМ КК, МТР, БДДС, СПО/КЛАД, Атлас) |
| Datamart | `dm_ufkbrd` | Справочники, staging, итоговые витрины и функции загрузки |

Имена полей — на латинице (см. `sql/docs/FIELD_MAPPING.md`).

## Соответствие Qlik → SQL

| Qlik | Функция / результат |
|------|---------------------|
| 01-01 Extract XLS master | `dm_ufkbrd.fn_load_refs()` → `ref_*`, `stg_kpi_*`, `stg_atlas_advances` |
| 01-02 Extract SAP | ODS `ods.sap_zgrccp410`, `ods.sap_zkhdcp050` |
| 02-01 Transform XLS | `fn_transform_advances()` → `stg_advances_*` |
| 02-02 Transform SAP | `fn_transform_zgrccp410()`, `fn_transform_zkhdcp050()` |
| 02-04 Transform АРМ КК | `fn_transform_arm_kk()` → `stg_arm_kk*` |
| 02-05 Transform МТР | `fn_transform_mtr()` → `stg_mtr` |
| 03-01 PreCalc | `fn_precalc_mtr_involvement_year`, `fn_precalc_ap_factoring`, `fn_precalc_kpd` |
| 03-03 PreCalc BDDS | `fn_precalc_bdds()` → `mart_bdds_*`, `mart_spo_*`, `mart_dds_for_vok` |
| 03-04 PreCalc SAP VOK | `fn_precalc_vok_uo()` → `mart_vok_uo`, calendar |
| 03-05 PreCalc Резервы | `fn_precalc_reserves()` → `mart_reserves*` |
| 03-08 Прогноз авансов | `fn_precalc_forecast_advances()` |
| 03-09 Прогноз ДЗ | `fn_precalc_forecast_ar()` |
| 03-10 Прогноз КЗ | `fn_precalc_forecast_ap()` |
| 03-11 Прогноз МТР | `fn_precalc_forecast_mtr()` |

## Установка

```bash
psql -d <db> -v ON_ERROR_STOP=1 -f sql/00_install_all.sql
```

## Загрузка и расчёт

1. Заполнить таблицы `ods.*` (ETL из Excel/SAP/АРМ/МТР/БДДС).
2. Параметры:

```sql
UPDATE dm_ufkbrd.pipeline_params SET param_value = '2022' WHERE param_name = 'dashboard_year';
UPDATE dm_ufkbrd.pipeline_params SET param_value = to_char(current_date,'YYYY-MM-DD') WHERE param_name = 'as_of_date';
```

3. Полный пересчёт:

```sql
SELECT dm_ufkbrd.fn_run_pipeline();
```

## Основные итоговые таблицы

- `dm_ufkbrd.mart_vok_uo` — единый факт ВОК (УО)
- `dm_ufkbrd.mart_bdds_data` / `mart_bdds_kpi` — вкладка БДДС
- `dm_ufkbrd.mart_reserves*` — резервы
- `dm_ufkbrd.mart_kpd` — КПД
- `dm_ufkbrd.mart_forecast_ar` / `mart_forecast_ap` / `mart_forecast_advances*` / `mart_forecast_mtr` — прогнозы
- `dm_ufkbrd.mart_calendar_turnover` — календарь оборачиваемости

## Совместимость Greenplum 6.22

- DDL с `DISTRIBUTED BY` / `DISTRIBUTED RANDOMLY`
- PL/pgSQL функции без конструкций новее PG 9.4
- Накопительные прогнозы через оконные `SUM() OVER (... ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)` вместо Qlik `Previous`/`peek`
- Crosstab Excel (месяцы) разворачивается на стороне ODS или в `fn_load_refs`

Исходные Qlik-скрипты: `qlik_sources/`.
