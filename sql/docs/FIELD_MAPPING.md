# Field name mapping (RU Qlik → Latin SQL)

## Common dimensions

| Qlik | SQL |
|------|-----|
| ДО Наименование / ДО Кратко | `do_name` / `do_short_name` |
| Наименование ДО | `do_full_name` |
| БЕ Код / 0COMP_CODE | `be_code` / `comp_code` |
| Период / Дата | `period_dt` / `report_dt` |
| Год | `year_num` |
| Месяц | `month_num` |
| Сумма / Данные | `amount` |
| Сценарий / Отчетный период | `scenario_name` / `report_period` |
| Признак Данные | `data_flag` |
| Источник данных | `source_system` |
| Контрагент Наименование | `counterparty_name` |
| Контрагент ИНН | `counterparty_inn` |
| Контрагент Код / ZKHCONTR | `counterparty_code` / `zkhcontr` |
| Договор Номер | `contract_number` |
| Бухгалтерский счет / 0GL_ACCOUNT | `gl_account` |
| Строка Тип | `row_type` |
| ТИП ДО | `do_type` |
| Признак ДО.ВОК / Резервы / БДДС / МТР / НЗС | `flag_vok` / `flag_reserves` / `flag_bdds` / `flag_mtr` / `flag_nzs` |

## Debt / advances (ARM KK)

| Qlik | SQL |
|------|-----|
| Задолженность Общая (за вычетом резервов) переоценка | `debt_total_reval_rub` |
| Задолженность Просроченная переоценка | `debt_overdue_reval_rub` |
| Задолженность просроченная (>30 дней) | `debt_overdue_gt30_rub` |
| Задолженность просроченная (>5 и <=30 дней) | `debt_overdue_5_30_rub` |
| Авансы Сумма на начало/конец | `advances_bop_rub` / `advances_eop_rub` |
| КЗ на начало/конец | `ap_bop_rub` / `ap_eop_rub` |
| Резерв начисление / восстановление | `reserve_accrual_wo_neg` / `reserve_writeoff_wo_neg` / `reserve_repay_wo_neg` |

## Forecasts

| Qlik | SQL |
|------|-----|
| Прогноз.Сценарий | `scenario_name` |
| Прогноз.Сумма | `forecast_amount` |
| Признак наличия факта | `fact_present_flag` |
| Сумма авансов, планируемых к выдаче | `planned_issue_rub` / `issue_plan_rub` |
| Размер погашения до конца года | `planned_repay_rub` / `repay_plan_rub` |
| Прогноз.Сумма.Выручка / Поступления | `revenue` / `receipts` |
| Прогноз.Сумма.OPEX/CAPEX.* | `opex_exp` / `opex_pay` / `capex_exp` / `capex_pay` / `capex_mtr` |

## BDDS

| Qlik | SQL |
|------|-----|
| ДДС Признак | `dds_flag` |
| ДДС Сумма | `dds_amount` |
| ДДС Период | `dds_period_dt` |
| Порядок статей | `article_order` |
| Группа / Группа1..3 | `group_name` / `group1`..`group3` |
| Сумма план-факт | `amount_plan_fact` |
| План | `plan_amount` |
