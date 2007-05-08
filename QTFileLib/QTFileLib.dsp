# Microsoft Developer Studio Project File - Name="QTFileLib" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Static Library" 0x0104

CFG=QTFileLib - Win32 Release
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "QTFileLib.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "QTFileLib.mak" CFG="QTFileLib - Win32 Release"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "QTFileLib - Win32 Debug" (based on "Win32 (x86) Static Library")
!MESSAGE "QTFileLib - Win32 Release" (based on "Win32 (x86) Static Library")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "QTFileLib - Win32 Debug"

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
# ADD CPP /nologo /MTd /W3 /ZI /Od /I "../" /I "../CommonUtilitiesLib/" /I ".." /I "../APIStubLib" /I "../RTPMetaInfoLib/" /I "../CommonUtilitiesLib" /FI"../WinNTSupport/Win32header.h" /D "WIN32" /D "_DEBUG" /D "_MBCS" /D "_LIB" /D "DSS_USE_API_CALLBACKS" /FR /FD /GZ /c
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LIB32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo

!ELSEIF  "$(CFG)" == "QTFileLib - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "QTFileLib___Win32_Release"
# PROP BASE Intermediate_Dir "QTFileLib___Win32_Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /w /W0 /Gm /ZI /Od /I "../" /I "../CommonUtilitiesLib/" /I ".." /I "../APIStubLib" /I "../RTPMetaInfoLib/" /I "../CommonUtilitiesLib" /FI"../WinNTSupport/Win32header.h" /D "WIN32" /D "_MBCS" /D "_LIB" /D "DSS_USE_API_CALLBACKS" /FR /FD /GZ /c
# ADD CPP /nologo /MT /w /W0 /O1 /Ob2 /I "../" /I "../CommonUtilitiesLib/" /I ".." /I "../APIStubLib" /I "../RTPMetaInfoLib/" /I "../CommonUtilitiesLib" /FI"../WinNTSupport/Win32header.h" /D "WIN32" /D "_MBCS" /D "_LIB" /D "DSS_USE_API_CALLBACKS" /FD /c
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

# Name "QTFileLib - Win32 Debug"
# Name "QTFileLib - Win32 Release"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=.\QTAtom.cpp
# End Source File
# Begin Source File

SOURCE=.\QTAtom_dref.cpp
# End Source File
# Begin Source File

SOURCE=.\QTAtom_elst.cpp
# End Source File
# Begin Source File

SOURCE=.\QTAtom_hinf.cpp
# End Source File
# Begin Source File

SOURCE=.\QTAtom_mdhd.cpp
# End Source File
# Begin Source File

SOURCE=.\QTAtom_mvhd.cpp
# End Source File
# Begin Source File

SOURCE=.\QTAtom_stco.cpp
# End Source File
# Begin Source File

SOURCE=.\QTAtom_stsc.cpp
# End Source File
# Begin Source File

SOURCE=.\QTAtom_stsd.cpp
# End Source File
# Begin Source File

SOURCE=.\QTAtom_stss.cpp
# End Source File
# Begin Source File

SOURCE=.\QTAtom_stsz.cpp
# End Source File
# Begin Source File

SOURCE=.\QTAtom_stts.cpp
# End Source File
# Begin Source File

SOURCE=.\QTAtom_tkhd.cpp
# End Source File
# Begin Source File

SOURCE=.\QTAtom_tref.cpp
# End Source File
# Begin Source File

SOURCE=.\QTFile.cpp
# End Source File
# Begin Source File

SOURCE=.\QTFile_FileControlBlock.cpp
# End Source File
# Begin Source File

SOURCE=.\QTHintTrack.cpp
# End Source File
# Begin Source File

SOURCE=.\QTRTPFile.cpp
# End Source File
# Begin Source File

SOURCE=.\QTTrack.cpp
# End Source File
# Begin Source File

SOURCE=..\RTPMetaInfoLib\RTPMetaInfoPacket.cpp
# End Source File
# End Group
# End Target
# End Project
