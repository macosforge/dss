# Microsoft Developer Studio Project File - Name="StreamingServer" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Console Application" 0x0103

CFG=StreamingServer - Win32 Release
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "StreamingServer.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "StreamingServer.mak" CFG="StreamingServer - Win32 Release"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "StreamingServer - Win32 Debug" (based on "Win32 (x86) Console Application")
!MESSAGE "StreamingServer - Win32 Release" (based on "Win32 (x86) Console Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 1
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "StreamingServer - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /Yu"stdafx.h" /FD /c
# ADD CPP /nologo /MTd /W3 /ZI /Od /I "../" /I "../Server.tproj/" /I "../CommonUtilitiesLib/" /I "../QTFileLib/" /I "../RTPMetaInfoLib/" /I "../PrefsSourceLib/" /I "../APIModules/" /I "../APIStubLib/" /I "../APICommonCode/" /I "../HTTPUtilitiesLib/" /I "../RTCPUtilitiesLib/" /I "../RTSPClientLib/" /I "../APIModules/QTSSFileModule/" /I "../APIModules/QTSSHttpFileModule/" /I "../APIModules/QTSSAccessModule/" /I "../APIModules/QTSSAccessLogModule/" /I "../APIModules/QTSSPosixFileSysModule/" /I "../APIModules/QTSSAdminModule/" /I "../APIModules/QTSSReflectorModule/" /I "../APIModules/QTSSWebStatsModule/" /I "../APIModules/QTSSWebDebugModule/" /I "../APIModules/QTSSFlowControlModule/" /I "../APIModules/QTSSMP3StreamingModule" /FI"../WinNTSupport/Win32header.h" /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /D "DSS_USE_API_CALLBACKS" /FR /FD /c
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /debug /machine:I386 /pdbtype:sept
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib oleaut32.lib ws2_32.lib wsock32.lib winmm.lib /nologo /subsystem:console /debug /machine:I386 /out:"..\WinNTSupport\Debug\DarwinStreamingServer.exe" /pdbtype:sept
# SUBTRACT LINK32 /pdb:none

!ELSEIF  "$(CFG)" == "StreamingServer - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "StreamingServer___Win32_Release1"
# PROP BASE Intermediate_Dir "StreamingServer___Win32_Release1"
# PROP BASE Ignore_Export_Lib 0
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MTd /w /W0 /Gm /ZI /Od /I "../" /I "../Server.tproj/" /I "../CommonUtilitiesLib/" /I "../QTFileLib/" /I "../RTPMetaInfoLib/" /I "../PrefsSourceLib/" /I "../APIModules/" /I "../APIStubLib/" /I "../APICommonCode/" /I "../HTTPUtilitiesLib/" /I "../RTCPUtilitiesLib/" /I "../RTSPClientLib/" /I "../APIModules/QTSSFileModule/" /I "../APIModules/QTSSHttpFileModule/" /I "../APIModules/QTSSAccessModule/" /I "../APIModules/QTSSAccessLogModule/" /I "../APIModules/QTSSPosixFileSysModule/" /I "../APIModules/QTSSAdminModule/" /I "../APIModules/QTSSReflectorModule/" /I "../APIModules/QTSSWebStatsModule/" /I "../APIModules/QTSSWebDebugModule/" /I "../APIModules/QTSSFlowControlModule/" /I "../APIModules/QTSSMP3StreamingModule" /FI"../WinNTSupport/Win32header.h" /D "WIN32" /D "_CONSOLE" /D "_MBCS" /D "DSS_USE_API_CALLBACKS" /FR /FD /c
# ADD CPP /nologo /MT /w /W0 /Z7 /O1 /Ob2 /I "../" /I "../Server.tproj/" /I "../CommonUtilitiesLib/" /I "../QTFileLib/" /I "../RTPMetaInfoLib/" /I "../PrefsSourceLib/" /I "../APIModules/" /I "../APIStubLib/" /I "../APICommonCode/" /I "../HTTPUtilitiesLib/" /I "../RTCPUtilitiesLib/" /I "../RTSPClientLib/" /I "../APIModules/QTSSFileModule/" /I "../APIModules/QTSSHttpFileModule/" /I "../APIModules/QTSSAccessModule/" /I "../APIModules/QTSSAccessLogModule/" /I "../APIModules/QTSSPosixFileSysModule/" /I "../APIModules/QTSSAdminModule/" /I "../APIModules/QTSSReflectorModule/" /I "../APIModules/QTSSWebStatsModule/" /I "../APIModules/QTSSWebDebugModule/" /I "../APIModules/QTSSFlowControlModule/" /I "../APIModules/QTSSMP3StreamingModule" /FI"../WinNTSupport/Win32header.h" /D "WIN32" /D "_CONSOLE" /D "_MBCS" /D "DSS_USE_API_CALLBACKS" /FD /c
# ADD BASE RSC /l 0x409
# ADD RSC /l 0x409
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib oleaut32.lib ws2_32.lib wsock32.lib winmm.lib /nologo /subsystem:console /debug /machine:I386 /nodefaultlib:"libcd.lib" /out:"DarwinStreamingServer.exe" /pdbtype:sept
# SUBTRACT BASE LINK32 /pdb:none /nodefaultlib
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib libcmt.lib odbc32.lib odbccp32.lib oleaut32.lib ws2_32.lib wsock32.lib winmm.lib /nologo /subsystem:console /incremental:yes /machine:I386 /out:"..\WinNTSupport\Release\DarwinStreamingServer.exe" /pdbtype:sept
# SUBTRACT LINK32 /pdb:none /debug

!ENDIF 

# Begin Target

# Name "StreamingServer - Win32 Debug"
# Name "StreamingServer - Win32 Release"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Group "API Modules"

# PROP Default_Filter ""
# Begin Group "QTSSReflectorModule"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\APIModules\QTSSReflectorModule\QTSSReflectorModule.cpp
# End Source File
# Begin Source File

SOURCE=..\APIModules\QTSSReflectorModule\QTSSRelayModule.cpp
# End Source File
# Begin Source File

SOURCE=..\APIModules\QTSSReflectorModule\RCFSourceInfo.cpp
# End Source File
# Begin Source File

SOURCE=..\APIModules\QTSSReflectorModule\ReflectorSession.cpp
# End Source File
# Begin Source File

SOURCE=..\APIModules\QTSSReflectorModule\ReflectorStream.cpp
# End Source File
# Begin Source File

SOURCE=..\APIModules\QTSSReflectorModule\RelayOutput.cpp
# End Source File
# Begin Source File

SOURCE=..\APIModules\QTSSReflectorModule\RelaySDPSourceInfo.cpp
# End Source File
# Begin Source File

SOURCE=..\APIModules\QTSSReflectorModule\RelaySession.cpp
# End Source File
# Begin Source File

SOURCE=..\APIModules\QTSSReflectorModule\RTPSessionOutput.cpp
# End Source File
# Begin Source File

SOURCE=..\APIModules\QTSSReflectorModule\RTSPSourceInfo.cpp
# End Source File
# Begin Source File

SOURCE=..\APIModules\QTSSReflectorModule\SequenceNumberMap.cpp
# End Source File
# End Group
# Begin Group "QTSSMP3StreamingModule"

# PROP Default_Filter ".cpp"
# Begin Source File

SOURCE=..\APIModules\QTSSMP3StreamingModule\QTSSMP3StreamingModule.cpp
# End Source File
# End Group
# Begin Source File

SOURCE=..\APIModules\QTSSAccessModule\AccessChecker.cpp

!IF  "$(CFG)" == "StreamingServer - Win32 Debug"

# ADD CPP /FR

!ELSEIF  "$(CFG)" == "StreamingServer - Win32 Release"

# SUBTRACT CPP /Fr

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\APIModules\QTSSAdminModule\AdminElementNode.cpp

!IF  "$(CFG)" == "StreamingServer - Win32 Debug"

# ADD CPP /FR

!ELSEIF  "$(CFG)" == "StreamingServer - Win32 Release"

# SUBTRACT CPP /Fr

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\APIModules\QTSSAdminModule\AdminQuery.cpp

!IF  "$(CFG)" == "StreamingServer - Win32 Debug"

# ADD CPP /FR

!ELSEIF  "$(CFG)" == "StreamingServer - Win32 Release"

# SUBTRACT CPP /Fr

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\APIModules\QTSSAccessLogModule\QTSSAccessLogModule.cpp

!IF  "$(CFG)" == "StreamingServer - Win32 Debug"

# ADD CPP /FR

!ELSEIF  "$(CFG)" == "StreamingServer - Win32 Release"

# SUBTRACT CPP /Fr

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\APIModules\QTSSAccessModule\QTSSAccessModule.cpp

!IF  "$(CFG)" == "StreamingServer - Win32 Debug"

# ADD CPP /FR
# SUBTRACT CPP /Z<none>

!ELSEIF  "$(CFG)" == "StreamingServer - Win32 Release"

# ADD BASE CPP /ZI /FR
# SUBTRACT CPP /Z<none> /Fr

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\APIModules\QTSSAdminModule\QTSSAdminModule.cpp

!IF  "$(CFG)" == "StreamingServer - Win32 Debug"

# ADD CPP /FR

!ELSEIF  "$(CFG)" == "StreamingServer - Win32 Release"

# SUBTRACT CPP /Fr

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\APIModules\QTSSFileModule\QTSSFileModule.cpp

!IF  "$(CFG)" == "StreamingServer - Win32 Debug"

# ADD CPP /FR

!ELSEIF  "$(CFG)" == "StreamingServer - Win32 Release"

# SUBTRACT CPP /Fr

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\APIModules\QTSSFlowControlModule\QTSSFlowControlModule.cpp

!IF  "$(CFG)" == "StreamingServer - Win32 Debug"

# ADD CPP /FR

!ELSEIF  "$(CFG)" == "StreamingServer - Win32 Release"

# SUBTRACT CPP /Fr

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\APIModules\QTSSPOSIXFileSysModule\QTSSPosixFileSysModule.cpp

!IF  "$(CFG)" == "StreamingServer - Win32 Debug"

# ADD CPP /FR

!ELSEIF  "$(CFG)" == "StreamingServer - Win32 Release"

# SUBTRACT CPP /Fr

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\APIModules\QTSSWebDebugModule\QTSSWebDebugModule.cpp

!IF  "$(CFG)" == "StreamingServer - Win32 Debug"

# ADD CPP /FR

!ELSEIF  "$(CFG)" == "StreamingServer - Win32 Release"

# SUBTRACT CPP /Fr

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\APIModules\QTSSWebStatsModule\QTSSWebStatsModule.cpp

!IF  "$(CFG)" == "StreamingServer - Win32 Debug"

# ADD CPP /FR

!ELSEIF  "$(CFG)" == "StreamingServer - Win32 Release"

# SUBTRACT CPP /Fr

!ENDIF 

# End Source File
# End Group
# Begin Group "Core"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\Server.tproj\GenerateXMLPrefs.cpp
# End Source File
# Begin Source File

SOURCE=..\OSMemoryLib\OSMemory.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\QTSSCallbacks.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\QTSSDataConverter.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\QTSSDictionary.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\QTSSErrorLogModule.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\QTSServer.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\QTSServerInterface.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\QTSServerPrefs.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\QTSSExpirationDate.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\QTSSFile.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\QTSSMessages.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\QTSSModule.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\QTSSPrefs.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\QTSSSocket.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\RTCPTask.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\RTPBandwidthTracker.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\RTPPacketResender.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\RTPSession.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\RTPSessionInterface.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\RTPStream.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\RTSPProtocol.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\RTSPRequest.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\RTSPRequestInterface.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\RTSPRequestStream.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\RTSPResponseStream.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\RTSPSession.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\RTSPSessionInterface.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\RunServer.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\win32main.cpp
# End Source File
# End Group
# Begin Group "RTSPClientLib"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\RTSPClientLib\ClientSocket.cpp
# End Source File
# Begin Source File

SOURCE=..\RTSPClientLib\RTSPClient.cpp
# End Source File
# End Group
# Begin Group "RTCP Utilities"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\RTCPUtilitiesLib\RTCPAckPacket.cpp
# End Source File
# Begin Source File

SOURCE=..\RTCPUtilitiesLib\RTCPAPPPacket.cpp
# End Source File
# Begin Source File

SOURCE=..\RTCPUtilitiesLib\RTCPPacket.cpp
# End Source File
# Begin Source File

SOURCE=..\RTCPUtilitiesLib\RTCPSRPacket.cpp
# End Source File
# End Group
# Begin Source File

SOURCE=..\PrefsSourceLib\FilePrefsSource.cpp
# End Source File
# Begin Source File

SOURCE=..\HTTPUtilitiesLib\HTTPProtocol.cpp
# End Source File
# Begin Source File

SOURCE=..\HTTPUtilitiesLib\HTTPRequest.cpp
# End Source File
# Begin Source File

SOURCE=..\SafeStdLib\InternalStdLib.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\QTSSUserProfile.cpp
# End Source File
# Begin Source File

SOURCE=..\Server.tproj\RTPOverbufferWindow.cpp
# End Source File
# Begin Source File

SOURCE=..\PrefsSourceLib\XMLParser.cpp
# End Source File
# Begin Source File

SOURCE=..\PrefsSourceLib\XMLPrefsParser.cpp
# End Source File
# End Group
# Begin Source File

SOURCE=.\ReadMe.txt

!IF  "$(CFG)" == "StreamingServer - Win32 Debug"

# PROP Intermediate_Dir "c:\Program Files\QuickTime\Darwin Streaming Server\"

!ELSEIF  "$(CFG)" == "StreamingServer - Win32 Release"

# PROP BASE Intermediate_Dir "c:\Program Files\QuickTime\Darwin Streaming Server\"
# PROP Intermediate_Dir "c:\Program Files\QuickTime\Darwin Streaming Server\"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=.\streamingrelay.cfg
# End Source File
# Begin Source File

SOURCE=.\streamingserver.cfg
# End Source File
# End Target
# End Project
