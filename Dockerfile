#
# Quick and dirty contained environement for runnning a ServerBear benchmark
#
# Reference:
# * http://www.serverbear.com
# * https://github.com/Crowd9/Benchmark
#
FROM ubuntu:14.04

MAINTAINER Kyle Manna <kyle@kylemanna.com>

ENV DEBIAN_FRONTEND noninteractive

ADD sb.sh /usr/local/bin/
RUN chmod a+x /usr/local/bin/sb.sh && \
    apt-get update && \
    apt-get install -y build-essential curl wget traceroute libaio-dev && \
    apt-get clean && apt-get purge && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME ["/test"]
WORKDIR /test

ENTRYPOINT ["sb.sh"]
