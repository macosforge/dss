---
title: Frequently Asked Questions
redirect_from: /faq.html
---

## What is Darwin Streaming Server?

Darwin Streaming Server is the open source server allowing you to stream hinted QuickTime, MPEG-4, and 3GPP files over the Internet via the industry standard RTP and RTSP protocols.

## What's new in DSS 6.0.3?

See the [DSS 6.0.3 release notes](https://github.com/macosforge/dss/releases/tag/6.0.3).

## Where can I find binaries for previous releases of Darwin Streaming Server?

See the [releases](https://github.com/macosforge/dss/releases) page.

## Does Darwin Streaming Server 6.0.3 install on Mac OS X 10.4 Tiger?

The posted installer will not install on Mac OS X v10.4. The installer binaries are built for 10.5 and will not run on older versions of the Mac OS.

## Can Darwin Streaming Server 6.0.3 be built on Mac OS X 10.4 Tiger?

Yes, there are some functional differences but the 6.0.3 source can be built using the buildit script as well as the installer package on Mac OS X 10.4. See the [developer notes](https://github.com/macosforge/dss/blob/master/Documentation/DevNotes.html) for more information.

## What does the Darwin Streaming Server source include?

The package includes source files for a streaming server with web based administration that can serve on-disk "hinted" QuickTime, MPEG2-program streams (hinted files), MPEG-4, and 3GPP files and reflect live broadcasts, as well as source for the proxy (except on Windows). StreamingLoadTool source code. See the [Documentation](https://github.com/macosforge/dss/tree/master/Documentation) directory included with the source for more information about the code.

## Where can I find information about streaming with Darwin Streaming Server (DSS)?

* <https://macosforge.github.io/dss/>
* <http://soundscreen.com/streaming/>
* <http://streaming411.com/wiki>
* <http://streaming411.com/forums>

## Which CVS tag is the latest stable release?

Future CVS use is under review while SVN or simple source tar postings are being evaluated.

You can download the latest Mac OS X 10.5 release from the [releases](https://github.com/macosforge/dss/releases) page.

The http://developer.apple.com/opensource/server/streaming/ CVS contains software for DSS Mac OS 10.4 and other OS platforms.

The latest CVS tag is DSS_5_5_5_Release. The Darwin Streaming Server branch tag is DSS_10_4_Branch. The QuickTime Streaming Server branch tag is MacOS_10_4_Branch.

## What is on the CVS top of tree?

The top of tree is reserved for merging QuickTime Streaming Server development and unreleased code with Darwin Streaming Server code to create a new major release branch. Bug fixes and submissions are added to branches.

## My .mp4, .3gp, or .mov file won't stream. Why does the player show 415 invalid media?

The streaming server supports QuickTime Movie (MOV), MPEG-4 (MP4), and 3GPP (3GP) "hinted" files.

Hinting is a post-process that you apply to your movies to make them RTSP-streamable. You can hint them with QuickTime Pro or the hinting tool available in the MPEG4IP package.

If you don't hint your .mov's or mp4's they will still be HTTP-downloadable but it will take them some seconds to start playing. You won't need a streaming server for this, just use good old Apache.

See also <http://soundscreen.com/streaming/compress_hint.html>.

## Can I stream mp3 files with DSS?

No, not by default, but the server can be configured using the experimental module "QTSSHttpFileModule" located in the modules.disabled directory. The module must be moved to the modules directory and an http_folder must be defined in the server's preference xml file.

## Can I http download files with DSS?

No, not by default, but the server can be configured using the experimental module "QTSSHttpFileModule" located in the modules.disabled directory. The module must be moved to the modules directory and an http_folder must be defined in the server's preference xml file.

## Can I configure DSS to stream live mp3 streams to simulate a radio station to connected users?

Yes. Use the MP3Broadcaster that is part of DSS to broadcast mp3 v1, v2, and v2.3 files from a server side playlist to DSS. All files must have the same sample rate.

## Can I configure DSS to stream live .mp4, .3gp, or .mov streams to simulate a radio or tv station to connected users?

Yes. Use the PlaylistBroadcaster that is part of DSS, to stream hinted files from a server side playlist to DSS. All video files must have the same frame size and use the same codec and all audio files must have the same sample size and use the same codec.

## Can I update the server side playlists while the playlist is being broadcast?

Yes. Replace the playlist file and add a playlist file using the playlist name and the extension ".updatelist" in the same directory as the playlist file.

## Can I see what the upcoming files are while the server side playlist is playing?

Yes. Look for the file with the extensions ".upcoming" in the directory with the playlist.

## Can I see the name of the current file being played by the server side playlist?

Yes. Look for a file with the extension ".current" in the directory with the playlist.

## Can I tell the playlist broadcaster to stop playing a playlist after 0 or more files?

Yes. Add a playlist file using the playlist name and the extension ".stoplist" in the same directory as the playlist file and it will be read at the next song and then deleted. The broadcast will stop playing at the end of the stoplist.

## Can I temporarily insert a set of files into the playlist while it is playing?

Yes. Add a playlist file with the playlist name and the extension ".insertlist" in the same directory as the playlist file and its list will be insert at the end of the next song and then deleted. The broadcast will revert back to the original list after playing the inserted list.

## Where is the streaming server's preference xml file?

* macOS: /Library/QuickTimeStreaming/Config/streamingserver.xml
* Windows: c:\Program Files\Darwin Streaming Server\streamingserver.xml
* UNIX-style OS: /etc/streaming/streamingserver.xml

## Where are the default log, movie folder, modules, and configuration paths defined?

See the file [defaultPaths.h](https://github.com/macosforge/dss/blob/master/defaultPaths.h) in the source code.

## What codecs can I use with DSS?

Because DSS streams hinted streaming files, any file that has been successfully hinted can be used by DSS. Hinted files remove the need for the server to understand the media information of the files it streams.

## How do I compile on Linux?

For DSS 5.5.5 or earlier: On UNIX platforms, type `./Buildit` from within the source directory.

## How do I create an installer directory and tar package?

On UNIX platforms, type `./Buildit install`. A DarwinStreamingSrvr-Platform install directory and tar file will be created.

See the [developer notes](https://github.com/macosforge/dss/blob/master/Documentation/DevNotes.html) for more information.

## How do I compile on Windows?

For DSS 5.5.5 or earlier: To build Darwin Streaming Server on Windows NT or Windows 2000, you must have a copy of Visual C++ version 6.0. There is a VC++ workspace file located inside the [WinNTSupport](https://github.com/macosforge/dss/tree/master/WinNTSupport) directory that can be used to to build the server. Once the workspace is open, select Batch Build from the Build menu.

See the [developer notes](https://github.com/macosforge/dss/blob/master/Documentation/DevNotes.html) in the source code for more information.

## Why does it take so long (a few seconds) the first time I connect to my streaming server using the QuickTime Player?

The first time the player connects to an IP address it checks the bandwidth to the server which can take a few seconds.

## Why does it take so long (30 seconds or more) the first time I connect to my streaming server using the QuickTime Player?

If there is a firewall or the default UDP port is unavailable the client will try alternate ports and protocols to connect to the server. This process can take up to a minute.

## How do I get through a firewall?

The best solution is to configure the firewall to allow streaming access minimally on port 554 and preferably with udp support on 6970-6999, and 1220 for web admin access, 8000 for mp3 streaming, and 7070 for some streaming players. When that is not possible, the QuickTime Player will automatically try to switch to the HTTP protocol to stream from the server, this sometimes works but if the standard streaming ports are completely blocked by a firewall then streaming on port 80 should be tried.

## How do I stream on Port 80 and have a Web server on the same system?

This is not possible without changing either DSS or the web server's port to something other than 80.

## How do I set up Authenticated access?

For DSS 6.0 or later: Turn off guest access in the server preference xml file by setting the "enable_allow_guest_default" preference to "false". The server will authenticate users against Directory Services and qtaccess files.

Please see DSS admin guide located at <http://developer.apple.com/opensource/server/streaming/qtss_admin_guide.pdf>.

## What does this error mean?

<dl>

<dt>415 - Unsupported Media Type</dt>
<dd>The file is probably not hinted or corrupt. The server was found but the requested media couldn't be accessed.</dd>

<dt>-3285 disconnect</dt>
<dd>Probably a firewall. The server was found but a network failure occurred.</dd>

<dt>-5420 connection failed</dt>
<dd>Server not found, maybe not running, or the machine or network is not connected.</dd>

<dt>404 file not found</dt>
<dd>A file was not found on the server or a live stream is no longer broadcasting to the server.</dd>

</dl>

## Can I use the QuickTime logo or web badge with my server?

Guidelines for use of the QuickTime logo and web badge are available at <http://developer.apple.com/softwarelicensing/agreements/quicktime.html>.
