FROM azul/zulu-openjdk:11 as build

RUN apt-get update && apt-get install -y maven curl tar gzip bash perl git

# Add script used by LDS servers to clone all SSB snapshot dependencies
ADD clone_snapshots.sh /

# Warm maven cache using stable LDS core
RUN git clone https://github.com/statisticsnorway/linked-data-store-core.git
WORKDIR /linked-data-store-core
RUN git checkout $(git tag | tail -1)
RUN mvn -B verify dependency:go-offline
WORKDIR /

#
# Build LDS Server
#
RUN ["jlink", "--strip-debug", "--no-header-files", "--no-man-pages", "--compress=2", "--module-path", "/opt/jdk/jmods", "--output", "/linked",\
 "--add-modules", "jdk.unsupported,java.base,java.management,java.net.http,java.xml,java.naming,java.desktop,java.sql"]
COPY pom.xml /lds/server/
WORKDIR /lds
RUN cat server/pom.xml | /clone_snapshots.sh && for i in $(ls -d */ | cut -f1 -d'/'); do cd $i; mvn -B install; cd ..; done
WORKDIR /lds/server
RUN mvn -B verify dependency:go-offline
COPY src /lds/server/src/
RUN mvn -B -o verify && mvn -B -o dependency:copy-dependencies

#
# Build LDS image
#
FROM ubuntu:18.04

RUN apt-get update && apt-get install -y curl

RUN curl -O https://www.foundationdb.org/downloads/6.0.15/ubuntu/installers/foundationdb-clients_6.0.15-1_amd64.deb
RUN dpkg -i foundationdb-clients_6.0.15-1_amd64.deb

COPY fdb.cluster /etc/foundationdb/

#
# Resources from build image
#
COPY --from=build /linked /opt/jdk/
COPY --from=build /lds/server/target/dependency /opt/lds/lib/
COPY --from=build /lds/server/target/linked-data-store-*.jar /opt/lds/server/
RUN touch /opt/lds/saga.log

ENV PATH=/opt/jdk/bin:$PATH

WORKDIR /opt/lds

VOLUME ["/conf", "/schemas"]

EXPOSE 9090

CMD ["java", "-cp", "/opt/lds/server/*:/opt/lds/lib/*", "no.ssb.lds.server.Server"]
