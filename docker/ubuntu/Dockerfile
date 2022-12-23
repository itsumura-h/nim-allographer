FROM ubuntu:20.04

# prevent timezone dialogue
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update; apt install -y libgnutls30 && \
    apt update --fix-missing && \
    apt upgrade -y
RUN apt install -y --fix-missing \
        gcc \
        xz-utils \
        ca-certificates \
        vim \
        curl \
        wget \
        git \
        libsass-dev \
        sqlite3 \
        libpq-dev \
        libmariadb-dev

ARG VERSION="1.6.10"
WORKDIR /root
RUN wget --inet4-only https://nim-lang.org/download/nim-${VERSION}-linux_x64.tar.xz && \
    tar -Jxf nim-${VERSION}-linux_x64.tar.xz && \
    rm -f nim-${VERSION}-linux_x64.tar.xz && \
    mv nim-${VERSION} .nimble

RUN rm -rf /var/lib/apt/lists/*
ENV PATH $PATH:/root/.nimble/bin
WORKDIR /root/project
COPY ./allographer.nimble .
RUN nimble install -y
RUN nimble install -y \
           bcrypt \
           progress
