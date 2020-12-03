'
' Copyright (c) AppDynamics, Inc., and its affiliates, 2014, 2015
' All Rights Reserved
'

' Require explicitly declaring variables
Option Explicit

' quote character
Const QUOTE = """"

Sub forceCScriptExecution
    Dim Arg, Str
    If Not LCase( Right( WScript.FullName, 12 ) ) = "\cscript.exe" Then
        For Each Arg In WScript.Arguments
            If InStr( Arg, " " ) Then Arg = QUOTE & Arg & QUOTE
            Str = Str & " " & Arg
        Next
        CreateObject( "WScript.Shell" ).Run _
            "cscript //nologo " & _
            QUOTE & WScript.ScriptFullName & QUOTE & _
            " " & Str
        WScript.Quit
    End If
End Sub
forceCScriptExecution

Dim fsObject, shell
Set fsObject = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

Dim scriptDir
scriptDir = fsObject.GetParentFolderName(WScript.ScriptFullName)

' Parses arguments to this script. For example -h -j JAVA_HOME -Dprop1 will be put in a map
' {"h": "", "j", "JAVA_HOME", "-Dprop1": "" }
' Returns a map representing the arguments passed to this script
Function parseCommandLineArgs()
    Dim argumentsMap
    Set argumentsMap = CreateObject("Scripting.Dictionary")
    Dim argPos
    For argPos = 0 to WScript.Arguments.Count - 1
        Dim key, val
        key = WScript.Arguments.Item(argPos)
        val = ""
        If key = "-j" Then
            argPos = argPos + 1
            val = WScript.Arguments.Item(argPos)
        End If
        argumentsMap.Add key, val
    Next
    set parseCommandLineArgs = argumentsMap
End Function

'Prints the usage of this script
Function usage()
    Dim usageText
    usageText = _
            "Usage: " & WScript.ScriptName & "[-h] [-j JAVA_HOME][-Dprop1 ...] [-Xprop2 ...]" & vbCrLf & _
            "Start the machine agent." & vbCrLf & _
            "    -h              print command line options" & vbCrLf & _
            "    -j JAVA_HOME    set java home for the agent" & vbCrLf & _
            "    -Dprop1         set standard system properties for the agent" & vbCrLf & _
            "    -Xprop2         set non-standard system properties for the agent"
    WScript.Echo usageText
End Function

Function getPathJava()
    Dim pathJavaHome, shellExec
    set shellExec = shell.exec("where java.exe")
    Do Until shellExec.Status
        WScript.Sleep 100
    Loop
    If shellExec.ExitCode = 0 Then
        pathJavaHome = shellExec.StdOut.ReadLine()
    End If
    getPathJava = pathJavaHome
End Function

Dim machineAgentHome
machineAgentHome = fsObject.GetParentFolderName(scriptDir)

Dim machineAgentJava, javaHomeJava, pathJava
machineAgentJava = machineAgentHome + "\jre\bin\java.exe"
javaHomeJava = shell.ExpandEnvironmentStrings("%JAVA_HOME%") + "\bin\java.exe"
pathJava = getPathJava()

Dim arguments, java, errMsg
Set arguments = parseCommandLineArgs()
If arguments.Exists("-h") Then
    usage()
    WScript.Quit
End If
If arguments.Exists("-j") Then
    java = arguments.Item("-j") + "\bin\java.exe"
    If Not fsObject.FileExists(java) Then
        errMsg = _
                "Configured Java installation " & java & "does not contain a valid JRE." & vbCrLf & _
                "Please configure a valid JRE installation with version 1.8 or above or" & vbCrLf & _
                "use a machine agent package with a bundled JRE"
        WScript.Echo errMsg
        WScript.Quit
    End If
ElseIf fsObject.FileExists(machineAgentJava) Then
    java = machineAgentJava
    WScript.Echo "Using bundled JRE at - " & java
ElseIf fsObject.FileExists(javaHomeJava) Then
    java = javaHomeJava
    WScript.Echo "Using JRE from JAVA_HOME environment variable - " & java
ElseIf fsObject.FileExists(pathJava) Then
    java = pathJava
    WScript.Echo "Using JRE from PATH environment variable - " & java
Else
    errMsg = _
            "Could not find a valid java installation. Please use a machine agent with" & vbCrLf & _
            "a bundled JRE or install a JRE with a version greater than or equal to 1.8" & vbCrLf & _
            "on your machine"
    WScript.Echo errMsg
    WScript.Quit
End If

'Quote enclose java incase it has spaces in it
java = QUOTE & java & QUOTE

Dim log4jConfig, stdProps, nonStdProps
log4jConfig = QUOTE & "-Dlog4.configuration=file:" & machineAgentHome & "\conf\logging\log4j.xml" & QUOTE
stdProps = ""
nonStdProps = ""

Dim arg
For Each arg In arguments
    If Left(arg, 2) = "-D" Then
        stdProps = stdProps & arg & " "
    ElseIf Left(arg, 2) = "-X" Then
        nonStdProps = nonStdProps & arg & " "
    End If
Next

' Disable minidump on crash if it's supported by the JRE. To enable change to -XX:+CreateMinidumpOnCrash
Dim mdmpOpts
mdmpOpts = "-XX:-CreateMinidumpOnCrash"
' If the option is not supported this command will fail so the machine agent
' will be started without this option
Dim shellExec
set shellExec = shell.exec(java & " " & mdmpOpts & " -version")
Do Until shellExec.Status
    WScript.Sleep 100
Loop
If shellExec.ExitCode <> 0 Then
    WScript.Echo "Disabling minidump not supported by java"
    mdmpOpts = ""
End If

Dim javaOpts
javaOpts = shell.ExpandEnvironmentStrings("%JAVA_OPTS%")
If javaOpts = "%JAVA_OPTS%" Then
    javaOpts = ""
End If
WScript.Echo "Starting AppDynamics Machine Agent"
Dim machineAgentCommand
machineAgentCommand = java & " " & _
        javaOpts & " " & _
        log4jConfig & " " & _
        mdmpOpts & " " & _
        stdProps & " " & nonStdProps & " " & _
        "-jar " & QUOTE & machineAgentHome & "\machineagent.jar" & QUOTE
Dim exitCode
shell.Run machineAgentCommand, 1, True
WScript.Echo "Machine Agent has stopped."
