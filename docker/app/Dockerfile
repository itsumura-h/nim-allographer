FROM nimlang/nim:alpine

RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories
RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache \
        curl \
        gcc \
        musl-dev \
        bsd-compat-headers \
        openssh-client \
        git \
        lcov \
        sqlite \
        libpq \
        mariadb-dev \
        openssl \
        pcre \
        && \
    rm /usr/lib/mysqld* -fr && \
    rm /usr/bin/mysql* -fr
ENV PATH $PATH:/root/.nimble/bin
RUN nimble install -y \
           bcrypt \
           progress

WORKDIR /root/project
