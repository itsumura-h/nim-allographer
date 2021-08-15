FROM nimlang/nim:latest

RUN apt update && apt-get install -y \
        vim \
        curl \
        sqlite \
        libpq-dev \
        libmysqlclient-dev
ENV PATH $PATH:/root/.nimble/bin
WORKDIR /root/project
RUN nimble install -y
