REM
REM Copyright (c) AppDynamics, Inc., and its affiliates, 2014, 2015
REM All Rights Reserved
REM
@echo off

REM A script defining a custom action to occur when the machine-agent fails
REM more than 3 times
REM Edit this script to define custom actions for when the agent is failing
REM frequently

echo Attempting to restart the machine-agent
sc start "AppDynamics Machine Agent"
