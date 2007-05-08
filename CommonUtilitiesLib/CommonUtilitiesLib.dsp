# Microsoft Developer Studio Project File - Name="CommonUtilitiesLib" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Static Library" 0x0104

CFG=CommonUtilitiesLib - Win32 Release
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "CommonUtilitiesLib.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "CommonUtilitiesLib.mak" CFG="CommonUtilitiesLib - Win32 Release"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "CommonUtilitiesLib - Win32 Debug" (based on "Win32 (x86) Static Library")
!MESSAGE "CommonUtilitiesLib - Win32 Release" (based on "Win32 (x86) Static Library")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "CommonUtilitiesLib - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_MBCS" /D "_LIB" /YX /FD /GZ /c
# ADD CPP /nologo /MTd /W3 /ZI /Od /I "../" /I "../WinNTSupport/" /I ".." /FI"../WinNTSupport/Win32header.h" /D "WIN32" /D "_DEBUG" /D "_MBCS" /D "_LIB" /FR /FD /c
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LIB32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo /out:"CommonUtilitiesLib.lib"

!ELSEIF  "$(CFG)" == "CommonUtilitiesLib - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "CommonUtilitiesLib___Win32_Release"
# PROP BASE Intermediate_Dir "CommonUtilitiesLib___Win32_Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /w /W0 /Gm /ZI /Od /I "../" /I "../WinNTSupport/" /I ".." /FI"../WinNTSupport/Win32header.h" /D "WIN32" /D "_MBCS" /D "_LIB" /FR /FD /GZ /c
# SUBTRACT BASE CPP /YX /Yc /Yu
# ADD CPP /nologo /MT /w /W0 /Z7 /Ob2 /I "../" /I "../WinNTSupport/" /I ".." /FI"../WinNTSupport/Win32header.h" /D "WIN32" /D "_MBCS" /D "_LIB" /FD /c
# SUBTRACT CPP /Gy
# ADD BASE RSC /l 0x409
# ADD RSC /l 0x409
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LIB32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo

!ENDIF 

# Begin Target

# Name "CommonUtilitiesLib - Win32 Debug"
# Name "CommonUtilitiesLib - Win32 Release"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=.\atomic.cpp
# End Source File
# Begin Source File

SOURCE=.\base64.c
# End Source File
# Begin Source File

SOURCE=.\ConfParser.cpp
# End Source File
# Begin Source File

SOURCE=.\DateTranslator.cpp
# End Source File
# Begin Source File

SOURCE=.\EventContext.cpp
# End Source File
# Begin Source File

SOURCE=.\getopt.c
# End Source File
# Begin Source File

SOURCE=.\GetWord.c
# End Source File
# Begin Source File

SOURCE=.\IdleTask.cpp
# End Source File
# Begin Source File

SOURCE=.\md5.c
# End Source File
# Begin Source File

SOURCE=.\md5digest.cpp
# End Source File
# Begin Source File

SOURCE=.\MyAssert.cpp
# End Source File
# Begin Source File

SOURCE=.\OS.cpp
# End Source File
# Begin Source File

SOURCE=.\OSBufferPool.cpp
# End Source File
# Begin Source File

SOURCE=.\OSCodeFragment.cpp
# End Source File
# Begin Source File

SOURCE=.\OSCond.cpp
# End Source File
# Begin Source File

SOURCE=.\OSFileSource.cpp
# End Source File
# Begin Source File

SOURCE=.\OSHeap.cpp
# End Source File
# Begin Source File

SOURCE=.\OSMutex.cpp
# End Source File
# Begin Source File

SOURCE=.\OSMutexRW.cpp
# End Source File
# Begin Source File

SOURCE=.\OSQueue.cpp
# End Source File
# Begin Source File

SOURCE=.\OSRef.cpp
# End Source File
# Begin Source File

SOURCE=.\OSThread.cpp
# End Source File
# Begin Source File

SOURCE=.\ResizeableStringFormatter.cpp
# End Source File
# Begin Source File

SOURCE=.\SDPUtils.cpp
# End Source File
# Begin Source File

SOURCE=.\Socket.cpp
# End Source File
# Begin Source File

SOURCE=.\SocketUtils.cpp
# End Source File
# Begin Source File

SOURCE=.\StringFormatter.cpp
# End Source File
# Begin Source File

SOURCE=.\StringParser.cpp
# End Source File
# Begin Source File

SOURCE=.\StringTranslator.cpp
# End Source File
# Begin Source File

SOURCE=.\StrPtrLen.cpp
# End Source File
# Begin Source File

SOURCE=.\Task.cpp
# End Source File
# Begin Source File

SOURCE=.\TCPListenerSocket.cpp
# End Source File
# Begin Source File

SOURCE=.\TCPSocket.cpp
# End Source File
# Begin Source File

SOURCE=.\TimeoutTask.cpp
# End Source File
# Begin Source File

SOURCE=.\Trim.c
# End Source File
# Begin Source File

SOURCE=.\UDPDemuxer.cpp
# End Source File
# Begin Source File

SOURCE=.\UDPSocket.cpp
# End Source File
# Begin Source File

SOURCE=.\UDPSocketPool.cpp
# End Source File
# Begin Source File

SOURCE=.\UserAgentParser.cpp
# End Source File
# Begin Source File

SOURCE=.\win32ev.cpp
# End Source File
# End Group
# End Target
# End Project
