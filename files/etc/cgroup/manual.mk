.SILENT:
.PHONY: $(shell ls)
.DEFAULT_GOAL = create

GROUP  =   foo

PID = 26980

create:
	mkdir -p /sys/fs/cgroup/memory/$(GROUP)
	#cgcreate  -g memory:/$(GROUP)
del:
	cgdelete  memory:/$(GROUP)
ls:
	ls   /sys/fs/cgroup/memory/$(GROUP)
mlimit:
	cat /sys/fs/cgroup/memory/$(GROUP)/memory.limit_in_bytes #9223372036854771712
m50mb:
	echo 50000000 | tee  /sys/fs/cgroup/memory/$(GROUP)/memory.limit_in_bytes        # 50 MB
m1k:
	echo 1000 | tee /sys/fs/cgroup/memory/$(GROUP)/memory.limit_in_bytes    
m50k:
	echo 50000 | tee /sys/fs/cgroup/memory/$(GROUP)/memory.limit_in_bytes    
add:
	echo $(PID) > /sys/fs/cgroup/memory/$(GROUP)/cgroup.procs
procs:
	cat  /sys/fs/cgroup/memory/$(GROUP)/cgroup.procs
mem:
	cat /sys/fs/cgroup/memory/$(GROUP)/memory.usage_in_bytes


ps:
	ps -o cgroup $(PID)

