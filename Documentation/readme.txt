About Darwin Streaming Server 

Contents

Welcome to Darwin Streaming Server, Apple's open source version of the QuickTime Streaming Server technology allowing you to send streaming media across the Internet using the industry standard RTP and RTSP protocols. Based on the same code base as QuickTime Streaming Server, Darwin Streaming Server provides a high level of customizability and runs on a variety of platforms allowing you to manipulate the code to fit your needs. 

What's New with Darwin Streaming Server 5.5.5

Darwin Streaming Server 5.5.5 is a new release containing open source submissions for the following issues:
- Compilation problems using gcc 4 (Andreas Thienemann)
- Support for SDPs created by VLC and Mpeg4IP (David Moore)
- Fix date display in DSS Web Admin (Maksym Veremeyenko)
- Better support for streaming through NAT (Denis Ahrens)
- Better support for running DSS on a multi-homed system (Denis Ahrens)
- Relaying problems with VLC (Alessandro Falaschi, http://labtel.ing.uniroma1.it/opencdn/darwinp.html)
- A security fix for possible stack and heap overflow attacks in the StreamingProxy (CVE-2007-0748, CVE-2007-0749)
- A fix for sync sample searching on OS X intel.
- A fix for an infinite loop when the server fails to bind to streaming ports.
- An enhancement allowing RTSP requests to contain the hh:mm:ss format for the npt value (Fredrik Widlund)

Please use http://www.opensource.apple.com/projects/modifications.html to submit your own Darwin Streaming Server modifications.


What's New with Darwin Streaming Server 5.5.4

Darwin Streaming Server 5.5.4 includes the following enhancements to 5.5.3:

- A fix to the unsigned character handling in the string parser resolves the following compiler generated issues:
--  Failure to stream to non-english QuickTime Players
--  Failure to stream live broadcast SDP files containing high-ascii characters
--  Failure to authenticate with users and passwords with high-ascii characters


Darwin Streaming Server 5.5.3 includes the following enhancements to 5.5.1:

- A security fix for DSS to prevent a crash when receiving an invalid RTSP request.
- A security fix for DSS to prevent a crash when reading an invalid movie file.
- An update to the Buildit script to build on Mac OS X intel systems.


Darwin Streaming Server 5.5 includes the following enhancements to 5.0.1.1:

- Latest security update changes
- Latest 3GPP release 5 client support
- High definition H.264 streaming 

Darwin Streaming Server 5.0.1.1 includes the following enhancements to 5.0:

- Latest security update changes
- Improved Safari compatibility

Darwin Streaming Server 5.0

- Enhanced multithread support 
- Home directory streaming (UNIX-based platforms only)
- Broadcast directory streaming
- HTTP to RTSP url redirection using QuickTime HREF support.
- Improved security through non-root user execution (UNIX-based platforms only)
- 3GPP streaming enhancements - As we constantly improve our support for streaming the latest digital media standards, DSS 5 includes a number of enhancements for 3GPP streaming

It can be ported to other platforms by modifying a handful of platform-specific source files. For more information about the source code and how to port to other platforms, see the files AboutTheSource.html and SourceFAQ.html provided with the Darwin Streaming Server source code.

For more information about the Darwin Streaming Server project and to obtain the Darwin Streaming Server 5.5 source, see Apple's Open Source Web site at: <http://developer.apple.com/darwin>.


System Requirements

Darwin Streaming Server is currently available on the following platforms:

*Mac OS X (version 10.2.8 or later)
*Linux (RedHat 8/9, Intel)
*Solaris 9 (SPARC)
*Windows 2000 Server/2003 Server

Darwin Streaming Server is compatible with QuickTime 4 or later client software. Digest mode Authentication and Skip Protection (first introduced in QuickTime Streaming Server 3.0) require QuickTime 5 or later client software.

Installing Darwin Streaming Server (Mac OS X)

To install Darwin Streaming Server 5.5 software, follow these 
steps:

1. After downloading Darwin Streaming Server, double-click the DarwinStreamingServer.dmg file. DarwinStreamingServer will mount a desktop image that contains DarwinStreamingServer.pkg.  

2. Double-click the DarwinStreamingServer.pkg file. This will launch the installer.

3. Click on the "lock" icon to make changes when prompted during installation. You will need to authenticate with the administrator username and password.

4. Follow the onscreen instructions. After you have read and agreed to the license, you can proceed with the installation.

5. If you are installing for the first time, after the install completes, you will be asked to create a user name and password for administering the server.  You must complete this step to administer the server from a remote system using a web browser.
    
   If you are upgrading, you will be presented with a web browser login window.

Set Up (Mac OS X)

After creating an administrator user name and password,  you can connect to the Darwin Streaming Server from your web browser.

Enter the URL for your Darwin Streaming Server:
http://myserver.com:1220

Replace "myserver.com" with the name of your Darwin Streaming Server computer. 
1220 is the port number.

    
Installing Darwin Streaming Server (Linux, Solaris)

To install Darwin Streaming Server 5.5 software, follow these steps on the server computer:

Stop any Darwin Streaming Server related processes.

IMPORTANT: Installing Darwin Streaming Server will remove older versions of Darwin Streaming Server. 
If an existing configuration is found, then the /etc/streamingserver.xml configuration file will be copied to 
/etc/streamingserver.xml.bak. 

After the install completes, you may need to reset your configuration settings from your /etc/streamingserver.xml.bak file.
    
Expand the compressed (.gz) tar file and "cd" into one of the following directories, depending on the platform: 
    DarwinStreamingSrvr5.5-Linux 

Then type: 
    ./Install

During the install, the streamingadminserver.pl application will automatically launch. To avoid the need to manually relaunch streamingadminserver.pl following reboots, you may want to configure your server machine to launch it automatically at boot time.

Set Up (Linux)
During the install, you will be asked to create a user name and password for administering the server.  You must complete this step to administer the server from a remote system using a web browser.

After creating an administrator user name and password,  you can connect to the Darwin Streaming Server from your web browser.

Enter the URL for your Darwin Streaming Server:
    http://myserver.com:1220

Replace "myserver.com" with the name of your Darwin Streaming Server computer. 
    1220 is the port number.


Installing Darwin Streaming Server (Windows 2000/2003 Server)

The Streaming Admin requires ActivePerl 5.8 (or later) to be running on the server machine. You must install a Perl interpreter in order to use the web-based administration software. 


To install Darwin Streaming Server software, follow these steps on the server computer:

Stop any Darwin Streaming Server related processes.

When the Server package is unzipped, a folder with Darwin Streaming Server and associated files will be created. Inside this folder is an Install script, named "Install.bat". Double-click this file to install the server and its components on the server machine. The installer also starts up the Streaming Server Admin, so keep the command prompt window open.
 
The Install script will create the following directory:

c:\Program Files\Darwin Streaming Server\

Inside this directory you will find:

DarwinStreamingServer.exe - Server executable
PlaylistBroadcaster.exe - PlaylistBroadcaster executable
MP3Broadcaster.exe – MP3 Broadcaster executable
qtpasswd.exe - Command-line utility for generating password files for access control
StreamingLoadTool.exe - RTSP simulated client stress tool
streamingadminserver.pl - Admin Server that is used for administering the Streaming Server
streamingserver.xml- Default server configuration file
relayconfig.xml-Sample - Sample relay configuration file
QTSSModules\ - Folder containing QTSS API modules
Movies\ - Media folder
Playlists\ - Folder containing Playlist configuration
Logs\ - Folder containing access and error logs
AdminHtml\ - Folder containing the CGIs and the HTMl files required by the Admin Server
Documentation\ - Documentation folder

The Install script also installs Darwin Streaming Server as a service in the Service Manager. It is possible to start, stop, and check server status from the Service control panel.

The Install script will attempt to launch the Admin Server. Make sure that the Perl interpreter installed on your machine is in the system PATH.

The Admin Server can be launched from the command prompt by typing:

C:\> perlpath "C:\Program Files\Darwin Streaming Server\streamingadminserver.pl"

where perlpath is the path to the Perl interpreter on your machine.


    If you are installing for the first time,  you will be asked to create a user name and password for administering the server.  You must complete this step to administer the server from a remote system using a web browser.
    

Set Up (Windows 2000/2003 Server)

    After creating an administrator user name and password,  you can connect to the Darwin Streaming Server from your web browser.

   Enter the URL for your Darwin Streaming Server:
http://localhost:1220 on the same local system or
http://myserver.com:1220 from a remote system

Replace "myserver.com" with the name of your Darwin Streaming Server computer. 
1220 is the port number.
	For help on using Streaming Server Admin, setting up secure administration (SSL), and setting up your server to stream hinted media, refer to the online Help by selecting the Question Mark button from the Streaming Server Admin.


Troubleshooting


* File Locations


Darwin Streaming Server (Mac OS X)
/usr/sbin/QuickTimeStreamingServer - Streaming Server app
/usr/sbin/streamingadminserver.pl - QTSS Web Admin server
/Library/QuickTimeStreaming/Modules/ - QTSS plug-ins
/usr/bin/PlaylistBroadcaster - The PlaylistBroadcaster
/usr//bin/MP3Broadcaster - The MP3Broadcaster
/usr/bin/qtpasswd - Generates password files for access control
/usr//bin/StreamingLoadTool - RTSP simulated client stress tool
/Library/QuickTimeStreaming/Config/ - QTSS config files
/Library/QuickTimeStreaming/Movies/ - Media files
/Library/QuickTimeStreaming/Docs/  - readme.html & user manual.pdf files
/Library/QuickTimeStreaming/logs/ - Logs
/Library/QuickTimeStreaming/playlists - Web Admin Playlist files

Darwin Streaming Server (Unix)
/usr/local/sbin/DarwinStreamingServer - Streaming Server app
/usr/local/sbin/streamingadminserver.pl - QTSS Web Admin server
/usr/local/sbin/StreamingServerModules/ - QTSS plug-ins
/usr/local/bin/PlaylistBroadcaster - The PlaylistBroadcaster
/usr/local/bin/MP3Broadcaster - The MP3Broadcaster
/usr/local/bin/qtpasswd - Generates password files for access control
/usr/local/bin/StreamingLoadTool - RTSP simulated client stress tool
/etc/streaming/ - QTSS config files
/usr/local/movies/ - Media files
/var/streaming/  - readme.html & user manual.pdf files
/var/streaming/logs - Logs
/var/streaming/playlists - Web Admin Playlist files

Darwin Streaming Server (Windows)
C:\Program Files\Darwin Streaming Server\
C:\Program Files\Darwin Streaming Server\Movies
C:\Program Files\Darwin Streaming Server\Playlists
C:\Program Files\Darwin Streaming Server\Logs
C:\Program Files\Darwin Streaming Server\QTSSModules
C:\Program Files\Darwin Streaming Server\AdminHtml


Public Mailing Lists

Through the Apple public mailing lists you can share experiences, questions, and comments with others who use the software. Apple employees may monitor the list, but Apple does not guarantee that questions sent to this list will be answered. For more information about joining the mailing lists, see the Apple mailing lists Web site at www.lists.apple.com.

For Darwin Streaming Server administration, join the Streaming Server mailing list, “streaming-server-users”. 

If you are interested in plug-in API or Open Source development, join the Streaming Server developer public mailing list, “streaming-server-developers”. 

The Darwin Streaming Server release is not supported by Apple Computer.


© 2003 Apple Computer, Inc. All rights reserved. Apple, the Apple logo, Mac, Macintosh, PowerBook, Power Macintosh, and QuickTime are trademarks of Apple Computer, Inc., registered in the United States and other countries.  eMac, iBook,  iMac, Power Mac and Xserve are trademarks of Apple Computer, Inc. All other product names are trademarks or registered trademarks of their respective holders.

