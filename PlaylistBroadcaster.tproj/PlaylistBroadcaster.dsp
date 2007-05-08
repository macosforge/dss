# Microsoft Developer Studio Project File - Name="PlaylistBroadcaster" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Console Application" 0x0103

CFG=PlaylistBroadcaster - Win32 Release
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "PlaylistBroadcaster.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "PlaylistBroadcaster.mak" CFG="PlaylistBroadcaster - Win32 Release"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "PlaylistBroadcaster - Win32 Debug" (based on "Win32 (x86) Console Application")
!MESSAGE "PlaylistBroadcaster - Win32 Release" (based on "Win32 (x86) Console Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 1
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "PlaylistBroadcaster - Win32 Debug"

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
# ADD BASE CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /Yu"stdafx.h" /FD /GZ /c
# ADD CPP /nologo /MTd /W3 /Gm /ZI /Od /I "../" /I "../CommonUtilitiesLib/" /I "../QTFileLib/" /I "../RTPMetaInfoLib/" /I "../RTSPClientLib/" /I "../APIModules/" /I "../APIStubLib/" /I "../APICommonCode/" /I "../RTCPUtilitiesLib/" /FI"../WinNTSupport/Win32header.h" /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /FR /FD /I /GZ /c
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /debug /machine:I386 /pdbtype:sept
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib oleaut32.lib ws2_32.lib wsock32.lib winmm.lib libcmtd.lib /nologo /subsystem:console /machine:I386 /nodefaultlib:"libcd.lib" /out:"..\WinNTSupport\Debug\PlaylistBroadcaster.exe" /pdbtype:sept
# SUBTRACT LINK32 /incremental:no /debug

!ELSEIF  "$(CFG)" == "PlaylistBroadcaster - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "PlaylistBroadcaster___Win32_Release"
# PROP BASE Intermediate_Dir "PlaylistBroadcaster___Win32_Release"
# PROP BASE Ignore_Export_Lib 0
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MTd /W3 /Gm /ZI /Od /I "../" /I "../CommonUtilitiesLib/" /I "../QTFileLib/" /I "../RTPMetaInfoLib/" /I "../RTSPClientLib/" /I "../APIModules/" /I "../APIStubLib/" /I "../APICommonCode/" /I "../RTCPUtilitiesLib/" /FI"../WinNTSupport/Win32header.h" /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /FR /FD /I /GZ /c
# ADD CPP /nologo /MT /w /W0 /Gf /I "../" /I "../CommonUtilitiesLib/" /I "../QTFileLib/" /I "../RTPMetaInfoLib/" /I "../RTSPClientLib/" /I "../APIModules/" /I "../APIStubLib/" /I "../APICommonCode/" /I "../RTCPUtilitiesLib/" /FI"../WinNTSupport/Win32header.h" /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /FR /FD /I /GZ /c
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib oleaut32.lib ws2_32.lib wsock32.lib winmm.lib libcmtd.lib /nologo /subsystem:console /machine:I386 /nodefaultlib:"libcd.lib" /out:"..\WinNTSupport\Debug\PlaylistBroadcaster.exe" /pdbtype:sept
# SUBTRACT BASE LINK32 /incremental:no /debug
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib oleaut32.lib ws2_32.lib wsock32.lib winmm.lib libcmt.lib /nologo /subsystem:console /machine:I386 /nodefaultlib:"libcd.lib" /out:"..\WinNTSupport\Release\PlaylistBroadcaster.exe" /pdbtype:sept
# SUBTRACT LINK32 /pdb:none

!ENDIF 

# Begin Target

# Name "PlaylistBroadcaster - Win32 Debug"
# Name "PlaylistBroadcaster - Win32 Release"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=.\BroadcasterSession.cpp
# End Source File
# Begin Source File

SOURCE=.\BroadcastLog.cpp
# End Source File
# Begin Source File

SOURCE=..\RTSPClientLib\ClientSocket.cpp
# End Source File
# Begin Source File

SOURCE=.\NoRepeat.cpp
# End Source File
# Begin Source File

SOURCE=..\OSMemoryLib\OSMemory.cpp
# End Source File
# Begin Source File

SOURCE=.\PickerFromFile.cpp
# End Source File
# Begin Source File

SOURCE=.\playlist_broadcaster.cpp
# End Source File
# Begin Source File

SOURCE=.\playlist_elements.cpp
# End Source File
# Begin Source File

SOURCE=.\playlist_lists.cpp
# End Source File
# Begin Source File

SOURCE=.\playlist_parsers.cpp
# End Source File
# Begin Source File

SOURCE=.\playlist_QTRTPBroadcastFile.cpp
# End Source File
# Begin Source File

SOURCE=.\playlist_SDPGen.cpp
# End Source File
# Begin Source File

SOURCE=.\playlist_SimpleParse.cpp
# End Source File
# Begin Source File

SOURCE=.\playlist_utils.cpp
# End Source File
# Begin Source File

SOURCE=.\PlaylistBroadcaster.cpp
# End Source File
# Begin Source File

SOURCE=.\PlaylistPicker.cpp
# End Source File
# Begin Source File

SOURCE=.\PLBroadcastDef.cpp
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\QueryParamList.cpp
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\ResizeableStringFormatter.cpp
# End Source File
# Begin Source File

SOURCE=..\RTSPClientLib\RTSPClient.cpp
# End Source File
# End Group
# Begin Group "Resource Files"

# PROP Default_Filter "ico;cur;bmp;dlg;rc2;rct;bin;rgs;gif;jpg;jpeg;jpe"
# End Group
# Begin Group "Header Files"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\CommonUtilitiesLib\atomic.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\base64.h
# End Source File
# Begin Source File

SOURCE="..\..\..\..\..\Program Files\Microsoft Visual Studio\VC98\Include\BASETSD.H"
# End Source File
# Begin Source File

SOURCE=.\BroadcasterSession.h
# End Source File
# Begin Source File

SOURCE=.\BroadcastLog.h
# End Source File
# Begin Source File

SOURCE=..\RTSPClientLib\ClientSocket.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\ConfParser.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\DateTranslator.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\ev.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\EventContext.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\FastCopyMacros.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\getopt.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\GetWord.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\IdleTask.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\md5.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\md5digest.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\MyAssert.h
# End Source File
# Begin Source File

SOURCE=.\NoRepeat.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\OS.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\OSArrayObjectDeleter.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\OSBufferPool.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\OSCodeFragment.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\OSCond.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\OSFileSource.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\OSHashTable.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\OSHeaders.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\OSHeap.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\OSMemory.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\OSMutex.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\OSMutexRW.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\OSQueue.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\OSRef.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\OSThread.h
# End Source File
# Begin Source File

SOURCE=.\PickerFromFile.h
# End Source File
# Begin Source File

SOURCE=..\PlatformHeader.h
# End Source File
# Begin Source File

SOURCE=.\playlist_array.h
# End Source File
# Begin Source File

SOURCE=.\playlist_broadcaster.h
# End Source File
# Begin Source File

SOURCE=.\playlist_elements.h
# End Source File
# Begin Source File

SOURCE=.\playlist_lists.h
# End Source File
# Begin Source File

SOURCE=.\playlist_parsers.h
# End Source File
# Begin Source File

SOURCE=.\playlist_QTRTPBroadcastFile.h
# End Source File
# Begin Source File

SOURCE=.\playlist_SDPGen.h
# End Source File
# Begin Source File

SOURCE=.\playlist_SimpleParse.h
# End Source File
# Begin Source File

SOURCE=.\playlist_utils.h
# End Source File
# Begin Source File

SOURCE=.\PlaylistPicker.h
# End Source File
# Begin Source File

SOURCE=.\PLBroadcastDef.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\PLDoubleLinkedList.h
# End Source File
# Begin Source File

SOURCE=..\QTFileLib\QTAtom.h
# End Source File
# Begin Source File

SOURCE=..\QTFileLib\QTAtom_dref.h
# End Source File
# Begin Source File

SOURCE=..\QTFileLib\QTAtom_elst.h
# End Source File
# Begin Source File

SOURCE=..\QTFileLib\QTAtom_hinf.h
# End Source File
# Begin Source File

SOURCE=..\QTFileLib\QTAtom_mdhd.h
# End Source File
# Begin Source File

SOURCE=..\QTFileLib\QTAtom_mvhd.h
# End Source File
# Begin Source File

SOURCE=..\QTFileLib\QTAtom_stco.h
# End Source File
# Begin Source File

SOURCE=..\QTFileLib\QTAtom_stsc.h
# End Source File
# Begin Source File

SOURCE=..\QTFileLib\QTAtom_stsd.h
# End Source File
# Begin Source File

SOURCE=..\QTFileLib\QTAtom_stss.h
# End Source File
# Begin Source File

SOURCE=..\QTFileLib\QTAtom_stsz.h
# End Source File
# Begin Source File

SOURCE=..\QTFileLib\QTAtom_stts.h
# End Source File
# Begin Source File

SOURCE=..\QTFileLib\QTAtom_tkhd.h
# End Source File
# Begin Source File

SOURCE=..\QTFileLib\QTAtom_tref.h
# End Source File
# Begin Source File

SOURCE=..\QTFileLib\QTFile.h
# End Source File
# Begin Source File

SOURCE=..\QTFileLib\QTFile_FileControlBlock.h
# End Source File
# Begin Source File

SOURCE=..\QTFileLib\QTHintTrack.h
# End Source File
# Begin Source File

SOURCE=..\QTFileLib\QTRTPFile.h
# End Source File
# Begin Source File

SOURCE=..\APIStubLib\QTSS.h
# End Source File
# Begin Source File

SOURCE=..\APICommonCode\QTSSRollingLog.h
# End Source File
# Begin Source File

SOURCE=..\APIStubLib\QTSSRTSPProtocol.h
# End Source File
# Begin Source File

SOURCE=..\QTFileLib\QTTrack.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\QueryParamList.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\ResizeableStringFormatter.h
# End Source File
# Begin Source File

SOURCE=..\revision.h
# End Source File
# Begin Source File

SOURCE=..\RTPMetaInfoLib\RTPMetaInfoPacket.h
# End Source File
# Begin Source File

SOURCE=..\RTSPClientLib\RTSPClient.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\SafeStdLib.h
# End Source File
# Begin Source File

SOURCE=..\APICommonCode\SDPSourceInfo.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\SDPUtils.h
# End Source File
# Begin Source File

SOURCE=.\SimplePlayListElement.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\Socket.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\SocketUtils.h
# End Source File
# Begin Source File

SOURCE=..\APICommonCode\SourceInfo.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\StringFormatter.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\StringParser.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\StringTranslator.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\StrPtrLen.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\Task.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\TCPListenerSocket.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\TCPSocket.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\TimeoutTask.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\Trim.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\UDPDemuxer.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\UDPSocket.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\UDPSocketPool.h
# End Source File
# Begin Source File

SOURCE=..\CommonUtilitiesLib\UserAgentParser.h
# End Source File
# Begin Source File

SOURCE=..\WinNTSupport\Win32header.h
# End Source File
# End Group
# Begin Source File

SOURCE=.\ReadMe.txt
# End Source File
# End Target
# End Project
