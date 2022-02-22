FROM nimlang/nim:1.6.2-ubuntu-regular

RUN apt update; apt install -y libgnutls30 && \
    apt upgrade -y && \
    apt install -y --no-install-recommends \
        vim \
        curl \
        sqlite \
        libpq-dev \
        libmysqlclient-dev
RUN rm -rf /var/lib/apt/lists/*
ENV PATH $PATH:/root/.nimble/bin
WORKDIR /root/project
COPY ./allographer.nimble .
RUN nimble install -y
RUN nimble install -y \
           bcrypt \
           progress
