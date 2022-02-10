FROM nimlang/nim:1.6.2-alpine-regular

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
WORKDIR /root/project
COPY ./allographer.nimble .
RUN nimble install -y
RUN nimble install -y \
           bcrypt \
           progress
