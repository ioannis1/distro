DROP SCHEMA IF EXISTS pgexporter CASCADE;
CREATE SCHEMA IF NOT EXISTS pgexporter AUTHORIZATION prometheus;

SET SEARCH_PATH  to pgexporter;

GRANT EXECUTE ON FUNCTION ls_dir(text) TO prometheus;
CREATE OR REPLACE FUNCTION ls_dir( dir text ) RETURNS SETOF text AS
$$ SELECT * FROM pg_catalog.pg_ls_dir(dir); $$
LANGUAGE sql
VOLATILE
SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION ls_dir(text) TO prometheus;


-- not needed for pg > REL_11
CREATE OR REPLACE FUNCTION ls_logdir( ) RETURNS numeric AS
$$ SELECT sum( (i).size)  FROM pg_catalog.pg_ls_logdir() as i; $$
LANGUAGE sql
VOLATILE
SECURITY DEFINER;

-- not needed for pg > REL_11
GRANT EXECUTE ON FUNCTION ls_logdir()  TO prometheus;


