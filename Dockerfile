FROM debian:wheezy

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r redis && useradd -r -g redis redis

RUN apt-get update \
    && apt-get install -y curl \
    && rm -rf /var/lib/apt/lists/*

# grab gosu for easy step-down from root
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture)" \
    && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture).asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu

ENV REDIS_VERSION 3.0.0
ENV REDIS_DOWNLOAD_URL http://download.redis.io/releases/redis-3.0.0.tar.gz
ENV REDIS_DOWNLOAD_SHA1 c75fd32900187a7c9f9d07c412ea3b3315691c65

# for redis-sentinel see: http://redis.io/topics/sentinel
RUN buildDeps='gcc libc6-dev libyajl-dev cmake make git'; \
    set -x \
    && apt-get update && apt-get install -y $buildDeps --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /usr/src/redis \
    && cd /usr/src/redis \
    && git clone https://github.com/mattsta/redis \
    && cd redis \
    && git checkout dynamic-redis-unstable \
    && make -C /usr/src/redis/redis \
    && make -C /usr/src/redis/redis install \
    && mkdir -p /usr/src/krmt \
    && cd /usr/src/krmt \
    && git clone https://github.com/mattsta/krmt \
    && cd krmt \
    && make -j \
    && cp geo.so /usr/lib \
    && rm -rf /usr/src/redis /usr/src/krmt \
    && apt-get purge -y --auto-remove $buildDeps

RUN mkdir /data && chown redis:redis /data
VOLUME /data
WORKDIR /data

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 6379
CMD [ "redis-server" ]
