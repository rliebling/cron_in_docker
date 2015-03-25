FROM ubuntu

RUN apt-get update && apt-get install -y cron rsyslog
COPY cronfile /
RUN cp /cronfile /etc/cron.d


CMD rsyslogd && cron && tail -f /var/log/syslog

