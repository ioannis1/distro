.PHONY=$(shell ls)
.SILENT:
.DEFAULT_GOAL = dry_run

bin  =  promtail
CONF =  promtail.yaml
#LOG =   tiny.log
LOG =   logs/one_pg.log
LOKI =  --client.url http://127.0.0.1:3100/loki/api/v1/push

opt += --dry-run
opt += -config.file $(CONF)
#opt += -log.level=debug



dry_run:
	cat $(LOG) | promtail --stdin --dry-run $(opt)  $(LOKI) --client.external-labels=ioannis=3
vi:
	vi $(CONF)
metrics m:
	curl -s http://qft:9080//metrics
help h:
	$(bin)  --help
tail t:
	#tail -f /tmp/fout
#rsync r:
	#rsync -av ~/prog/promtail  bulk:prog  --delete
r:
	service promtail restart
s:
	service promtail status
stop start status restart:
	service promtail $@
ps:
	ps xu | grep   promtail #| egrep -v  'aa'

