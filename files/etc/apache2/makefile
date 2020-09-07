.PHONY:
.SILENT:
.DEFAULT_GOAL = restart

logdir = /var/log/apache2/
vi_opt = -p -c 'set ft=apache'
OS     =  $(strip $(shell uname -s))

include  $(OS).mk

t check:
	apachectl -t
vdefault vd:
	vi $(vi_opt) sites-enabled/000-default.conf
ssl vs:
	vi $(vi_opt) sites-enabled/ssl.conf
H hosts:
	apache2 -S

vi:
	vi $(vi_opt)  httpd.conf
configtest c:
	apache2ctl configtest
fullstatus f:
	apache2ctl fullstatus
ports p:
	vi $(vi_opt) ports.conf
vhosts:
	 apachectl -t -D DUMP_VHOSTS
mods M:
	 apachectl -M
sites:
	ls sites-enabled/
tail:
	multitail -cS apache_error $(logdir)/error.log
cmin:
	find $(logdir) -cmin -2 -exec ls -l {} \;

scan: lo amr tear
lo:
	echo localhost scannig... 
	 -curl  -q  --connect-timeout 1 -o /dev/null  http://localhost  2>&1 | tail -1
amr tear:
	echo $@ scannig... 
	 -curl   --connect-timeout 1 -o /dev/null  http://$@       2>&1 | tail -1
slo:
	echo localhost SSL scannig... 
	 -curl  -q  --connect-timeout 1 -o /dev/null  https://localhost  2>&1 | tail -1
scp:
	scp makefile *.mk $(other_site):/etc/apache2/
alias:
	vi -p conf.d/alias.conf
lslocal:
	-lsof -ni:http -i:https | egrep '127'
lsamr:
	-lsof -ni:http -i:https | egrep '192'
lsof ls:
	-lsof -ni:http -i:https
