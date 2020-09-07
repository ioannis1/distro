this_site  = amr
other_site = tear
plist      = /System/Library/LaunchDaemons/org.apache.httpd.plist

restart: stop
	sleep 2
	make start


reload: unload load
load unload:
	launchctl $@ -w $(plist)
start stop :
	apachectl -k $@
list :
	-launchctl list | egrep org.apache.httpd
cat:
	-launchctl $@ org.apache.httpd
ps:
	-ps xc | grep -i http
