this_site  = tear
other_site = amr

status:
	-apachectl -k $@

restart_: stop
	sleep 2
	make start

stop start restart:

	/etc/init.d/apache2 $@

ps:
	ps xa |grep apache | egrep -v grep
