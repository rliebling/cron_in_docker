# Cron in Docker containers

### What did __not__ work

Some people describe an approach where your Dockerfile uses a step like this
```
RUN crontab /path/to/my_crontab_file
CMD cron -f
```

Here, the crontab utility is used to install the cron jobs when building the
image, and then the cron daemon runs when a container is launched and is
expected to fire off the jobs defined in the crontab.

What this example repo shows, on the master branch, is a simple case of that
where this fails.  I cannot really explain why it fails, but presume for some
reason cron, when starting up, does not read or accept the jobs defined in
`/var/spool/cron/crontabs/root`, which is where the `crontab` utility installs
them.

What's baffling to me is that i have had several docker projects use exactly this
scheme and work reliably for a while, before suddenly not working anymore.  It's
entirely possible that this is because of something i changed, but i did check
the obvious things (eg the Dockerfile didn't change, the cron definition didn't
change, the shell file it ran didn't change, ...)

### Here's the way I suggest doing it instead

A more reliable way, i believe, is to install your crontab in /etc/cron.d (at least
on Debian-based systems, where cron will read files here).  Note that the file format
is slightly different, by including the username after the schedule definition and
before the command.

Example Dockerfile snippet
```
COPY my_crontab_file /etc/cron.d/
CMD cron -f
```

See the branch `cron_works` for example code

### How to run this example

Checkout whichever branch (master shows it broken, and `cron_works` shows it working)

```
$ docker build --rm -t ct .
Sending build context to Docker daemon 66.56 kB
Sending build context to Docker daemon 
Step 0 : FROM ubuntu
 ---> e54ca5efa2e9
Step 1 : RUN apt-get update && apt-get install -y cron rsyslog
 ---> Using cache
 ---> 81f5a27faed4
Step 2 : COPY cronfile /
 ---> ac7b4913a846
Removing intermediate container b6df3a30c4b4
Step 3 : RUN cp /cronfile /etc/cron.d
 ---> Running in 825541197c29
 ---> 10059fa9e1b6
Removing intermediate container 825541197c29
Step 4 : CMD rsyslogd && cron && tail -f /var/log/syslog
 ---> Running in bfa45ec1725f
 ---> 18ca47a89da2
Removing intermediate container bfa45ec1725f
Successfully built 18ca47a89da2

$ docker run -d --name ct1 ct
610e6fa6fccad22f50df201d78bc3dc9abc357bce311b3dac84603587251628d

$ docker logs -f ct1
Mar 25 16:28:01 610e6fa6fcca rsyslogd: [origin software="rsyslogd" swVersion="7.4.4" x-pid="6" x-info="http://www.rsyslog.com"] start
Mar 25 16:28:01 610e6fa6fcca rsyslogd: imklog: cannot open kernel log (/proc/kmsg): Operation not permitted.
Mar 25 16:28:01 610e6fa6fcca rsyslogd-2145: activation of module imklog failed [try http://www.rsyslog.com/e/2145 ]
Mar 25 16:28:01 610e6fa6fcca rsyslogd: rsyslogd's groupid changed to 104
Mar 25 16:28:01 610e6fa6fcca rsyslogd: rsyslogd's userid changed to 101
Mar 25 16:28:01 610e6fa6fcca rsyslogd-2039: Could no open output pipe '/dev/xconsole': No such file or directory [try http://www.rsyslog.com/e/2039 ]
Mar 25 16:28:01 610e6fa6fcca cron[7]: (CRON) INFO (pidfile fd = 3)
Mar 25 16:28:01 610e6fa6fcca cron[10]: (CRON) STARTUP (fork ok)
Mar 25 16:28:01 610e6fa6fcca cron[10]: (CRON) INFO (Running @reboot jobs)
Mar 25 16:29:01 610e6fa6fcca CRON[13]: (root) CMD (echo "cron is working at `date`" | logger)
Mar 25 16:29:01 610e6fa6fcca logger: cron is working at Wed Mar 25 16:29:01 UTC 2015
Mar 25 16:30:01 610e6fa6fcca CRON[13]: (root) CMD (echo "cron is working at `date`" | logger)
Mar 25 16:30:01 610e6fa6fcca logger: cron is working at Wed Mar 25 16:30:01 UTC 2015
```

The last four lines above indicate the cron job is firing.  They will not appear
in the `master` branch version.


