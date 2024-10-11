FROM ubuntu:24.04

# prevent timezone dialogue
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update
RUN apt upgrade -y
RUN apt install -y \
    gcc \
    xz-utils \
    ca-certificates \
    curl \
    git \
    sqlite3 \
    libpq-dev \
    libmariadb-dev

# Nim
ARG NIM_VERSION="2.0.0"
WORKDIR /root
RUN curl https://nim-lang.org/choosenim/init.sh -o init.sh
RUN sh init.sh -y
RUN rm -f init.sh
ENV PATH $PATH:/root/.nimble/bin
RUN choosenim ${NIM_VERSION}

WORKDIR /root/project
COPY ./allographer.nimble .
RUN nimble install -y -d

RUN git config --global --add safe.directory /root/project

WORKDIR /root/project
