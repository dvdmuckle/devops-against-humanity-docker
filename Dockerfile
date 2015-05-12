FROM tomcat
MAINTAINER tanner filip <tannerfilip@gmail.com>
# HEY YOU
# READ THIS
# Set what you want your Postgres password to be here. If you don't, it'll work but your postgres password will be "PASSWORD".
ENV PGPASSWORD password 
# add Postgres key
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

# Add postgres repo
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Install!
RUN apt-get update && apt-get install -y postgresql-9.3 postgresql-client-9.3 git maven default-jdk zip
RUN useradd -m pyz 

# Setting up Postgres

USER pyz
# Now pull the code, because we have to compile it.
RUN git clone https://github.com/ajanata/PretendYoureXyzzy /home/pyz/PretendYoureXyzzy
WORKDIR /home/pyz/PretendYoureXyzzy
COPY build.properties /home/pyz/PretendYoureXyzzy/build.properties
RUN mvn clean package war:exploded
WORKDIR /home/pyz/PretendYoureXyzzy/target/ROOT/
RUN zip -r ../../pyz.war ./*
# Now do the port stuff
EXPOSE 8080

COPY cah_cards.sql /home/pyz/cah_cards.sql

USER postgres
RUN /etc/init.d/postgresql start &&\
  psql --command "CREATE USER pyz WITH PASSWORD '$PGPASSWORD';" &&\
  createdb -O pyz pyz &&\
  psql --command "REVOKE CONNECT ON DATABASE pyz FROM PUBLIC;" &&\
  psql --command "GRANT CONNECT ON DATABASE pyz TO pyz;" &&\
  psql --command "GRANT ALL ON ALL TABLES IN SCHEMA public TO pyz;"

USER root
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.3/main/pg_hba.conf
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.3/main/postgresql.conf
RUN /etc/init.d/postgresql start && psql -f /home/pyz/cah_cards.sql -h localhost -U pyz

RUN cp /home/pyz/PretendYoureXyzzy/pyz.war /usr/local/tomcat/webapps/
CMD ["/etc/init.d/postgresql", "start"]
CMD ["catalina.sh", "run"]
