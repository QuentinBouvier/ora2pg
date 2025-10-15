FROM perl:5.42

RUN apt-get update && apt-get install -y \
    glibc-source \
    libc-bin \
    alien \
    libaio1t64 \
    postgresql-client

# Hack to make libaio1 work for oracle client
RUN ln -s /lib/x86_64-linux-gnu/libaio.so.1t64 /lib/x86_64-linux-gnu/libaio.so.1 && ldconfig

RUN mkdir -p /assets
WORKDIR /assets
RUN curl -o oracle-instantclient-basic-23.9.0.25.07-1.el9.x86_64.rpm https://download.oracle.com/otn_software/linux/instantclient/2390000/oracle-instantclient-basic-23.9.0.25.07-1.el9.x86_64.rpm
RUN curl -o oracle-instantclient-sqlplus-23.9.0.25.07-1.el9.x86_64.rpm https://download.oracle.com/otn_software/linux/instantclient/2390000/oracle-instantclient-sqlplus-23.9.0.25.07-1.el9.x86_64.rpm
RUN curl -o oracle-instantclient-devel-23.9.0.25.07-1.el9.x86_64.rpm https://download.oracle.com/otn_software/linux/instantclient/2390000/oracle-instantclient-devel-23.9.0.25.07-1.el9.x86_64.rpm
RUN curl -o oracle-instantclient-jdbc-23.9.0.25.07-1.el9.x86_64.rpm https://download.oracle.com/otn_software/linux/instantclient/2390000/oracle-instantclient-jdbc-23.9.0.25.07-1.el9.x86_64.rpm

RUN alien -i --scripts oracle-instantclient-*.rpm
RUN rm -rf oracle-instantclient-*.rpm

ENV ORACLE_HOME=/usr/lib/oracle/23/client64
ENV LD_LIBRARY_PATH=/usr/lib/oracle/23/client64/lib
ENV C_INCLUDE_PATH=/usr/include/oracle/23/client64
ENV PERL_MM_USE_DEFAULT=1

RUN cpan install Test::NoWarnings
RUN cpan install DBI
RUN cpan install DBD::Pg
RUN cpan install Bundle::Compress::Zlib
RUN cpanm install DBD::Oracle@1.91_2

RUN mkdir -p /tmp/ora2pg
COPY . /tmp/ora2pg
WORKDIR /tmp/ora2pg

RUN perl Makefile.PL &&\
    make && make install

RUN mkdir -p /data
VOLUME /data
RUN mkdir -p /config
VOLUME /config

WORKDIR /