FROM openjdk:8-jdk-alpine
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} petclinic-rest.jar
ENV APPDYNAMICS_AGENT_APPLICATION_NAME=PETCLINIC-REST
ENV APPDYNAMICS_AGENT_ACCOUNT_NAME=fedex1-test
ENV APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY=1dce5fc52c17
ENV APPDYNAMICS_CONTROLLER_HOST_NAME=fedex1-test.saas.appdynamics.com
ENV APPDYNAMICS_CONTROLLER_PORT=443
ENV APPDYNAMICS_CONTROLLER_SSL_ENABLED=true
ENV APPDYNAMICS_AGENT_NODE_NAME=aks-default-27669806-vmss000005
CMD cp -r /opt /
CMD chmod -R o+x /opt/appd/
CMD set UNIQUE_HOST_ID=`grep -i 'systemd' /proc/self/cgroup | grep -oE '[^/]+$' | cut -c 1-12`
CMD set JAVA_OPTS="-javaagent:/opt/appd/appd_4.5.12/appagent/javaagent.jar -Dappdynamics.agent.uniqueHostId=$UNIQUE_HOST_ID"
# ENTRYPOINT ["/usr/bin/java","$JAVA_OPTS","-jar","/petclinic-rest.jar"]
# ENTRYPOINT ["java","-jar","/petclinic-rest.jar"]
ENTRYPOINT ["/usr/bin/java","-javaagent:/opt/appd/appd_4.5.12/appagent/javaagent.jar","-Dappdynamics.agent.uniqueHostId=$UNIQUE_HOST_ID","-jar","/petclinic-rest.jar"]
