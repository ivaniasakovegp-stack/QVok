-- UFKBRD VOK dashboard: schemas for Greenplum 6.22 / PostgreSQL 9.4.26
-- ods  - operational data store (source tables as loaded)
-- dm_ufkbrd - datamart: refs, staging, marts, load functions

CREATE SCHEMA IF NOT EXISTS ods;
CREATE SCHEMA IF NOT EXISTS dm_ufkbrd;

COMMENT ON SCHEMA ods IS 'ODS layer: raw/source tables for UFKBRD VOK (Excel NSI, SAP, ARM KK, MTR, BDDS, SPO/KLAD, Atlas)';
COMMENT ON SCHEMA dm_ufkbrd IS 'Datamart UFKBRD VOK: reference maps, transforms, precalc functions and final fact tables';
