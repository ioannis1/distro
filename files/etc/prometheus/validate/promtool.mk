.PHONY: $(shell ls)
.SILENT:
.DEFAULT_GOAL = help
.DEFAULT_GOAL = conf

CONF    = /etc/prometheus/prometheus.yml
RULES   = /etc/prometheus/rules/
label   = device
server  = http://localhost:9090
#query   = node_filesystem_size_bytes{device="/dev/disk1",fstype="hfs",mountpoint="/Volumes/Macintosh HD"}
name   = node_filesystem_size_bytes #{device="/dev/disk1",fstype="hfs",mountpoint="/Volumes/Macintosh HD"}
name   = node_cpu_seconds_total


NOW     =`date -u -j +"%Y-%m-%dT%H:%M:%SZ"`    # in UTC

conf:
	promtool check config $(CONF)
labels lb:
	promtool query labels http://localhost:9090  $(label) 
series q:
	promtool query series --match=$(name)  $(server)
ru:
	promtool check rules $(RULES)
metrics:
	curl -s http://localhost:9090/metrics | promtool check metrics
bylabel l:
	./bylabel.pl $(label)
node:
	curl -s http://localhost:9100/metrics 
help:
	promtool help
r: restart
s: status
tail:
	tail -f /var/log/daemon.log
start stop status restart:
	service prometheus $@
