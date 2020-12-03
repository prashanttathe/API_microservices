#!/bin/bash
#######################################################################################################
# machine_agent_appd.sh - script to set the AppDynamics parameters
# This script sets the java -D parameters for the AppDynamics machine agent. The script is called with EAI 
# Number as an argument.
# Author - Chuck Cianciola - 81845 - chuck.cianciola@fedex.com
# 2013.03.12 Initial creation. Chuck Cianciola
# 2017.01.17 modified to allow machine agent to start independently or without app agent.
#            if started by app_agent_appd.sh, don't hit curl.  use existing results.  only hit webservice
#            if starting machine agent as standalone.
#######################################################################################################
export HOSTNAME=`hostname`	# this will be passed to webservice to match serverName from serverconfig.csv
export LOGDIR=/var/fedex/appd/logs
export CONTROLLER_SSL_ENABLED=true
export APPD_ENABLED=YES
export APPD_JAVA_HOME=/opt/java/hotspot/8/latest
MEM_ARGS="-Xmx256m -Xms128m"
LOGFILE=${LOGDIR}/machine_agent_startup.log
. /etc/init.d/functions


#####################################################################################################################
#Use APPD_JAVA_HOME if set, otherwise use JAVA_HOME
if [  -n "${APPD_JAVA_HOME+set}" ] || [  -n "${JAVA_HOME+set}" ]
then
APPD_JAVA_HOME=${APPD_JAVA_HOME:-${JAVA_HOME}} #Use APPD_JAVA_HOME if set, otherwise use JAVA_HOME
export APPD_JAVA_HOME=${APPD_JAVA_HOME:-${JAVA_HOME}}
export JAVA_CMD=${APPD_JAVA_HOME}/bin/java
echo JAVA_HOME=$JAVA_HOME
echo APPD_JAVA_HOME=$APPD_JAVA_HOME
echo JAVA_CMD=$JAVA_CMD
echo JAVA_HOME=$JAVA_HOME >> ${LOGFILE}
echo APPD_JAVA_HOME=$APPD_JAVA_HOME >> ${LOGFILE}
echo JAVA_CMD=$JAVA_CMD >> ${LOGFILE}
else
echo Please set a valid APPD_JAVA_HOME or JAVA_HOME to run the machine agent
echo "Please set a valid APPD_JAVA_HOME or JAVA_HOME to run the machine agent" >> ${LOGFILE}
echo JAVA_HOME=$JAVA_HOME
echo APPD_JAVA_HOME=$APPD_JAVA_HOME
echo JAVA_CMD=$JAVA_CMD
echo JAVA_HOME=$JAVA_HOME >> ${LOGFILE}
echo APPD_JAVA_HOME=$APPD_JAVA_HOME >> ${LOGFILE}
echo JAVA_CMD=$JAVA_CMD >> ${LOGFILE}
echo "Machine agent NOT started." >> ${LOGFILE}
exit 0
fi

#####################################################################################################################
if [ $# -eq 2 ]; then
        export EAINUMBER=${1}
        export ACTION=${2}
elif [ $# -eq 1 ]; then
        export ACTION=${1}
fi


export APP_LOGDIR=${LOGDIR}/${EAINUMBER}

#####################################################################################################################
# Create Log file if not there
if [[ ! -d $APP_LOGDIR ]]
then
	mkdir -p $APP_LOGDIR
fi




#####################################################################################################################
if [[ -z "${STANDALONE}" ]] # if not set by app_agent_appd.sh (not set = Standalone) set it to true here
then
	STANDALONE=true
else
	STANDALONE=false
fi

echo "#########################################################################################################" >> ${LOGFILE}
echo `date` >> ${LOGFILE}
echo "JAVA_CMD = ${JAVA_CMD}" >> ${LOGFILE}
echo "STANDALONE=${STANDALONE}, arg1=${1}, arg2=${2}" >> ${LOGFILE}

#####################################################################################################################
# if there are 2 args, use them.  if there is one arg, use $EAINUMBER as exported and passed in from app_agent script
# from legacy "if" block that is not needed anymore.  just need to account for teams not removing the "if" block.
# Check for the cmd line args.  Bail out if not there.
if [ $# -eq 2 ] || [ $# -eq 1 ]; then
	echo "ACTION=${ACTION}" >> ${LOGFILE}
	echo "EAINUMBER=${EAINUMBER}" >> ${LOGFILE}
	echo "standalone=${STANDALONE}" >> ${LOGFILE}
else
	echo "Invalid # of cmdline args given" >> ${LOGFILE}
	echo "Usage: $0 EAINUMBER {start|stop|restart|reload|status}" >> ${LOGFILE}
	echo "For example: $0 5125 start" >> ${LOGFILE}
	export APPD_ENABLED=NO
	exit
fi

if [ -z ${EAINUMBER+x} ]; then
		echo "EAINUMBER is unset.  Machine Agent NOT started.  Please set EAINUMBER and restart."
		echo "EAINUMBER is unset.  Machine Agent NOT started.  Please set EAINUMBER and restart." >> ${LOGFILE}
		export APPD_ENABLED=NO
fi

# Start the service machine_agent_appd
start() {  #START
STATUS=`ps -ef |grep machineagent.jar |grep -v grep`
#####################################################################################################################
if [ $? -eq 0 ]
then
	echo "*****A current machine agent was running. No start necessary" >> ${LOGFILE}
else
	if [ -z ${APPD_JAVA_HOME+x} ]; then
		echo "APPD_JAVA_HOME is unset.  Machine Agent NOT started.  ***** Please set APPD_JAVA_HOME and restart. *****"
		echo "APPD_JAVA_HOME is unset.  Machine Agent NOT started.  ***** Please set APPD_JAVA_HOME and restart. *****" >> ${LOGFILE}
	else 
		echo "APPD_ENABLED = ${APPD_ENABLED}" >> ${LOGFILE}
		#####################################################################################################################
		if [ ${APPD_ENABLED} = "NO" ]
		then
			echo "Configuration not correct.  Not starting machine agent! Check webservice for entries" >> ${LOGFILE}
		else
			echo "*****Trying to START a machine agent for EAINumber ${EAINUMBER}."
			echo "*****Trying to START a machine agent for EAINumber ${EAINUMBER}." >> $LOGFILE
        		# get info from webservice and store in cached copy. Using curl to grab data and store it in serverconfig.old as the cached copy.  Then
        		# using xmllint to format it so that it will be easier to read if needing to debug.  if curl fails, the serverconfig.old will be there
        		# if curl was successful at any time.
			#####################################################################################################################
			if [ -x /opt/fedex/cloud/bin/cloudenv ]
			then
				echo "I'm a CloudOps machine!"
				echo "running: curl -s -m 30 -o ${APP_LOGDIR}/serverconfig.old http://appdcloudws.prod.cloud.fedex.com:8080/AppDServiceCheck/jaxrs/appdenabled/${EAINUMBER}" >> $LOGFILE
				curl -sf -m 30 -o ${APP_LOGDIR}/serverconfig.old http://appdcloudws.prod.cloud.fedex.com:8080/AppDServiceCheck/jaxrs/appdenabled/${EAINUMBER}
				CURL_RESULT=${?}
			else
				echo "So sad, just a regular VM."
				echo "running: curl -s -m 30 -o ${APP_LOGDIR}/serverconfig.old http://prh00640.sac.fedex.com:8080/AppDServiceCheck/jaxrs/appdenabled/${EAINUMBER}" >> $LOGFILE
				curl -sf -m 30 -o ${APP_LOGDIR}/serverconfig.old http://prh00640.sac.fedex.com:8080/AppDServiceCheck/jaxrs/appdenabled/${EAINUMBER}
				CURL_RESULT=${?}
			fi

			#####################################################################################################################	
			# check if curl failed and if so, log it.
			if [ ${CURL_RESULT} -ne 0 ]
			then
				echo "curl failed. Using cached copy. Curl ERROR is: ${CURL_RESULT}" >> ${LOGFILE}
			fi 

			#####################################################################################################################	
			# Format the xml to make it human readable, leaving serverconfig.old as it is to be a backup if curl doesnt work.
			if [[ -e ${APP_LOGDIR}/serverconfig.old ]]
			then
				xmllint --format ${APP_LOGDIR}/serverconfig.old > ${APP_LOGDIR}/serverconfig.xml
			else
				echo "xmllint format: ${APP_LOGDIR}/serverconfig.old not found." >> $LOGFILE
				echo "Application may not be enabled for AppD.  Please open an RT in the APM queue." >> $LOGFILE
			fi

			#####################################################################################################################	
			# Parse values from serverconfig.xml file 
			if [[ -e ${APP_LOGDIR}/serverconfig.xml ]]
			then
				export EAINAME=`xmllint --shell ${APP_LOGDIR}/serverconfig.xml <<<"cat /appdServerInfoes/appdServerInfo[eaiNumber='${EAINUMBER}'][serverName='${HOSTNAME}']/eaiName/text()" |grep -v "\/"|uniq|awk 'NR==1'`
				export CONTROLLER=`xmllint --shell ${APP_LOGDIR}/serverconfig.xml <<<"cat /appdServerInfoes/appdServerInfo[eaiNumber='${EAINUMBER}'][serverName='${HOSTNAME}']/controller/text()" |grep -v "\/"|uniq|awk 'NR==1'`
				export APPLICATION=`xmllint --shell ${APP_LOGDIR}/serverconfig.xml <<<"cat /appdServerInfoes/appdServerInfo[eaiNumber='${EAINUMBER}'][serverName='${HOSTNAME}']/application/text()" |grep -v "\/"|uniq|awk 'NR==1'`
				export LOADLEVEL=`xmllint --shell ${APP_LOGDIR}/serverconfig.xml <<<"cat /appdServerInfoes/appdServerInfo[eaiNumber='${EAINUMBER}'][serverName='${HOSTNAME}']/loadLevel/text()" |grep -v "\/"|uniq|awk 'NR==1'`
				export PROXYHOST=`xmllint --shell ${APP_LOGDIR}/serverconfig.xml <<<"cat /appdServerInfoes/appdServerInfo[eaiNumber='${EAINUMBER}'][serverName='${HOSTNAME}']/proxyHost/text()" |grep -v "\/"|uniq|awk 'NR==1'` 
				export PROXYPORT=`xmllint --shell ${APP_LOGDIR}/serverconfig.xml <<<"cat /appdServerInfoes/appdServerInfo[eaiNumber='${EAINUMBER}'][serverName='${HOSTNAME}']/proxyPort/text()" |grep -v "\/"|uniq|awk 'NR==1'` 
				export CONTROLLER_PORT=`xmllint --shell ${APP_LOGDIR}/serverconfig.xml <<<"cat /appdServerInfoes/appdServerInfo[eaiNumber='${EAINUMBER}'][serverName='${HOSTNAME}']/controllerPort/text()" |grep -v "\/"|uniq|awk 'NR==1'` 
				export ACCOUNT_NAME=`xmllint --shell ${APP_LOGDIR}/serverconfig.xml <<<"cat /appdServerInfoes/appdServerInfo[eaiNumber='${EAINUMBER}'][serverName='${HOSTNAME}']/accountName/text()" |grep -v "\/"|uniq|awk 'NR==1'` 
				export ACCOUNT_ACCESS_KEY=`xmllint --shell ${APP_LOGDIR}/serverconfig.xml <<<"cat /appdServerInfoes/appdServerInfo[eaiNumber='${EAINUMBER}'][serverName='${HOSTNAME}']/accountAccessKey/text()" |grep -v "\/"|uniq|awk 'NR==1'` 
				export MAX_METRICS=`xmllint --shell ${APP_LOGDIR}/serverconfig.xml <<<"cat /appdServerInfoes/appdServerInfo[eaiNumber='${EAINUMBER}'][serverName='${HOSTNAME}']/variable0/text()" |grep -v "\/"|uniq|awk 'NR==1'` 
				export SIM_FLAG=`xmllint --shell ${APP_LOGDIR}/serverconfig.xml <<<"cat /appdServerInfoes/appdServerInfo[eaiNumber='${EAINUMBER}'][serverName='${HOSTNAME}']/variable1/text()" |grep -v "\/"|uniq|awk 'NR==1'` 
			else
				echo "PROBLEM READING FILE" >> ${LOGFILE}
			fi


			#####################################################################################################################	
			# if ${SERVER_NAME} is not set by weblogic or if ${WLCA_MANAGED_SERVER_NAME} is not set by JBOSS, this is a standalone app, use ${HOSTNAME} instead
			if [[ -z "${SERVER_NAME}" ]]
			then 
				if [[ -z "${WLCA_MANAGED_SERVER_NAME}" ]] 	
				then
       					APPD_SERVER_NAME=${HOSTNAME}
				else
					APPD_SERVER_NAME=${WLCA_MANAGED_SERVER_NAME}-${HOSTNAME}
				fi
			else
				APPD_SERVER_NAME=${SERVER_NAME}-${HOSTNAME}
			fi

			#####################################################################################################################	
			if [[ ${SIM_FLAG} == "true" ]]
			then
				SIM_FLAG="true"
			else
				SIM_FLAG="false"
			fi

			# Validate that there are values for every variable and log them.  If not, log FIRST offender and bail out.
			for VARIABLE in HOSTNAME EAINUMBER EAINAME CONTROLLER APPLICATION LOADLEVEL PROXYHOST PROXYPORT MAX_METRICS SIM_FLAG
			do
				#####################################################################################################################	
				if [[ -z "${!VARIABLE}" ]]
				then 
					echo "${VARIABLE} is empty! Please open a ticket in the APM queue to have this application enabled" >> $LOGFILE
					export APPD_ENABLED=NO
				else
					echo "${VARIABLE}=	${!VARIABLE}" >> $LOGFILE
				fi
			done

			#####################################################################################################################	
			# Create Application Specific Log Directory if not there in case there are multiple apps on one host
			if [[ -d $LOGDIR/${EAINAME} ]]
			then
				mkdir -p $LOGDIR/${EAINAME}
				echo `date` >> $LOGFILE
			fi

			#####################################################################################################################	
			# if MAX_METRICS is set to anything other than "VAR0", use it.  If it isn't, don't.  
			if [[ ${MAX_METRICS} != "VAR0" ]]
       			then
       				echo "Starting Machine Agent for ${SERVERNAME}: ${APPLICATION} ${EAINAME}-${EAINUMBER}.  See /var/fedex/appd/logs/machine-agent.log for details" >> ${LOGFILE}
       				echo "RUNNING: nohup ${JAVA_CMD} ${MEM_ARGS} -Dappdynamics.http.proxyHost=${PROXYHOST} -Dappdynamics.http.proxyPort=${PROXYPORT} -Dappdynamics.controller.ssl.enabled=${CONTROLLER_SSL_ENABLED} -Dappdynamics.controller.port=${CONTROLLER_PORT} -Dappdynamics.controller.hostName=${CONTROLLER} -Dappdynamics.agent.accountName=${ACCOUNT_NAME} -Dappdynamics.agent.accountAccessKey=${ACCOUNT_ACCESS_KEY} -Dchmod-use-full-permissions=false -Dappdynamics.agent.maxMetrics=${MAX_METRICS} -Dappdynamics.sim.enabled=${SIM_FLAG} -Dappdynamics.machine.agent.extensions.calcVolumeFreeAndUsedWithDfCommand=true -Dappdynamics.agent.runtime.dir=${APP_LOGDIR} -jar /opt/appd/current/machineagent/machineagent.jar >&/dev/null &" >> ${LOGFILE}
       				nohup ${JAVA_CMD} ${MEM_ARGS} -Dappdynamics.http.proxyHost=${PROXYHOST} -Dappdynamics.http.proxyPort=${PROXYPORT} -Dappdynamics.controller.ssl.enabled=${CONTROLLER_SSL_ENABLED} -Dappdynamics.controller.port=${CONTROLLER_PORT} -Dappdynamics.controller.hostName=${CONTROLLER} -Dappdynamics.agent.accountName=${ACCOUNT_NAME} -Dappdynamics.agent.accountAccessKey=${ACCOUNT_ACCESS_KEY} -Dchmod-use-full-permissions=false -Dappdynamics.agent.maxMetrics=${MAX_METRICS} -Dappdynamics.sim.enabled=${SIM_FLAG} -Dappdynamics.machine.agent.extensions.calcVolumeFreeAndUsedWithDfCommand=true -Dappdynamics.agent.runtime.dir=${APP_LOGDIR} -jar /opt/appd/current/machineagent/machineagent.jar >&/dev/null &
			else
       				echo "Starting Machine Agent for ${SERVERNAME}: ${APPLICATION} ${EAINAME}-${EAINUMBER}.  See /var/fedex/appd/logs/machine-agent.log for details" >> ${LOGFILE}
       				echo "RUNNING: nohup ${JAVA_CMD} ${MEM_ARGS} -Dappdynamics.http.proxyHost=${PROXYHOST} -Dappdynamics.http.proxyPort=${PROXYPORT} -Dappdynamics.controller.ssl.enabled=${CONTROLLER_SSL_ENABLED} -Dappdynamics.controller.port=${CONTROLLER_PORT} -Dappdynamics.controller.hostName=${CONTROLLER} -Dappdynamics.agent.accountName=${ACCOUNT_NAME} -Dappdynamics.agent.accountAccessKey=${ACCOUNT_ACCESS_KEY} -Dchmod-use-full-permissions=false -Dappdynamics.sim.enabled=${SIM_FLAG} -Dappdynamics.machine.agent.extensions.calcVolumeFreeAndUsedWithDfCommand=true  -Dappdynamics.agent.runtime.dir=${APP_LOGDIR} -jar /opt/appd/current/machineagent/machineagent.jar >&/dev/null &" >> ${LOGFILE}
       				nohup ${JAVA_CMD} ${MEM_ARGS} -Dappdynamics.http.proxyHost=${PROXYHOST} -Dappdynamics.http.proxyPort=${PROXYPORT} -Dappdynamics.controller.ssl.enabled=${CONTROLLER_SSL_ENABLED} -Dappdynamics.controller.port=${CONTROLLER_PORT} -Dappdynamics.controller.hostName=${CONTROLLER} -Dappdynamics.agent.accountName=${ACCOUNT_NAME} -Dappdynamics.agent.accountAccessKey=${ACCOUNT_ACCESS_KEY} -Dchmod-use-full-permissions=false -Dappdynamics.sim.enabled=${SIM_FLAG} -Dappdynamics.machine.agent.extensions.calcVolumeFreeAndUsedWithDfCommand=true -Dappdynamics.agent.runtime.dir=${APP_LOGDIR} -jar /opt/appd/current/machineagent/machineagent.jar >&/dev/null &
			fi
		fi # if [ ${APPD_ENABLED} = "NO" ]
	fi # if [ -z ${APPD_JAVA_HOME+x} ]; then
fi # if [ $? -eq 0 ]
} # START

# Stop the service machine_agent_appd
stop() {
	#####################################################################################################################	
	STATUS=`ps -ef |grep machineagent.jar |grep -v grep`
	if [ $? -eq 0 ]
	then
        	echo "Stopping Machine Agent for EAINUMBER ${EAINUMBER}"
        	echo "#####Stopping Machine Agent for EAINUMBER ${SERVERNAME}" >> $LOGFILE
 		ps -ef |grep machineagent |grep -v grep|awk '{print $2}'|xargs kill -9
		sleep 3
	else
		echo "Machine agent was NOT running. Nothing to kill"
	fi
}
# Check the status of service machine_agent_appd
status() {
	#####################################################################################################################	
	STATUS=`ps -ef |grep machineagent.jar |grep -v grep`
	if [ $? -eq 0 ]
	then
		echo "Machine agent is running"
	else
		echo "Machine agent is NOT running"
	fi
}
### main logic ###

case "$ACTION" in
  start)
        start
	status
        ;;
  stop)
        stop
	status
        ;;
  status)
        status 
        ;;
  restart|reload|condrestart)
        stop
        start
        ;;
  *)
        echo $"Usage: $0 EAINUMBER {start|stop|restart|reload|status}"
        exit
esac
exit 0
