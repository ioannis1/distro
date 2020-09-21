.PHONY=$(shell ls)
.SILENT:
.DEFAULT_GOAL = run

bin = /opt/td-agent-bit/bin/td-agent-bit
CONF = c.conf

opt +=

run:
	$(bin)  $(opt)  -c $(CONF) 
metrics m:
	curl -s http://127.0.0.1:2020/api/v1/metrics
15 16:
	less ../log/main-$@.log
