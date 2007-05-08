# Microsoft Developer Studio Project File - Name="qtpasswd" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Console Application" 0x0103

CFG=qtpasswd - Win32 Release
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "qtpasswd.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "qtpasswd.mak" CFG="qtpasswd - Win32 Release"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "qtpasswd - Win32 Debug" (based on "Win32 (x86) Console Application")
!MESSAGE "qtpasswd - Win32 Release" (based on "Win32 (x86) Console Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 1
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "qtpasswd - Win32 Debug"

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
# ADD CPP /nologo /MTd /W3 /Gm /ZI /Od /I "../" /I "../CommonUtilitiesLib/" /I "../OSMemoryLib/" /FI"../WinNTSupport/Win32header.h" /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /FR /FD /GZ /c
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /debug /machine:I386 /pdbtype:sept
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib oleaut32.lib ws2_32.lib wsock32.lib winmm.lib libcmtd.lib /nologo /subsystem:console /debug /machine:I386 /nodefaultlib:"libcd.lib" /out:"..\WinNTSupport\Debug\qtpasswd.exe" /pdbtype:sept
# SUBTRACT LINK32 /pdb:none

!ELSEIF  "$(CFG)" == "qtpasswd - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "qtpasswd___Win32_Release"
# PROP BASE Intermediate_Dir "qtpasswd___Win32_Release"
# PROP BASE Ignore_Export_Lib 0
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /w /W0 /Gm /ZI /Od /I "../" /I "../CommonUtilitiesLib/" /I "../OSMemoryLib/" /FI"../WinNTSupport/Win32header.h" /D "WIN32" /D "_CONSOLE" /D "_MBCS" /FD /GZ /c
# ADD CPP /nologo /MT /w /W0 /O1 /Ob2 /I "../" /I "../CommonUtilitiesLib/" /I "../OSMemoryLib/" /FI"../WinNTSupport/Win32header.h" /D "WIN32" /D "_CONSOLE" /D "_MBCS" /FD /c
# ADD BASE RSC /l 0x409
# ADD RSC /l 0x409
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib oleaut32.lib ws2_32.lib wsock32.lib winmm.lib libcmtd.lib /nologo /subsystem:console /debug /machine:I386 /nodefaultlib:"libcd.lib" /pdbtype:sept
# SUBTRACT BASE LINK32 /pdb:none
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib winmm.lib odbc32.lib odbccp32.lib oleaut32.lib ws2_32.lib wsock32.lib libcmt.lib /nologo /subsystem:console /debug /machine:I386 /nodefaultlib:"libc.lib" /out:"..\WinNTSupport\Release\qtpasswd.exe" /pdbtype:sept
# SUBTRACT LINK32 /pdb:none

!ENDIF 

# Begin Target

# Name "qtpasswd - Win32 Debug"
# Name "qtpasswd - Win32 Release"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=..\OSMemoryLib\OSMemory.cpp
# End Source File
# Begin Source File

SOURCE=.\QTSSPasswd.cpp
# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl"
# End Group
# Begin Group "Resource Files"

# PROP Default_Filter "ico;cur;bmp;dlg;rc2;rct;bin;rgs;gif;jpg;jpeg;jpe"
# End Group
# Begin Source File

SOURCE=.\ReadMe.txt
# End Source File
# End Target
# End Project
