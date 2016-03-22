FROM quay.io/ukhomeofficedigital/centos-base:v0.2.0

RUN yum install -y java-headless openssl
RUN curl -s -L https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/bin/jq && chmod 0755 /usr/bin/jq

WORKDIR /data
VOLUME /data

COPY run.sh /run.sh
CMD /run.sh
