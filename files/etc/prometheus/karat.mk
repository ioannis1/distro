.PHONY: $(shell ls)
.SILENT:
.DEFAULT_GOAL = reload
.DEFAULT_GOAL = validate


bin    = consul
#LOG    = /tmp/consul.log
CONFDIR= /etc/consul.d


members m:
	$(SUDO) $(bin) members
info i:
	$(SUDO) $(bin) info | head -29
services s:
	$(SUDO) $(bin) catalog services  # -node=bulk
nodes n:
	$(SUDO) $(bin) catalog nodes   #  -service=postgres-exporter

add_karat add:
	-@(mv  -f $(CONFDIR)/postgres_exporter_5433.json-  $(CONFDIR)/postgres_exporter_5433.json) 2>/dev/null
	-@(mv  -f $(CONFDIR)/grok_exporter_karat.json-     $(CONFDIR)/grok_exporter_karat.json ) 2>/dev/null 
	ls $(CONFDIR)/postgres_exporter_5433.json*         $(CONFDIR)/grok_exporter_karat.json*
	@service consul restart
	@service  prometheus-postgres-exporter_5433 start
rm_karat  rem:
	-@(mv  -f $(CONFDIR)/postgres_exporter_5433.json  $(CONFDIR)/postgres_exporter_5433.json- ) 2>/dev/null
	-@(mv  -f $(CONFDIR)/grok_exporter_karat.json     $(CONFDIR)/grok_exporter_karat.json-    ) 2>/dev/null
	ls $(CONFDIR)/postgres_exporter_5433.json*         $(CONFDIR)/grok_exporter_karat.json*
	@service consul restart
	@service  prometheus-postgres-exporter_5433 stop


rm_karat:

cat log:
	cat $(LOG)	
tail :
	@#tail -f $(LOG)	
	tail -f /var/log/daemon.log
	@#consul monitor
ver:
	consul version

pid:
	cat $(PID) ; echo
ps:
	-ps xau |grep bin/consul |egrep -v grep
validate v:
	consul validate $(CONFDIR)
default vi:
	vi /etc/default/consul
h:
	echo help 
	echo 'help_start  (hs)'
	echo 'start stop restart status'
	echo '(tel)emetry'
	echo '(m)members'
	echo '(i)info'
	echo '(s)services'
	echo '(n)odes'
	echo '(v)alidate'
	echo '(d)default'
	echo 'cat, tail, ver, pid, ps, id'

help:
	$(bin) --help
help_start hs:
	$(bin) agent --help
start stop restart status:  
	#mkdir -p $(RUNDIR)
	#$(SUDO) $(bin) agent  -dev  --config-dir=$(CONFDIR)  &
	service consul $@
