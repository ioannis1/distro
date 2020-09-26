.PHONY: $(shell ls)
.SILENT:
.DEFAULT_GOAL = reload
.DEFAULT_GOAL = test


bin    = /bin/consul
#LOG    = /tmp/consul.log
#PID    = /tmp/consul.pid
#RUNDIR = /var/consul
CONFDIR= /etc/consul.d

#copt +=  -log-file=$(LOG)
#copt += -datacenter=dc1
#copt +=  -log-level=<value>
#copt +=  -log-rotate-bytes=<value>
#copt +=  -log-rotate-duration=

help:
	$(bin) --help
help_start hs:
	$(bin) agent --help
start stop restart status:  
	#mkdir -p $(RUNDIR)
	#$(SUDO) $(bin) agent  -dev  --config-dir=$(CONFDIR)  &
	service consul $@
#stop:  
	#ps axu|grep bin/consul|egrep -v grep| perl -ae 'print "@F[1]\n"' | xargs  kill -TERM 
#reload: 
	#ps axu|grep bin/consul|egrep -v grep| perl -ae 'print "@F[1]\n"' | xargs  kill -HUP 
telemetry tel: 
	ps axu|grep bin/consul|egrep -v grep| perl -ae 'print "@F[1]\n"' | xargs  kill -USR1 
members m:
	$(SUDO) $(bin) members
info i:
	$(SUDO) $(bin) info | head -29
services s:
	$(SUDO) $(bin) catalog $@   # -node=bulk
nodes n:
	$(SUDO) $(bin) catalog $@   #  -service=postgres-exporter


cat log:
	cat $(LOG)	
tail :
	#tail -f $(LOG)	
	consul monitor
ver:
	consul version

pid:
	cat $(PID) ; echo
ps:
	-ps xau |grep bin/consul |egrep -v grep
backup:
	-tar -cpvf consul.tgz         $(CONFDIR)/ $(CONFDIR)-/  handlers/   files/  makefile   *.mk 
id:
	cat $(RUNDIR)/node-id ;echo
clean: stop
	rm -rf $(RUNDIR)/* 
validate v:
	consul validate $(CONFDIR)
default d:
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

