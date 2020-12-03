#!/bin/bash
#######################################################################################################
# appdEnv.sh - script to set the AppDynamics parameters
# This script sets the java -D parameters for the AppDynamics agent. The script is called with EAI 
# Number as an argument.
# Author - Chuck Cianciola - 81845 - chuck.cianciola@fedex.com
# 2013.03.12 Initial creation. Chuck Cianciola
# 2018.11.30 Added RETRANSFORMATION_FLAG, cleaned up "tmp" and "WILY" references and 
#            added logic to use APPD_SERVER_NAME if set.
#######################################################################################################

export HOSTNAME=`hostname`	# this will be passed to webservice to match serverName from serverconfig.csv
export EAINUMBER=${1}		# this will be passed to webservice to match eaiNumber from serverconfig.csv
export LOGDIR=/var/fedex/appd/logs
export APPD_SERVER_NAME=${APPD_SERVER_NAME:-${SERVER_NAME}} #Use APPD_SERVER_NAME if set, otherwise use SERVER_NAME
export APP_LOGDIR=${LOGDIR}/${EAINUMBER}/${APPD_SERVER_NAME}
export CONTROLLER_SSL_ENABLED=true
export APPD_ENABLED=YES
export JAVA_CMD=${JAVA_HOME}/bin/java
export APPD_XBOOT_CLASSPATH="-javaagent:/opt/appd/current/appagent/javaagent.jar"  
export STANDALONE=false #set to let machine agent know if it is started by this script (false) or standalone(true)




#######################################################################################################################
if [[ -z "${APPD_SERVER_NAME}" ]]
	then
		LOGFILE=${LOGDIR}/appd_startup.log
	else
		LOGFILE=${LOGDIR}/${APPD_SERVER_NAME}_appd_startup.log
fi

# Restart machine agent EVERY time.  Minimal downtime but it ensures that the JAVA agent and the machine agent are
# always running the same version and keeps the users from having to stop manually and restart the app to pick up
# any changes or versions by the machine agent.
echo "************************">> $LOGFILE
echo "RESTARTING Machine agent with command: /opt/appd/current/scripts/machine_agent_appd.sh ${EAINUMBER} restart" >> $LOGFILE
echo "************************">> $LOGFILE
/opt/appd/current/scripts/machine_agent_appd.sh ${EAINUMBER} restart

echo "#######################################################################################################################" >> $LOGFILE
echo "#######################################################################################################################" >> $LOGFILE
echo "APPD_SERVER_NAME = $APPD_SERVER_NAME" >> $LOGFILE
echo "SERVER_NAME = $SERVER_NAME" >> $LOGFILE

#######################################################################################################################
# Create Log file if not there
if [[ ! -d $APP_LOGDIR ]]
then
	mkdir -p $APP_LOGDIR
	echo "#########################################################################################################" >> $LOGFILE
	echo `date` >> $LOGFILE
else
	echo "#########################################################################################################" >> $LOGFILE
	echo `date` >> $LOGFILE
fi

#######################################################################################################################
# Check AppDynamics installation and quit if not installed.
if [[ ! -e /opt/appd/current/appagent/javaagent.jar ]]
then
        echo "AppDynamics NOT installed.  Please open a ticket in the APM queue." >> $LOGFILE
	export APPD_ENABLED=NO
  	exit # bail out if EAINUMBER is not passed in
fi

#######################################################################################################################
# Check for cmd line arg.  If not there, show usage.
if [ ! $# == 1 ]; then
  echo "Usage: $0 EAINUMBER"
  echo "For example: $0 5125"
  echo "Invalid # of cmdline args given" >> $LOGFILE
  export APPD_ENABLED=NO
  exit # bail out if EAINUMBER is not passed in
fi

SERVER_CONFIG_DIR=${LOGDIR}/${EAINUMBER}

#######################################################################################################################
# Make sure that HOSTNAME and EAINUMBER are set. If not, log it and bail out.
for ARG in HOSTNAME EAINUMBER
do
	if [[ -z "$ARG" ]]
	then
        	echo "$ARG is empty! Please open a ticket in the APM queue to have this application enabled" >> $LOGFILE
		export APPD_ENABLED=NO
		exit # bail out if EAINUMBER and HOSTNAME are empty
	fi
done

#######################################################################################################################
# Go get a serverconfig file if there is not one there.  Should be one present from the machine agent script above.
if [[ -e ${SERVER_CONFIG_DIR}/serverconfig.xml ]]
then
	echo "${SERVER_CONFIG_DIR}/serverconfig.xml exists from machine_ agent_appd.sh.  No need to re-run curl"  >> $LOGFILE
else
	##############################################################################################################################
	echo "${APP_LOGDIR}/serverconfig.xml DOES NOT EXIST. Hitting webservice to get -D parameters" >> $LOGFILE
	# get info from webservice and store in cached copy. Using curl to grab data and store it in serverconfig.old as the cached copy.  Then
	# using xmllint to format it so that it will be easier to read if needing to debug.  if curl fails, the serverconfig.old will be there
	# if curl was successful at any time.
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

	##############################################################################################################################
	# check if curl failed and if so, log it.
	if [ ${CURL_RESULT} -ne 0 ]
	then
		echo "curl failed. Using cached copy. Curl ERROR is: ${CURL_RESULT}" >> ${LOGFILE}
	fi

	##############################################################################################################################
	# Format the xml to make it human readable, leaving serverconfig.old as it is to be a backup if curl doesnt work.
	if [[ -e ${APP_LOGDIR}/serverconfig.old ]]
	then
		xmllint --format ${APP_LOGDIR}/serverconfig.old > ${SERVER_CONFIG_DIR}/serverconfig.xml
	else
		echo "xmllint format: ${APP_LOGDIR}/serverconfig.old not found." >> $LOGFILE
		echo "Application may not be enabled for AppD.  Please open an RT in the APM queue." >> $LOGFILE
	fi
fi


	##############################################################################################################################
	# Parse values from serverconfig.xml file 
	if [[ -e ${SERVER_CONFIG_DIR}/serverconfig.xml ]]
	then
		export EAINAME=`xmllint --shell ${SERVER_CONFIG_DIR}/serverconfig.xml <<<"cat /appdServerInfoes/appdServerInfo[eaiNumber='${EAINUMBER}'][serverName='${HOSTNAME}']/eaiName/text()" |grep -v "\/"|uniq|awk 'NR==1'`
	#####	echo "EAINAME = ${EAINAME}" >> ${LOGFILE}
		export CONTROLLER=`xmllint --shell ${SERVER_CONFIG_DIR}/serverconfig.xml <<<"cat /appdServerInfoes/appdServerInfo[eaiNumber='${EAINUMBER}'][serverName='${HOSTNAME}']/controller/text()" |grep -v "\/"|uniq|awk 'NR==1'`
	#####	echo "CONTROLLER = ${CONTROLLER}" >> ${LOGFILE}
		export APPLICATION=`xmllint --shell ${SERVER_CONFIG_DIR}/serverconfig.xml <<<"cat /appdServerInfoes/appdServerInfo[eaiNumber='${EAINUMBER}'][serverName='${HOSTNAME}']/application/text()" |grep -v "\/"|uniq|awk 'NR==1'`
	#####	echo "APPLICATION = ${APPLICATION}" >> ${LOGFILE}
		export LOADLEVEL=`xmllint --shell ${SERVER_CONFIG_DIR}/serverconfig.xml <<<"cat /appdServerInfoes/appdServerInfo[eaiNumber='${EAINUMBER}'][serverName='${HOSTNAME}']/loadLevel/text()" |grep -v "\/"|uniq|awk 'NR==1'`
	#####	echo "LOADLEVEL = ${LOADLEVEL}" >> ${LOGFILE}
		export PROXYHOST=`xmllint --shell ${SERVER_CONFIG_DIR}/serverconfig.xml <<<"cat /appdServerInfoes/appdServerInfo[eaiNumber='${EAINUMBER}'][serverName='${HOSTNAME}']/proxyHost/text()" |grep -v "\/"|uniq|awk 'NR==1'` 
	#####	echo "PROXYHOST = ${PROXYHOST}" >> ${LOGFILE}
		export PROXYPORT=`xmllint --shell ${SERVER_CONFIG_DIR}/serverconfig.xml <<<"cat /appdServerInfoes/appdServerInfo[eaiNumber='${EAINUMBER}'][serverName='${HOSTNAME}']/proxyPort/text()" |grep -v "\/"|uniq|awk 'NR==1'` 
	#####	echo "PROXYPORT = ${PROXYPORT}" >> ${LOGFILE}
		export CONTROLLER_PORT=`xmllint --shell ${SERVER_CONFIG_DIR}/serverconfig.xml <<<"cat /appdServerInfoes/appdServerInfo[eaiNumber='${EAINUMBER}'][serverName='${HOSTNAME}']/controllerPort/text()" |grep -v "\/"|uniq|awk 'NR==1'` 
	#####	echo "CONTROLLER_PORT = ${CONTROLLER_PORT}" >> ${LOGFILE}
		export ACCOUNT_NAME=`xmllint --shell ${SERVER_CONFIG_DIR}/serverconfig.xml <<<"cat /appdServerInfoes/appdServerInfo[eaiNumber='${EAINUMBER}'][serverName='${HOSTNAME}']/accountName/text()" |grep -v "\/"|uniq|awk 'NR==1'` 
	#####	echo "ACCOUNT_NAME = ${ACCOUNT_NAME}" >> ${LOGFILE}
		export ACCOUNT_ACCESS_KEY=`xmllint --shell ${SERVER_CONFIG_DIR}/serverconfig.xml <<<"cat /appdServerInfoes/appdServerInfo[eaiNumber='${EAINUMBER}'][serverName='${HOSTNAME}']/accountAccessKey/text()" |grep -v "\/"|uniq|awk 'NR==1'` 
	#####	echo "ACCOUNT_ACCESS_KEY = ${ACCOUNT_ACCESS_KEY}" >> ${LOGFILE}
##### The MAX_METRICS variable is set to whatever VAR0 is in the serverconfig.xml file if it is anything other than "VAR0"
		export MAX_METRICS=`xmllint --shell ${SERVER_CONFIG_DIR}/serverconfig.xml <<<"cat /appdServerInfoes/appdServerInfo[eaiNumber='${EAINUMBER}'][serverName='${HOSTNAME}']/variable0/text()" |grep -v "\/"|uniq|awk 'NR==1'` 
	#####	echo "MAX_METRICS = ${MAX_METRICS}" >> ${LOGFILE}
##### The SIM_FLAG variable is set to whatever VAR1 is in the serverconfig.xml file. Set to true if "true", false if anything else.
		export SIM_FLAG=`xmllint --shell ${SERVER_CONFIG_DIR}/serverconfig.xml <<<"cat /appdServerInfoes/appdServerInfo[eaiNumber='${EAINUMBER}'][serverName='${HOSTNAME}']/variable1/text()" |grep -v "\/"|uniq|awk 'NR==1'` 
	#####	echo "SIM_FLAG = ${SIM_FLAG}" >> ${LOGFILE}
##### The RETRANSFORMATION_FLAG variable is set to whatever VAR2 is in the serverconfig.xml file. Set to true if "true", false if anything else.
		export RETRANSFORMATION_FLAG=`xmllint --shell ${SERVER_CONFIG_DIR}/serverconfig.xml <<<"cat /appdServerInfoes/appdServerInfo[eaiNumber='${EAINUMBER}'][serverName='${HOSTNAME}']/variable2/text()" |grep -v "\/"|uniq|awk 'NR==1'` 
	#####	echo "RETRANSFORMATION_FLAG = ${RETRANSFORMATION_FLAG}" >> ${LOGFILE}
	else
		echo "PROBLEM READING FILE" >> ${LOGFILE}
	fi

	###################################################################################################################################################
	# if ${RETRANSFORMATION_FLAG} is true, reset it.  if not, set to false
                        if [[ ${RETRANSFORMATION_FLAG} == "true" ]]
                        then
                                RETRANSFORMATION_FLAG="true"
                        else
                                RETRANSFORMATION_FLAG="false"
                        fi


	###################################################################################################################################################
	# if ${APPD_SERVER_NAME} is not set by weblogic or if ${WLCA_MANAGED_SERVER_NAME} is not set by JBOSS, this is a standalone app, use ${HOSTNAME} instead
	if [[ -z "${APPD_SERVER_NAME}" ]]
	then 
		if [[ -z "${WLCA_MANAGED_SERVER_NAME}" ]] 	
		then
       			APPD_SERVER_NAME=${HOSTNAME}
		else
			APPD_SERVER_NAME=${WLCA_MANAGED_SERVER_NAME}-${HOSTNAME}
		fi
	else
		APPD_SERVER_NAME=${APPD_SERVER_NAME}-${HOSTNAME}
	fi

	####################################################################################################################
	# Validate that there are values for every variable and log them.  If not, log FIRST offender and bail out.
	for VARIABLE in HOSTNAME EAINUMBER EAINAME CONTROLLER APPLICATION LOADLEVEL PROXYHOST PROXYPORT MAX_METRICS SIM_FLAG RETRANSFORMATION_FLAG APPD_SERVER_NAME
	do
		if [[ -z "${!VARIABLE}" ]]
		then 
			echo "${VARIABLE} is empty! Please open a ticket in the APM queue to have this application enabled" >> $LOGFILE
			export APPD_ENABLED=NO
		else
			echo "${VARIABLE}=	${!VARIABLE}" >> $LOGFILE
		fi
	done

	####################################################################################################
	# Create Application Specific Log Directory if not there in case there are multiple apps on one host
	if [[ -d $LOGDIR/${EAINAME} ]]
	then
		mkdir -p $LOGDIR/${EAINAME}
		echo `date` >> $LOGFILE
	fi



	#########################################################################################################################################
	if [ $APPD_ENABLED = "NO" ]
	then
		echo "AppDynamics NOT enabled.  Please open a ticket in the APM queue to have this application enabled or configured" >> $LOGFILE
	else
		if [ ${RETRANSFORMATION_FLAG} = "true" ]
		then
			# Set the JAVA_OPTIONS used to start AppD and export, appending to existing JAVA_OPTIONS
			export APPD_JAVA_OPTIONS="-Dappdynamics.http.proxyHost=${PROXYHOST} -Dappdynamics.http.proxyPort=${PROXYPORT} -Dappdynamics.agent.applicationName=${APPLICATION} -Dappdynamics.agent.tierName=${EAINAME}-${EAINUMBER} -Dappdynamics.agent.nodeName=${APPD_SERVER_NAME} -Dappdynamics.controller.ssl.enabled=${CONTROLLER_SSL_ENABLED} -Dappdynamics.controller.sslPort=${CONTROLLER_PORT} -Dappdynamics.agent.logs.dir=${APP_LOGDIR} -Dappdynamics.agent.runtime.dir=${LOGDIR} -Dappdynamics.controller.hostName=${CONTROLLER} -Dappdynamics.controller.port=${CONTROLLER_PORT} -Dappdynamics.agent.accountName=${ACCOUNT_NAME} -Dappdynamics.agent.accountAccessKey=${ACCOUNT_ACCESS_KEY} -Dappdynamics.agent.disable.retransformation=true"
			export JAVA_OPTIONS="${JAVA_OPTIONS} ${APPD_XBOOT_CLASSPATH} ${APPD_JAVA_OPTIONS}"
			export JAVA_OPTS="${JAVA_OPTS} ${APPD_XBOOT_CLASSPATH} ${APPD_JAVA_OPTIONS}"
		else
			# Set the JAVA_OPTIONS used to start AppD and export, appending to existing JAVA_OPTIONS
			export APPD_JAVA_OPTIONS="-Dappdynamics.http.proxyHost=${PROXYHOST} -Dappdynamics.http.proxyPort=${PROXYPORT} -Dappdynamics.agent.applicationName=${APPLICATION} -Dappdynamics.agent.tierName=${EAINAME}-${EAINUMBER} -Dappdynamics.agent.nodeName=${APPD_SERVER_NAME} -Dappdynamics.controller.ssl.enabled=${CONTROLLER_SSL_ENABLED} -Dappdynamics.controller.sslPort=${CONTROLLER_PORT} -Dappdynamics.agent.logs.dir=${APP_LOGDIR} -Dappdynamics.agent.runtime.dir=${LOGDIR} -Dappdynamics.controller.hostName=${CONTROLLER} -Dappdynamics.controller.port=${CONTROLLER_PORT} -Dappdynamics.agent.accountName=${ACCOUNT_NAME} -Dappdynamics.agent.accountAccessKey=${ACCOUNT_ACCESS_KEY} "
			export JAVA_OPTIONS="${JAVA_OPTIONS} ${APPD_XBOOT_CLASSPATH} ${APPD_JAVA_OPTIONS}"
			export JAVA_OPTS="${JAVA_OPTS} ${APPD_XBOOT_CLASSPATH} ${APPD_JAVA_OPTIONS}"
		fi
	fi
echo "###################################" >> $LOGFILE
echo "JAVA_OPTIONS=${JAVA_OPTIONS}" >> $LOGFILE
echo "JAVA_OPTIONS=${JAVA_OPTIONS}"
echo "JAVA_OPTS=${JAVA_OPTS}" >> $LOGFILE
echo "JAVA_OPTS=${JAVA_OPTS}"

