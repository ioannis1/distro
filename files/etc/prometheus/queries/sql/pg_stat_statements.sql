CREATE EXTENSION IF NOT  EXISTS  pg_stat_statements;
CREATE SCHEMA IF NOT EXISTS pgexporter;
GRANT USAGE ON SCHEMA pgexporter TO prometheus;

SET SEARCH_PATH TO pgexporter ;

-- not needed for pg > REL_11
CREATE OR REPLACE FUNCTION get_pg_stat_activity() RETURNS SETOF pg_stat_activity AS
$$ SELECT * FROM pg_catalog.pg_stat_activity; $$
LANGUAGE sql
VOLATILE
SECURITY DEFINER;

-- not needed for pg > REL_11
CREATE OR REPLACE VIEW pg_stat_activity AS
  SELECT * from pgexporter.get_pg_stat_activity();

-- not needed for pg > REL_11
GRANT SELECT ON pg_stat_activity TO prometheus;

-- not needed for pg > REL_11
CREATE OR REPLACE FUNCTION get_pg_stat_replication() RETURNS SETOF pg_stat_replication AS
$$ SELECT * FROM pg_catalog.pg_stat_replication; $$
LANGUAGE sql
VOLATILE
SECURITY DEFINER;

-- not needed for pg > REL_11
CREATE OR REPLACE VIEW pg_stat_replication AS
  SELECT * FROM pgexporter.get_pg_stat_replication();

-- not needed for pg > REL_11
GRANT SELECT ON pg_stat_replication TO prometheus;

-- not needed for pg > REL_11
CREATE OR REPLACE FUNCTION get_pg_stat_statements() RETURNS SETOF public.pg_stat_statements AS
$$ SELECT * FROM public.pg_stat_statements; $$
LANGUAGE sql
VOLATILE
SECURITY DEFINER;

-- not needed for pg > REL_11
CREATE OR REPLACE VIEW pg_stat_statements AS
  SELECT * FROM pgexporter.get_pg_stat_statements();

GRANT SELECT ON pg_stat_statements TO prometheus;
