# Microsoft Developer Studio Project File - Name="QTFileExternalLib" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Static Library" 0x0104

CFG=QTFileExternalLib - Win32 Release
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "QTFileExternalLib.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "QTFileExternalLib.mak" CFG="QTFileExternalLib - Win32 Release"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "QTFileExternalLib - Win32 Debug" (based on "Win32 (x86) Static Library")
!MESSAGE "QTFileExternalLib - Win32 Release" (based on "Win32 (x86) Static Library")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "QTFileExternalLib - Win32 Debug"

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
# ADD CPP /nologo /MTd /W3 /ZI /Od /I "../../" /I "../../CommonUtilitiesLib/" /I ".." /I "../../RTPMetaInfoLib/" /FI"../WinNTSupport/Win32header.h" /D "WIN32" /D "_DEBUG" /D "_MBCS" /D "_LIB" /FR /FD /I /GZ /c
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LIB32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo

!ELSEIF  "$(CFG)" == "QTFileExternalLib - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "QTFileExternalLib___Win32_Release"
# PROP BASE Intermediate_Dir "QTFileExternalLib___Win32_Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /w /W0 /Gm /ZI /Od /I "../../" /I "../../CommonUtilitiesLib/" /I ".." /I "../../RTPMetaInfoLib/" /FI"../WinNTSupport/Win32header.h" /D "WIN32" /D "_MBCS" /D "_LIB" /FR /FD /I /GZ /c
# ADD CPP /nologo /MT /w /W0 /O1 /Ob2 /I "../../" /I "../../CommonUtilitiesLib/" /I ".." /I "../../RTPMetaInfoLib/" /FI"../WinNTSupport/Win32header.h" /D "WIN32" /D "_MBCS" /D "_LIB" /FD /I /force /c
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

# Name "QTFileExternalLib - Win32 Debug"
# Name "QTFileExternalLib - Win32 Release"
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl"
# Begin Source File

SOURCE="..\..\..\..\Program Files\Microsoft Visual Studio\VC98\Include\BASETSD.H"
# End Source File
# Begin Source File

SOURCE=..\..\CommonUtilitiesLib\DateTranslator.h
# End Source File
# Begin Source File

SOURCE=..\..\CommonUtilitiesLib\FastCopyMacros.h
# End Source File
# Begin Source File

SOURCE=..\..\CommonUtilitiesLib\MyAssert.h
# End Source File
# Begin Source File

SOURCE=..\..\CommonUtilitiesLib\OS.h
# End Source File
# Begin Source File

SOURCE=..\..\CommonUtilitiesLib\OSCond.h
# End Source File
# Begin Source File

SOURCE=..\..\CommonUtilitiesLib\OSFileSource.h
# End Source File
# Begin Source File

SOURCE=..\..\CommonUtilitiesLib\OSHeaders.h
# End Source File
# Begin Source File

SOURCE=..\..\CommonUtilitiesLib\OSMemory.h
# End Source File
# Begin Source File

SOURCE=..\..\CommonUtilitiesLib\OSMutex.h
# End Source File
# Begin Source File

SOURCE=..\..\CommonUtilitiesLib\OSQueue.h
# End Source File
# Begin Source File

SOURCE=..\..\CommonUtilitiesLib\OSThread.h
# End Source File
# Begin Source File

SOURCE=..\..\PlatformHeader.h
# End Source File
# Begin Source File

SOURCE=..\QTAtom.h
# End Source File
# Begin Source File

SOURCE=..\QTAtom_dref.h
# End Source File
# Begin Source File

SOURCE=..\QTAtom_elst.h
# End Source File
# Begin Source File

SOURCE=..\QTAtom_hinf.h
# End Source File
# Begin Source File

SOURCE=..\QTAtom_mdhd.h
# End Source File
# Begin Source File

SOURCE=..\QTAtom_mvhd.h
# End Source File
# Begin Source File

SOURCE=..\QTAtom_stco.h
# End Source File
# Begin Source File

SOURCE=..\QTAtom_stsc.h
# End Source File
# Begin Source File

SOURCE=..\QTAtom_stsd.h
# End Source File
# Begin Source File

SOURCE=..\QTAtom_stss.h
# End Source File
# Begin Source File

SOURCE=..\QTAtom_stsz.h
# End Source File
# Begin Source File

SOURCE=..\QTAtom_stts.h
# End Source File
# Begin Source File

SOURCE=..\QTAtom_tkhd.h
# End Source File
# Begin Source File

SOURCE=..\QTAtom_tref.h
# End Source File
# Begin Source File

SOURCE=..\QTFile.h
# End Source File
# Begin Source File

SOURCE=..\QTFile_FileControlBlock.h
# End Source File
# Begin Source File

SOURCE=..\QTHintTrack.h
# End Source File
# Begin Source File

SOURCE=..\QTRTPFile.h
# End Source File
# Begin Source File

SOURCE=..\QTTrack.h
# End Source File
# Begin Source File

SOURCE=..\..\revision.h
# End Source File
# Begin Source File

SOURCE=..\..\RTPMetaInfoLib\RTPMetaInfoPacket.h
# End Source File
# Begin Source File

SOURCE=..\..\CommonUtilitiesLib\StringParser.h
# End Source File
# Begin Source File

SOURCE=..\..\CommonUtilitiesLib\StrPtrLen.h
# End Source File
# Begin Source File

SOURCE=..\..\WinNTSupport\Win32header.h
# End Source File
# End Group
# Begin Group "Source Files"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\QTAtom.cpp

!IF  "$(CFG)" == "QTFileExternalLib - Win32 Debug"

!ELSEIF  "$(CFG)" == "QTFileExternalLib - Win32 Release"

# ADD CPP /O1
# SUBTRACT CPP /Z<none>

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\QTAtom_dref.cpp

!IF  "$(CFG)" == "QTFileExternalLib - Win32 Debug"

!ELSEIF  "$(CFG)" == "QTFileExternalLib - Win32 Release"

# ADD CPP /O1
# SUBTRACT CPP /Z<none>

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\QTAtom_elst.cpp

!IF  "$(CFG)" == "QTFileExternalLib - Win32 Debug"

!ELSEIF  "$(CFG)" == "QTFileExternalLib - Win32 Release"

# ADD CPP /O1
# SUBTRACT CPP /Z<none>

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\QTAtom_hinf.cpp

!IF  "$(CFG)" == "QTFileExternalLib - Win32 Debug"

!ELSEIF  "$(CFG)" == "QTFileExternalLib - Win32 Release"

# ADD CPP /O1
# SUBTRACT CPP /Z<none>

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\QTAtom_mdhd.cpp

!IF  "$(CFG)" == "QTFileExternalLib - Win32 Debug"

!ELSEIF  "$(CFG)" == "QTFileExternalLib - Win32 Release"

# ADD CPP /O1
# SUBTRACT CPP /Z<none>

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\QTAtom_mvhd.cpp

!IF  "$(CFG)" == "QTFileExternalLib - Win32 Debug"

!ELSEIF  "$(CFG)" == "QTFileExternalLib - Win32 Release"

# ADD CPP /O1
# SUBTRACT CPP /Z<none>

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\QTAtom_stco.cpp

!IF  "$(CFG)" == "QTFileExternalLib - Win32 Debug"

!ELSEIF  "$(CFG)" == "QTFileExternalLib - Win32 Release"

# ADD CPP /O1
# SUBTRACT CPP /Z<none>

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\QTAtom_stsc.cpp

!IF  "$(CFG)" == "QTFileExternalLib - Win32 Debug"

!ELSEIF  "$(CFG)" == "QTFileExternalLib - Win32 Release"

# ADD CPP /O1
# SUBTRACT CPP /Z<none>

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\QTAtom_stsd.cpp

!IF  "$(CFG)" == "QTFileExternalLib - Win32 Debug"

!ELSEIF  "$(CFG)" == "QTFileExternalLib - Win32 Release"

# ADD CPP /O1
# SUBTRACT CPP /Z<none>

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\QTAtom_stss.cpp

!IF  "$(CFG)" == "QTFileExternalLib - Win32 Debug"

!ELSEIF  "$(CFG)" == "QTFileExternalLib - Win32 Release"

# ADD CPP /O1
# SUBTRACT CPP /Z<none>

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\QTAtom_stsz.cpp

!IF  "$(CFG)" == "QTFileExternalLib - Win32 Debug"

!ELSEIF  "$(CFG)" == "QTFileExternalLib - Win32 Release"

# ADD CPP /O1
# SUBTRACT CPP /Z<none>

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\QTAtom_stts.cpp

!IF  "$(CFG)" == "QTFileExternalLib - Win32 Debug"

!ELSEIF  "$(CFG)" == "QTFileExternalLib - Win32 Release"

# ADD CPP /O1
# SUBTRACT CPP /Z<none>

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\QTAtom_tkhd.cpp

!IF  "$(CFG)" == "QTFileExternalLib - Win32 Debug"

!ELSEIF  "$(CFG)" == "QTFileExternalLib - Win32 Release"

# ADD CPP /O1
# SUBTRACT CPP /Z<none>

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\QTAtom_tref.cpp

!IF  "$(CFG)" == "QTFileExternalLib - Win32 Debug"

!ELSEIF  "$(CFG)" == "QTFileExternalLib - Win32 Release"

# ADD CPP /O1
# SUBTRACT CPP /Z<none>

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\QTFile.cpp

!IF  "$(CFG)" == "QTFileExternalLib - Win32 Debug"

!ELSEIF  "$(CFG)" == "QTFileExternalLib - Win32 Release"

# ADD CPP /O1
# SUBTRACT CPP /Z<none>

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\QTFile_FileControlBlock.cpp

!IF  "$(CFG)" == "QTFileExternalLib - Win32 Debug"

!ELSEIF  "$(CFG)" == "QTFileExternalLib - Win32 Release"

# ADD CPP /O1
# SUBTRACT CPP /Z<none>

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\QTHintTrack.cpp

!IF  "$(CFG)" == "QTFileExternalLib - Win32 Debug"

!ELSEIF  "$(CFG)" == "QTFileExternalLib - Win32 Release"

# ADD CPP /O1
# SUBTRACT CPP /Z<none>

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\QTRTPFile.cpp

!IF  "$(CFG)" == "QTFileExternalLib - Win32 Debug"

!ELSEIF  "$(CFG)" == "QTFileExternalLib - Win32 Release"

# ADD CPP /O1
# SUBTRACT CPP /Z<none>

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\QTTrack.cpp

!IF  "$(CFG)" == "QTFileExternalLib - Win32 Debug"

!ELSEIF  "$(CFG)" == "QTFileExternalLib - Win32 Release"

# ADD CPP /O1
# SUBTRACT CPP /Z<none>

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\..\RTPMetaInfoLib\RTPMetaInfoPacket.cpp

!IF  "$(CFG)" == "QTFileExternalLib - Win32 Debug"

!ELSEIF  "$(CFG)" == "QTFileExternalLib - Win32 Release"

# ADD CPP /O1
# SUBTRACT CPP /Z<none>

!ENDIF 

# End Source File
# End Group
# End Target
# End Project
