FROM openjdk:8-jdk-alpine
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} petclinicapi.jar
#CMD cp -r /opt /
#CMD set UNIQUE_HOST_ID=`grep -i 'systemd' /proc/self/cgroup | grep -oE '[^/]+$' | cut -c 1-12`
#CMD set JAVA_OPTS="-javaagent:/opt/appd/appd_4.5.12/appagent/javaagent.jar -Dappdynamics.agent.uniqueHostId=$UNIQUE_HOST_ID"
# ENTRYPOINT ["/usr/bin/java","$JAVA_OPTS","-jar","/petclinic-rest.jar"]
ENTRYPOINT ["java","-jar","/petclinicapi.jar"]
# ENTRYPOINT ["/usr/bin/java","-javaagent:/opt/appd/appd_4.5.12/appagent/javaagent.jar","-Dappdynamics.agent.uniqueHostId=$UNIQUE_HOST_ID","-jar","/petclinic-rest.jar"]
