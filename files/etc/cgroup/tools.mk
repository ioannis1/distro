.SILENT:
.PHONY: $(shell ls)
.DEFAULT_GOAL = check

group  = foo

PID = 26980
CG_CONF = etc.conf
CG_CONF = /etc/cgconfig.conf

reload: stop del install start

install i: uninstall
	mkdir -p /etc/cgroup
	install   rules.conf                 /etc/cgroup/
	install   makefile                   /etc/cgroup/
	ln -sf    /etc/cgroup/rules.conf     /etc/cgrules.conf
	install   cgred.conf                  /etc/cgroup/
	install   cgconfig.conf               /etc/
	install   cgconfigparser.service      /etc/systemd/system/
	install   cgrulesgend.service         /etc/systemd/system/
uninstall u:
	rm    -f    /etc/cgroup/*
	rm    -f    /etc/cgred.conf  
	rm    -f    /etc/cgconfig.conf
	rm    -f    /etc/{rules.conf,cgrules.conf}
	rm    -f    /etc/systemd/system/cgconfigparser.service
	rm    -f    /etc/systemd/system/cgrulesgend.service

parser par: 
	cgconfigparser -l  $(CG_CONF)
	/usr/sbin/cgrulesengd -vvv
check:  par
	cat /sys/fs/cgroup/cpu/$(group)/tasks
	cat /sys/fs/cgroup/memory/$(group)/tasks

	systemctl daemon-reload
	systemctl $(patsubst systemd_%,%,$@)  cgconfigparser
	systemctl $(patsubst  systemd_%,%,$@)  cgrulesgend

start stop status enable disable  restart:
	systemctl daemon-reload
	systemctl $(patsubst  systemd_%,%,$@)  cgrulesgend
	systemctl $(patsubst systemd_%,%,$@)  cgconfigparser
	
create:
	cgcreate  -g memory:/foo
del:
	-cgdelete  memory:/foo
ls:
	ls   /sys/fs/cgroup/memory/foo
mlimit:
	cat /sys/fs/cgroup/memory/foo/memory.limit_in_bytes #9223372036854771712
add:
	cgexec -g memory:/foo   ./sleeper.sh &

procs:
	cat  /sys/fs/cgroup/memory/foo/cgroup.procs
mem:
	cat /sys/fs/cgroup/memory/foo/memory.usage_in_bytes
log:
	cat /var/log/messages 

ps:
	ps -f -o pid -o user  -o cgroup  | sort -n
	#ps  -o pid -o user  -o cgroup  | sort -n


m50mb:
	echo 50000000 | tee  /sys/fs/cgroup/memory/foo/memory.limit_in_bytes        # 50 MB
m1k:
	echo 1000 | tee /sys/fs/cgroup/memory/foo/memory.limit_in_bytes    
m50k:
	echo 50000 | tee /sys/fs/cgroup/memory/foo/memory.limit_in_bytes    
rules :
	cat /etc/cgroup/rules.conf
vi:
	vi /etc/cgroup/rules.conf
