FROM ubuntu

RUN apt-get update && apt-get install -y cron rsyslog
COPY cronfile /
RUN crontab /cronfile


CMD rsyslogd && cron && tail -f /var/log/syslog

