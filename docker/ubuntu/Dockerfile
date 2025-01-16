FROM ubuntu:24.04

# prevent timezone dialogue
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update
RUN apt upgrade -y
RUN apt install -y \
    gcc \
    xz-utils \
    ca-certificates \
    libpcre3-dev \
    vim \
    curl \
    git \
    sqlite3 \
    libpq-dev \
    libmariadb-dev

# gcc... for Nim
# xz-utils... for unzip tar.xz
# ca-certificates... for https
# libpcre3-dev... for nim regex

WORKDIR /root

# Nim
ARG NIM_VERSION="2.0.0"
RUN curl https://nim-lang.org/choosenim/init.sh -o init.sh
RUN sh init.sh -y
RUN rm -f init.sh
ENV PATH $PATH:/root/.nimble/bin
RUN choosenim ${NIM_VERSION}

# nimlangserver
# https://github.com/nim-lang/langserver/releases
RUN curl -o nimlangserver.tar.gz -L https://github.com/nim-lang/langserver/releases/download/v1.8.0/nimlangserver-linux-amd64.tar.gz
RUN tar zxf nimlangserver.tar.gz
RUN rm -f nimlangserver.tar.gz
RUN mv nimlangserver /root/.nimble/bin/

WORKDIR /root/project
COPY ./allographer.nimble .
RUN nimble install -y -d

RUN git config --global --add safe.directory /root/project
