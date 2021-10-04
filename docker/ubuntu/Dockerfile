FROM nimlang/nim:1.4.8-ubuntu

# RUN cat /etc/os-release
# RUN apt upgrade -y ca-certificates
# RUN update-ca-certificates
# RUN apt update -y
# RUN apt upgrade -y
# RUN apt install -y \
#         vim \
#         curl \
#         sqlite \
#         libpq-dev \
#         libmysqlclient-dev \
#         --fix-missing
RUN apt update && apt-get install -y \
        vim \
        curl \
        sqlite \
        libpq-dev \
        libmysqlclient-dev
ENV PATH $PATH:/root/.nimble/bin
WORKDIR /root/project
COPY ./allographer.nimble .
RUN nimble install -y
