# COPYRIGHT (c) Ioannis Tambouras   2017

.PHONY: $(shell ls)
.SILENT:
.DEFAULT_GOAL = start
.DEFAULT_GOAL = help

DIR    =  /etc/pgbouncer
port   =  6543
LOG    =  /var/log/postgresql/pgbouncer.log
CONFIG =  $(DIR)/pgbouncer.ini
LOG    =  `cat $(CONFIG)| egrep '\blogfile\b'|egrep -v '^\#'|cut -f 2 -d =   `
SUDO   =  sudo


opt    =  --daemon --user=postgres


pause resume:
	psql -X -p $(port) -d  pgbouncer -c '$@ lessons'
	psql -X -p $(port) -d  pgbouncer -c 'show pools'
	

vi conf ini:
	vi $(CONFIG)
hba:
	vi $(DIR)/hba.conf


start:
	pgbouncer $(opt)  $(CONFIG)
restart: stop start
reload:
	pgbouncer $(opt) -R $(CONFIG) 
pg:
	psql -X -p $(port)  pgbouncer  postgres
ps:
	ps -ax|grep -e '\bpgbouncer' #|tr -d \  | cut -f 1 -d ?
pid:
	 cat `grep pid $(CONFIG) | cut -f 3 -d \  `
stop kill:
	 killall pgbouncer

clients servers \
stats databases users pools lists fds config dns_hosts :
	psql -X -p $(port) -c 'show $@' -U postgres -d pgbouncer
cat log:
	cat $(LOG) 
tail:
	tail -f $(LOG) 
clean:
	rm -f $(LOG)
cert_check cert:
	cert_check_bouncer
disable enable:
	psql -X -p $(port) -c '$@ timescaledb'
	psql -X -p $(port) -c 'show databases'
ver:
	pgbouncer -V
		
help:
	echo start restart reload stop  cert_check
	echo ps vi pg pid  log clean
	echo clients servers stats databases users pools lists 
	echo fds config dns_hosts
######################################################
first    = `expr $1 : '\(.\)' `
cluster  = $(if $(findstring m,$(call first,$1)),main,$(if  $(findstring k,$(call first,$1)),karat,green))
mcat kcat gcat:
	make -f ~postgres/db.mk $(call rm_first,$@)  cluster=$(call cluster,$@)
first    = `expr $1 : '\(.\)' `
######################################################
systemd_start sa:
	$(SUDO)  /bin/systemctl start pgbouncer
systemd_stop  so:
	$(SUDO)  killall pgbouncer
systemd_restart  :
	$(SUDO)  /bin/systemctl reload pgbouncer

