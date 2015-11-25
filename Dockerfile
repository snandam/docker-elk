#Kibana

FROM ubuntu:12.04.5
# https://github.com/docker/docker/issues/10324. Ubuntu won't always be able to resolve archive.ubuntu.com
# Hardcoding is bad but using it to be able to build the image

RUN echo "91.189.92.201 archive.ubuntu.com" >> /etc/hosts ; cat /etc/hosts

RUN echo 'deb http://archive.ubuntu.com/ubuntu precise main universe' > /etc/apt/sources.list && \
    echo 'deb http://archive.ubuntu.com/ubuntu precise-updates universe' >> /etc/apt/sources.list && \
    echo 'deb http://archive.ubuntu.com/ubuntu precise-updates main' >> /etc/apt/sources.list && \
    apt-get update

#Prevent daemon start during install
RUN	echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && \
    chmod +x /usr/sbin/policy-rc.d

#Supervisord
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor && \
	mkdir -p /var/log/supervisor
CMD ["/usr/bin/supervisord", "-n"]

#SSHD
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server && \
	mkdir /var/run/sshd && chmod 700 /var/run/sshd && \
	echo 'root:root' |chpasswd

#Utilities
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y wget less nano ntp net-tools inetutils-ping curl git telnet

#Install Oracle Java 7
RUN echo 'deb http://ppa.launchpad.net/webupd8team/java/ubuntu precise main' > /etc/apt/sources.list.d/java.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886 && \
    apt-get update && \
    echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y oracle-java7-installer

#Maven
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y maven


#ElasticSearch
RUN wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.7.0.tar.gz && \
    tar xf elasticsearch-*.tar.gz && \
    rm elasticsearch-*.tar.gz && \
    mv elasticsearch-* elasticsearch && \
    ./elasticsearch/bin/plugin install mobz/elasticsearch-head && \
    ./elasticsearch/bin/plugin install elasticsearch/marvel/latest


#Kibana
RUN wget https://download.elastic.co/kibana/kibana/kibana-4.1.1-linux-x64.tar.gz && \
    tar xf kibana-*.tar.gz && \
    rm kibana-*.tar.gz && \
    mv kibana-* kibana

#NGINX
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python-software-properties && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:nginx/stable && \
    echo 'deb http://packages.dotdeb.org squeeze all' >> /etc/apt/sources.list && \
    curl http://www.dotdeb.org/dotdeb.gpg | apt-key add - && \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx

#Logstash
RUN wget https://download.elasticsearch.org/logstash/logstash/logstash-2.0.0.tar.gz && \
	tar xf logstash-*.tar.gz && \
    rm logstash-*.tar.gz && \
    mv logstash-* logstash

#LogGenerator
RUN git clone https://github.com/vspiewak/log-generator.git && \
	cd log-generator && \
	/usr/share/maven/bin/mvn clean package

#Geo
RUN wget -N http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz && \
	gunzip GeoLiteCity.dat.gz && \
    mv GeoLiteCity.dat /log-generator/GeoLiteCity.dat

#Configuration
ADD ./ /docker-elk
RUN cd /docker-elk && \
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.saved && \
    cp nginx.conf /etc/nginx/nginx.conf && \
    cp supervisord-kibana.conf /etc/supervisor/conf.d && \
    mkdir /logstash/patterns && \
    cp logback /logstash/patterns/logback && \
    cp logstash-forwarder.crt /logstash/logstash-forwarder.crt && \
    cp logstash-forwarder.key /logstash/logstash-forwarder.key

#80=ngnx, 9200=elasticsearch, 5601=kibana, 49021=logstash, 49022=lumberjack, 9999=udp
EXPOSE 22 80 5601 9200 49021 49022 9999/udp
