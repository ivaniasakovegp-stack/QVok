-- Utility functions for Greenplum 6.22 / PostgreSQL 9.4.26

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_month_end(p_dt date)
RETURNS date
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT (date_trunc('month', p_dt)::date + INTERVAL '1 month' - INTERVAL '1 day')::date;
$$;

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_month_start(p_dt date)
RETURNS date
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT date_trunc('month', p_dt)::date;
$$;

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_year_end(p_dt date)
RETURNS date
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT make_date(EXTRACT(YEAR FROM p_dt)::integer, 12, 31);
$$;

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_year_start(p_dt date)
RETURNS date
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT make_date(EXTRACT(YEAR FROM p_dt)::integer, 1, 1);
$$;

-- SAP 0FISCPER like '02024012' -> year=2024, period=12 (13..16 -> 12)
CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_fiscper_to_date(p_fiscper varchar)
RETURNS date
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    v_year integer;
    v_mon  integer;
BEGIN
    IF p_fiscper IS NULL OR length(trim(p_fiscper)) < 6 THEN
        RETURN NULL;
    END IF;
    v_year := substring(p_fiscper from 2 for 4)::integer;
    v_mon  := right(p_fiscper, 2)::integer;
    IF v_mon > 12 THEN
        v_mon := 12;
    END IF;
    RETURN dm_ufkbrd.fn_month_end(make_date(v_year, v_mon, 1));
END;
$$;

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_pad10(p_val varchar)
RETURNS varchar
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT lpad(regexp_replace(coalesce(p_val, ''), '[^0-9]', '', 'g'), 10, '0');
$$;

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_get_param(p_name varchar)
RETURNS varchar
LANGUAGE sql
STABLE
AS $$
    SELECT param_value FROM dm_ufkbrd.pipeline_params WHERE param_name = p_name LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_dashboard_year()
RETURNS integer
LANGUAGE sql
STABLE
AS $$
    SELECT coalesce(dm_ufkbrd.fn_get_param('dashboard_year')::integer, 2022);
$$;

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_as_of_date()
RETURNS date
LANGUAGE sql
STABLE
AS $$
    SELECT coalesce(dm_ufkbrd.fn_get_param('as_of_date')::date, current_date);
$$;

CREATE OR REPLACE FUNCTION dm_ufkbrd.fn_scenario_from_month(p_dt date)
RETURNS varchar
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    v_m integer;
BEGIN
    v_m := EXTRACT(MONTH FROM p_dt)::integer;
    IF v_m = 12 THEN
        RETURN NULL;
    END IF;
    RETURN v_m::text || '+' || (12 - v_m)::text;
END;
$$;
