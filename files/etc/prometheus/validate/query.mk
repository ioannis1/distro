.PHONY: $(shell ls)
.SILENT:
.DEFAULT_GOAL = file
.DEFAULT_GOAL = bylabel
.DEFAULT_GOAL = range

expr    = up{job=\"pro\"}
timeout = 7s
NOW     =`date -u -j +"%Y-%m-%dT%H:%M:%SZ"`    # in UTC
get:
	curl  -g  http://localhost:9090/api/v1/query?query=$(expr)&timeout=$(timeout)&time=$(NOW) 
	echo
#######################################

file = files/ser
file = files/cmd
file = files/prom.sql

host = localhost
port = 5432
user = postgres
db   = prom
conn = -qX -h $(host) -p $(port) -U $(user) -d $(db)


range:
#	curl 'http://localhost:9090/api/v1/query_range?query=up&start=2018-12-25T20:10:30.781Z&end=2018-12-25T20:11:00.781Z&step=15s'
	curl -g -K files/range
del_push dp:
	curl -X DELETE http://localhost:9091/metrics/job/some_job      #/instance/localhost:9091

file:
	curl -g  -K $(file)
	echo
del2:
	curl -X DELETE 'http://localhost:9090/api/v2/admin/tsdb/delete_series'
	curl -X POST -g 'http://localhost:9090/api/v2/admin/tsdb/clean_tombstones'
delete:
	curl -X POST -g 'http://localhost:9090/api/v1/admin/tsdb/delete_series?match[]={country="BR"}'
	curl -X POST -g 'http://localhost:9090/api/v1/admin/tsdb/clean_tombstones'
pg_load:
	curl -s http://localhost:9090/metrics | grep -v "^#" | psql $(conn) -c "COPY metrics_copy FROM STDIN"
pg_query:
	psql $(conn) < $(file)
pport = 9090  # prometheus
pport = 9187  # postgres
metrics:
	curl -s http://localhost:$(strip $(pport))/metrics | egrep -v "^#" 
label  = device
bylabel l:
	./bylabel.pl $(label)
targets:
	curl  -g  http://localhost:9090/api/v1/targets
	echo
