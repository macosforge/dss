#!/usr/bin/perl
# 
# @APPLE_LICENSE_HEADER_START@
#
# Copyright (c) 1999-2003 Apple Computer, Inc.  All Rights Reserved.
#
# This file contains Original Code and/or Modifications of Original Code
# as defined in and that are subject to the Apple Public Source License
# Version 2.0 (the 'License'). You may not use this file except in
# compliance with the License. Please obtain a copy of the License at
# http://www.opensource.apple.com/apsl/ and read it before using this
# file.
#
# The Original Code and all software distributed under the License are
# distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
# EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
# INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
# Please see the License for the specific language governing rights and
# limitations under the License.
#
# @APPLE_LICENSE_HEADER_END@
#
# Require needed libraries
#
# A very simple perl web server used by Streaming Admin Server

# If it's Win32, check to make sure we're using the correct Perl version
if ($^O eq "MSWin32")
{
	eval "use Config";
	$activeperl_required_message = "\r\n\r\nActivePerl 5.8.0 or higher is required in order to run the Darwin Streaming Server web-based administration.\r\nPlease download it from http://www.activeperl.com/ and install it.\r\n\r\n";
	die $activeperl_required_message if ($Config{"PERL_API_REVISION"} + ($Config{"PERL_API_VERSION"} * 0.1) < 5.8);
}
 
# Require needed libraries
package streamingadminserver;
use Socket;
use POSIX;
use Sys::Hostname;
#eval "use Net::SSLeay";

if ($^O eq "darwin")
{
	# add /Library/QuickTimeStreaming/AdminHtml to INC so that it can find SSLeay.bundle
	push(@INC, "/Library/QuickTimeStreaming/AdminHtml");
}

eval "use Net::SSLeay";

$ssl_available = 0;
if (!$@) {
	$use_ssl = 1;
	$ssl_available = 1; # can be set to 0 if a valid cert isn't present
						# this check is done after the config is read in
	# These functions only exist for SSLeay 1.0
	eval "Net::SSLeay::SSLeay_add_ssl_algorithms()";
	eval "Net::SSLeay::load_error_strings()";
	if (defined(&Net::SSLeay::X509_STORE_CTX_get_current_cert) &&
	    defined(&Net::SSLeay::CTX_load_verify_locations) &&
	    defined(&Net::SSLeay::CTX_set_verify)) {
		$client_certs = 1;
	}
}
	
# Get streamingadminserver's perl path and location
$streamingadminserver_path = $0;
open(SOURCE, $streamingadminserver_path);
<SOURCE> =~ /^#!(\S+)/; $perl_path = $1;
close(SOURCE);
@streamingadminserver_argv = @ARGV;

if($^O eq "MSWin32") {
	$defaultConfigPath = "C:/Program Files/Darwin Streaming Server/streamingadminserver.conf";
}
elsif($^O eq "darwin") {
        $defaultConfigPath = "/Library/QuickTimeStreaming/Config/streamingadminserver.conf";
}
else {
	$defaultConfigPath = "/etc/streaming/streamingadminserver.conf";
}

$debug = 0;
# Find and read config file
if (@ARGV < 1) {
    $conf = $defaultConfigPath;
}
elsif(@ARGV == 1) {
    if($ARGV[0] eq "-d") {
	$conf = $defaultConfigPath;
	$debug = 1;
    }
    else {
	&usage($defaultConfigPath);
	exit;
    }
}
elsif(@ARGV == 2) {
    if(($ARGV[0] eq "-cd") || ($ARGV[0] eq "-dc")) {
	$debug = 1;
    }
    elsif($ARGV[0] ne "-c") {
	&usage($defaultConfigPath);
	exit;
    }
    if($^O eq "MSWin32") {
	    $conf = $ARGV[1];
	}
    else {
	if ($ARGV[1] =~ /^\//) {
	    $conf = $ARGV[1];
	}
	else {
	    chop($pwd = `pwd`);
	    $conf = "$pwd/$ARGV[1]";
	}
    }
}
else {
	&usage($defaultConfigPath);
    exit;
}

if(!open(CONF, $conf)) {
	if($conf ne $defaultConfigPath) {
		die "Failed to open config file $conf : $!";
	}
} else {
	while(<CONF>) {
	    chomp;
	    if (/^#/ || !/\S/) { 
			next; 
	    }
	    /^([^=]+)=(.*)$/;
	    $name = $1; $val = $2;
	    $name =~ s/^\s+//g; $name =~ s/\s+$//g;
	    $val =~ s/^\s+//g; $val =~ s/\s+$//g;
	    $config{$name} = $val;
	}
	close(CONF);
}

# Check vital config options
if($^O eq "darwin") {
	%vital = ("port", 1220,
	  "sslport", 1240,
	  "root", "/Library/QuickTimeStreaming/AdminHtml",
      "plroot", "/Library/QuickTimeStreaming/Playlists/",
	  "server", "QTSS 5.5 Admin Server/1.0",
	  "index_docs", "index.html parse_xml.cgi index.htm index.cgi",
	  "addtype_html", "text/html",
	  "addtype_htm", "text/html",
	  "addtype_txt", "text/plain",
	  "addtype_gif", "image/gif",
	  "addtype_jpg", "image/jpeg",
	  "addtype_jpeg", "image/jpeg",
	  "addtype_cgi", "internal/cgi",
	  "addtype_mov", "video/quicktime",
	  "addtype_js", "application/x-javascript",
	  "realm", "QTSS Admin Server",
	  "qtssIPAddress", "localhost",
	  "qtssPort", "554",
	  "qtssName", "/usr/sbin/QuickTimeStreamingServer",
	  "qtssAutoStart", "0",
	  "logfile", "/Library/QuickTimeStreaming/Logs/streamingadminserver.log",
	  "log", "1",
	  "logclear", "0",
	  "logtime", "168",
	  "messagesfile", "messages",
	  "gbrowse", "0",
	  "ssl", "0",
	  "crtfile", "/Library/QuickTimeStreaming/Config/streamingadminserver.pem",
	  "keyfile", "/Library/QuickTimeStreaming/Config/streamingadminserver.pem",
	  #"keypasswordfile", "",
	  "qtssQTPasswd", "/usr/bin/qtpasswd",
	  "qtssPlaylistBroadcaster", "/usr/bin/PlaylistBroadcaster",
	  "qtssMP3Broadcaster", "/usr/bin/MP3Broadcaster",
	  "tempfileloc", "/tmp",
	  "helpurl", "http://helpqt.apple.com/qtssWebAdminHelpR2/qtssWebAdmin.help/English.lproj/index.html",
	  "qtssAdmin", "streamingadmin", 
	  "cacheMessageFiles", "0",
	  "pidfile", "/var/run/streamingadminserver.pid",
	  "runUser", "qtss",
	  "runGroup", "qtss",
	  "cookieExpireSeconds", "600"
	  );
}
elsif($^O eq "MSWin32") {
	%vital = ("port", 1220,
	  "sslport", 1240,
	  "root", "C:/Program Files/Darwin Streaming Server/AdminHtml",
	  "plroot", "C:\\Program Files\\Darwin Streaming Server\\Playlists\\",
	  "server", "QTSS 5.5 Admin Server/1.0",
	  "index_docs", "index.html parse_xml.cgi index.htm index.cgi",
	  "addtype_html", "text/html",
      "addtype_htm", "text/html",
	  "addtype_txt", "text/plain",
	  "addtype_gif", "image/gif",
	  "addtype_jpg", "image/jpeg",
	  "addtype_jpeg", "image/jpeg",
	  "addtype_cgi", "internal/cgi",
	  "addtype_mov", "video/quicktime",
	  "addtype_js", "application/x-javascript",
	  "realm", "QTSS Admin Server",
	  "qtssIPAddress", "localhost",
	  "qtssPort", "554",
	  "qtssName", "C:/Program Files/Darwin Streaming Server/DarwinStreamingServer.exe",
	  "qtssAutoStart", "1",
      "logfile", "C:/Program Files/Darwin Streaming Server/Logs/streamingadminserver.log",
	  "log", "1",
	  "logclear", "0",
	  "logtime", "168",
	  "messagesfile", "messages",
	  "gbrowse", "0",
	  "ssl", "0",
	  "crtfile", "C:/Program Files/Darwin Streaming Server/streamingadminserver.pem",
	  "keyfile", "C:/Program Files/Darwin Streaming Server/streamingadminserver.pem",
	  #"keypasswordfile", "",
	  "qtssQTPasswd", "C:/Program Files/Darwin Streaming Server/qtpasswd.exe",
	  "qtssPlaylistBroadcaster", "c:\\Program Files\\Darwin Streaming Server\\PlaylistBroadcaster.exe",
	  "qtssMP3Broadcaster", "c:\\Program Files\\Darwin Streaming Server\\MP3Broadcaster.exe",
	  "helpurl", "http://helpqt.apple.com/dssWebAdminHelpR3/dssWebAdmin.help/DSSHelp.htm",
	  "qtssAdmin", "streamingadmin",
  	  "cacheMessageFiles", "0",
	  #"pidfile", "C:/Program Files/Darwin Streaming Server/streamingadminserver.pid"
	  );
}
else {
	%vital = ("port", 1220,
	  "sslport", 1240,
	  "root", "/var/streaming/AdminHtml",
      "plroot", "/var/streaming/playlists/",
	  "server", "DSS 5.5 Admin Server/1.0",
	  "index_docs", "index.html parse_xml.cgi index.htm index.cgi",
	  "addtype_html", "text/html",
      "addtype_htm", "text/html",
	  "addtype_txt", "text/plain",
	  "addtype_gif", "image/gif",
	  "addtype_jpg", "image/jpeg",
	  "addtype_jpeg", "image/jpeg",
	  "addtype_cgi", "internal/cgi",
	  "addtype_mov", "video/quicktime",
	  "addtype_js", "application/x-javascript",
	  "realm", "DSS Admin Server",
	  "qtssIPAddress", "localhost",
	  "qtssPort", "554",
	  "qtssName", "/usr/local/sbin/DarwinStreamingServer",
      "qtssAutoStart", "1",
	  "logfile", "/var/streaming/logs/streamingadminserver.log",
	  "log", "1",
	  "logclear", "0",
	  "logtime", "168",
	  "messagesfile", "messages",
	  "gbrowse", "0",
	  "ssl", "0",
	  "crtfile", "/etc/streaming/streamingadminserver.pem",
	  "keyfile", "/etc/streaming/streamingadminserver.pem",
	  #"keypasswordfile", "",
	  "qtssQTPasswd", "/usr/local/bin/qtpasswd",
	  "qtssPlaylistBroadcaster", "/usr/local/bin/PlaylistBroadcaster",
	  "qtssMP3Broadcaster", "/usr/local/bin/MP3Broadcaster",
	  "helpurl", "http://helpqt.apple.com/dssWebAdminHelpR3/dssWebAdmin.help/DSSHelp.htm",
	  "tempfileloc", "/tmp",
	  "qtssAdmin", "streamingadmin",
	  "cacheMessageFiles", "0",
	  "pidfile", "/var/run/streamingadminserver.pid",
	  "runUser", "qtss",
	  "runGroup", "qtss",
	  "cookieExpireSeconds", "600"
	  );
}

foreach $v (keys %vital) {
	if ((!defined($config{$v})) || ($config{$v} eq "")) {
		if ($vital{$v} eq "") {
		    die "Missing config option $v";
		}
		$config{$v} = $vital{$v};
	}
}

# Check if valid ssl cert and key files are present
# if not, then set $ssl_available to 0
# For now, just check for the existance of the files
if(($config{'crtfile'} eq "") || ($config{'keyfile'} eq "") || !(-e $config{'crtfile'}) || !(-e $config{'keyfile'}) )
{
	$ssl_available = 0;
}

if($config{'qtssIPAddress'} eq "localhost") {
	$config{'qtssIPAddress'} = inet_ntoa(INADDR_LOOPBACK);
}

$passwordfile = $config{'keypasswordfile'};
$keypassword = "";
if(defined($passwordfile) && ($passwordfile ne ""))
{
	if(open(PASSFILE, $passwordfile)) {
		read(PASSFILE, $keypassword, -s $passwordfile);
		close(PASSFILE);
	}
}

# init days and months for http_date
@weekday = ( "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" );
@month = ( "Jan", "Feb", "Mar", "Apr", "May", "Jun",
	   "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" );

# Change dir to the server root
chdir($config{'root'});
if ($^O ne "MSWin32") {
    $user_homedir = (getpwuid($<))[7];
}

# Read users file
#if ($config{'userfile'}) {
#	open(USERS, $config{'userfile'});
#	while(<USERS>) {
#		s/\r|\n//g;
#		local @user = split(/:/, $_);
#		$users{$user[0]} = $user[1];
#		$certs{$user[0]} = $user[3] if ($user[3]);
#		if ($user[4] =~ /^allow\s+(.*)/) {
#			$allow{$user[0]} = [ &to_ipaddress(split(/\s+/, $1)) ];
#		}
#		elsif ($user[4] =~ /^deny\s+(.*)/) {
#			$deny{$user[0]} = [ &to_ipaddress(split(/\s+/, $1)) ];
#		}
#	}
#	close(USERS);
#}

# Setup SSL if possible and if requested
# Setup SSL no matter what -
# otherwise dynamic switching between
# http and https won't work!

if (!$config{'ssl'}) { $use_ssl = 0; }
if ($ssl_available) {
	$ssl_ctx = Net::SSLeay::CTX_new() ||
		die "Failed to create SSL context : $!";
	$client_certs = 0 if (!$config{'ca'} || !%certs);
	if ($client_certs) {
		Net::SSLeay::CTX_load_verify_locations(
			$ssl_ctx, $config{'ca'}, "");
		Net::SSLeay::CTX_set_verify(
			$ssl_ctx, &Net::SSLeay::VERIFY_PEER, \&verify_client);
		}
	}

## Read MIME types file and add extra types
#if ($config{"mimetypes"} ne "") {
#    open(MIME, $config{"mimetypes"});
#    while(<MIME>) {
#	 	chop;
#		/^(\S+)\s+(.*)$/;
#		$type = $1; @exts = split(/\s+/, $2);
#		foreach $ext (@exts) {
#		    $mime{$ext} = $type;
#		}
#    }
#    close(MIME);
#}

foreach $k (keys %config) {
    if ($k !~ /^addtype_(.*)$/) { next; }
    $mime{$1} = $config{$k};
}

# get the time zone
if ($config{'log'}) {
	local(@gmt, @lct, $days, $hours, $mins);
	@make_date_marr = ("Jan", "Feb", "Mar", "Apr", "May", "Jun",
		 	   "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
	@gmt = gmtime(time());
	@lct = localtime(time());
	$days = $lct[3] - $gmt[3];
	$hours = ($days < -1 ? 24 : 1 < $days ? -24 : $days * 24) +
		 $lct[2] - $gmt[2];
	$mins = $hours * 60 + $lct[1] - $gmt[1];
	$timezone = ($mins < 0 ? "-" : "+"); $mins = abs($mins);
	$timezone .= sprintf "%2.2d%2.2d", $mins/60, $mins%60;
	}


%messagesfile = ();
%messages = ();
# load immediately
&LoadMessageHashes();

# find the user IDs and group IDs
# if they aren't found, bail
if ($^O ne "MSWin32")
{
    $runGroup = $config{"runGroup"};
    
    if (defined($runGroup) && ($runGroup ne ""))
    {
        if (!($gid = getgrnam($runGroup)))
		{
            print "Cannot switch to group $runGroup\n";
            exit;
		}
    }    

    $runUser = $config{"runUser"};
    if (defined($runUser) && ($runUser ne ""))
    {
        if (!($uid = getpwnam($runUser)))
		{
            print "Cannot switch to user $runUser\n";
            exit;
		}
    }  
}

if($config{'qtssAutoStart'} == 1) {
# check if the streaming server is running by trying to connect
# to it. If the server doesn't respond, look for the name of the 
# streaming server binary in the config file and start it

	if(!($iaddr = inet_aton($config{'qtssIPAddress'}))) { 
		if($debug) {
	   		print "No host: $config{'qtssIPAddress'}\n";
		}
	}
	$paddr = sockaddr_in($config{'qtssPort'}, $iaddr);
	$proto = getprotobyname('tcp');
	if(!socket(TEST_SOCK, PF_INET, SOCK_STREAM, $proto)) {
    	if($debug) {
			print "Couldn't create socket to connect to the Streaming Server: $!\n";
    	}
	}
	if(!connect(TEST_SOCK, $paddr)) {
    	if($debug) {
			print "Couldn't connect to the Streaming Server at $config{'qtssIPAddress'} "
			    . " on port $config{'qtssPort'}\n";
			if($^O eq "MSWin32") {
		    	print "Please start Darwin Streaming Server from the Service Manager\n";
			}
			else {
	    		print "Launching Streaming Server...\n";
			}
    	}

	    $prog = $config{'qtssName'};
	    if($^O ne "MSWin32") {
	        unless (fork()) {
		    	unless (fork()) {
		    		close(MAIN);
		    		close(SSLMAIN);
					exec($prog);
					exit 0;
		    	}
		    	exit 0;
			}
    	}
	    else {
			#eval "require Win32::Service";
			#if($@) {
			#	print "Win32::Service module not installed.\n"
			#		. "Cannot launch the Streaming Server from the admin server\n";
			#}
			#else {
			#	Win32::Service::StartService(NULL, "Darwin Streaming Server");
			#}
    	}
	}
	close(TEST_SOCK);
}

# once the config options are read in
# and the local QTSS is started up
# start playlists that died due to a crash/reboot
my $startplaylists = "";
if (($config{'root'} !~ /\/$/) && ($config{'root'} !~ /\\$/))
{
    if ($^O eq "MSWin32")
    {
	$startplaylists = $config{'root'} . "\\startplaylists.pl";
    }
    else
    {
	$startplaylists = $config{'root'} . "/startplaylists.pl";
    }
}
else
{
    $startplaylists = $config{'root'} . "startplaylists.pl";
}
if ($debug)
{
    print "Running the startplaylists.pl script at $startplaylists\n";
}

do $startplaylists;

# For darwin platforms (other than Win32)
if(($^O ne "MSWin32") && ($^O ne "darwin")) {
	if ($config{'inetd'}) {
		# We are being run from inetd - go direct to handling the request
		$SIG{'HUP'} = 'IGNORE';
		$SIG{'TERM'} = 'DEFAULT';
		$SIG{'PIPE'} = 'DEFAULT';
		open(SOCK, "+>&STDIN");

		# Check if it is time for the logfile to be cleared
		if ($config{'logclear'}) {
			local $write_logtime = 0;
			local @st = stat("$config{'logfile'}.time");
			if (@st) {
				if ($st[9]+$config{'logtime'}*60*60 < time()){
					# need to clear log
					$write_logtime = 1;
					unlink($config{'logfile'});
				}
			}
			else { $write_logtime = 1; }
			if ($write_logtime) {
				open(LOGTIME, ">$config{'logfile'}.time");
				print LOGTIME time(),"\n";
				close(LOGTIME);
			}
		}

		# Initialize SSL for this connection if request came in on ssl port
		($myport, $myaddr) = unpack_sockaddr_in(getsockname(SOCK));
		if($myport == $config{'sslport'})
		{ 
			$sslrequest == 1;
		}
		else
		{	
			$sslrequest = 0;
		}

		#check ssl config for each request
		#$use_ssl = &check_sslconfig($conf, $use_ssl, $ssl_available);

		if ($sslrequest && $ssl_available) {
			$ssl_con = Net::SSLeay::new($ssl_ctx);
			Net::SSLeay::set_fd($ssl_con, fileno(SOCK));
			if($keypassword ne "")
			{
				Net::SSLeay::CTX_set_default_passwd_cb($ssl_ctx, \&pem_passwd_cb);
				#Net::SSLeay::SSL_CTX_set_default_passwd_cb_userdata($ssl_ctx, \$keypassword);
			}
			Net::SSLeay::use_RSAPrivateKey_file(
				$ssl_con, $config{'keyfile'},
				&Net::SSLeay::FILETYPE_PEM);
			Net::SSLeay::use_certificate_file(
				$ssl_con, $config{'crtfile'},
				&Net::SSLeay::FILETYPE_PEM);
			Net::SSLeay::accept($ssl_con) || exit;
	       }

		# Work out the hostname for this web server
		if (!$config{'host'}) {
			($myport, $myaddr) =
				unpack_sockaddr_in(getsockname(SOCK));
			$myname = gethostbyaddr($myaddr, AF_INET);
			if ($myname eq "") {
				$myname = inet_ntoa($myaddr);
			}
			$host = $myname;
		}
		else { $host = $config{'host'}; }
		$port = $config{'port'};
		$sslport = $config{'sslport'};
		
		while(&handle_request(getpeername(SOCK))) { }
		close(SOCK);
		exit;
	}
}
	
# Open main socket
$proto = getprotobyname('tcp');
$baddr = $config{"bind"} ? inet_aton($config{"bind"}) : INADDR_ANY;
$port = $config{"port"};
$servaddr = sockaddr_in($port, $baddr);
socket(MAIN, PF_INET, SOCK_STREAM, $proto) ||
	die "Failed to open listening socket for Streaming Admin Server : $!\n";
setsockopt(MAIN, SOL_SOCKET, SO_REUSEADDR, pack("l", 1));
bind(MAIN, $servaddr) || die "Failed to start Streaming Admin Server.\n"
								. "Port $config{port} is in use by another process.\n"
								. "The Streaming Admin Server may already be running.\n";  

listen(MAIN, SOMAXCONN) || die "Failed to listen on socket for Streaming Admin Server: $!\n";


# open another listening socket for ssl requests
# only do this if the Net::SSLeay module is available
if ($ssl_available)
{
	$sslport = $config{"sslport"};
	$servssladdr = sockaddr_in($sslport, $baddr);
	socket(SSLMAIN, PF_INET, SOCK_STREAM, $proto) ||
		die "Failed to open ssl listening socket for Streaming Admin Server : $!\n";
	setsockopt(SSLMAIN, SOL_SOCKET, SO_REUSEADDR, pack("l", 1));
	bind(SSLMAIN, $servssladdr) || die "Failed to start Streaming Admin Server.\n"
									. "SSL Port $config{port} is in use by another process.\n"
									. "The Streaming Admin Server may already be running.\n";  

	# if sslport = 0, then get the port we actually bound to
	# so that we can redirect to the right port later
	if ($sslport == 0)
	{
		$sslsockaddr = getsockname(SSLMAIN);
		($sslport, $ssladdr) = unpack_sockaddr_in($sslsockaddr);

	}
	
	listen(SSLMAIN, SOMAXCONN) || die "Failed to listen on socket for Streaming Admin Server: $!\n";
}


# Split from the controlling terminal
if (($^O ne "MSWin32") && ($debug == 0)) {
    if (fork()) {
		exit;
    }
    setsid();
    open(STDIN, '>/dev/null');
    open(STDOUT, '>/dev/null');
    open(STDERR, '>/dev/null');
}

# write out the PID file
# Not used for NT
if(defined($config{'pidfile'}) && ($config{'pidfile'} ne "")) { $write_pid = 1; }
if (($^O ne "MSWin32") && ($write_pid == 1))  {
    open(PIDFILE, "> $config{'pidfile'}");
    printf PIDFILE "%d\n", getpid();
    close(PIDFILE);
}

# Switch to specfied user and/or group in the config
if ($^O ne "MSWin32")
{   
    if (defined($runGroup) && ($runGroup ne ""))
    {
		$) = $gid;
		$( = $gid;
    }    

    if (defined($runUser) && ($runUser ne ""))
    {
		$> = $uid;
		$< = $uid;
    }  
}

# Start the log-clearing process, if needed. This checks every minute
# to see if the log has passed its reset time, and if so clears it
if ($^O ne "MSWin32") {
    if ($config{'logclear'}) {
		if (!($logclearer = fork())) {
	    	while(1) {
				$write_logtime = 0;
				if (open(LOGTIME, "$config{'logfile'}.time")) {
		    		<LOGTIME> =~ /(\d+)/;
		    		close(LOGTIME);
		    		if ($1 && $1+$config{'logtime'}*60*60 < time()){
						# need to clear log
						$write_logtime = 1;
						unlink($config{'logfile'});
		    		}
				}
				else { $write_logtime = 1; }
				if ($write_logtime) {
		    		open(LOGTIME, ">$config{'logfile'}.time");
		    		print LOGTIME time(),"\n";
		    		close(LOGTIME);
				}
				sleep(5*60);
	    	}
	    	exit;
		}
		push(@childpids, $logclearer);
    }
}

# Run the main loop
if ($^O ne "MSWin32") {
	$SIG{'CHLD'} = 'streamingadminserver::reaper';
    $SIG{'TERM'} = 'streamingadminserver::term_handler';
    $SIG{'HUP'} = 'streamingadminserver::trigger_restart';
}
$SIG{'PIPE'} = 'IGNORE';
@deny = &to_ipaddress(split(/\s+/, $config{"deny"}));
@allow = &to_ipaddress(split(/\s+/, $config{"allow"}));
$p = 0;
while(1) {
    # wait for a new connection, or a message from a child process
    undef($rmask);
    vec($rmask, fileno(MAIN), 1) = 1;
    # add ssl socket to select mask
    # only do this if the Net::SSLeay module is available
    if ($ssl_available)
    {
    	vec($rmask, fileno(SSLMAIN), 1) = 1;
    }
    
    if($^O ne "MSWin32") {
		if ($config{'passdelay'}) {
	    	for($i=0; $i<@passin; $i++) {
				vec($rmask, fileno($passin[$i]), 1) = 1;
	    	}
		}
    }

    local $sel = select($rmask, undef, undef, 10);
    if ($need_restart) { &restart_streamingadminserver(); }
    
    #if($^O ne "MSWin32") {
	#	# Clean up finished processes
	#	local($pid);
	#	do {
	#    	$pid = waitpid(-1, WNOHANG);
	#    	print "reaped child $pid\n";
	#    	@childpids = grep { $_ != $pid } @childpids;
	#		print "remaining children @childpids\n";
	#	} while($pid > 0);
    #}

    next if ($sel <= 0);
    $nonsslrequest = 0;
    $sslrequest = 0;
    
    if($ssl_available)
    {
	    if (vec($rmask, fileno(MAIN), 1)) { $nonsslrequest = 1; $sslrequest = 0; }
    	elsif (vec($rmask, fileno(SSLMAIN), 1)) { $nonsslrequest = 0; $sslrequest = 1; }
    }
    else
    {
    	 if (vec($rmask, fileno(MAIN), 1)) { $nonsslrequest = 1; }
    	 $sslrequest = 0;	# if ssl request isn't avaiable, sslrequest will always be zero
    }
    
    if ($nonsslrequest || $sslrequest) {
		# got new connection
		if($nonsslrequest)
		{
			$acptaddr = accept(SOCK, MAIN);
		}
		elsif($sslrequest)
		{
			$acptaddr = accept(SOCK, SSLMAIN);
		}
		if (!$acptaddr) { next; }
		
		if($^O ne "MSWin32") {
	    	# create pipes
	    	if ($config{'passdelay'}) {
				$PASSINr = "PASSINr$p"; $PASSINw = "PASSINw$p";
				$PASSOUTr = "PASSOUTr$p"; $PASSOUTw = "PASSOUTw$p";
				$p++;
				pipe($PASSINr, $PASSINw);
				pipe($PASSOUTr, $PASSOUTw);
				select($PASSINw); $| = 1; select($PASSINr); $| = 1;
				select($PASSOUTw); $| = 1; select($PASSOUTw); $| = 1;
		 	}
		}
	
		select(SOCK); $| = 1;
		select(STDOUT);

		if($^O eq "MSWin32") {
			#check ssl config for each request
			#$use_ssl = &check_sslconfig($conf, $use_ssl, $ssl_available);
				
			# Initialize SSL for this connection
			if ($sslrequest && $ssl_available) {
				$ssl_con = Net::SSLeay::new($ssl_ctx);
				Net::SSLeay::set_fd($ssl_con, fileno(SOCK));
				if($keypassword ne "")
				{
					Net::SSLeay::CTX_set_default_passwd_cb($ssl_ctx, \&pem_passwd_cb);
					#Net::SSLeay::SSL_CTX_set_default_passwd_cb_userdata($ssl_ctx, \$keypassword);
				}
				Net::SSLeay::use_RSAPrivateKey_file(
					$ssl_con, $config{'keyfile'},
					&Net::SSLeay::FILETYPE_PEM);
				Net::SSLeay::use_certificate_file(
					$ssl_con, $config{'crtfile'},
					&Net::SSLeay::FILETYPE_PEM);
				Net::SSLeay::accept($ssl_con) || next;
			}
		
		    # Work out the hostname for this web server
		    if (!$config{'host'}) {
				($myport, $myaddr) =
			    	unpack_sockaddr_in(getsockname(SOCK));
				$myname = gethostbyaddr($myaddr, AF_INET);
				if ($myname eq "") {
				    $myname = inet_ntoa($myaddr);
				}
				$host = $myname;
		    }
		    else { $host = $config{'host'}; }
	    
		    while(&handle_request($acptaddr)) { }
		    shutdown(SOCK, 1);
	    	close(SOCK);
		}
		else {
		    # fork the subprocess
		    if (!($handpid = fork())) {
				# setup signal handlers
				$SIG{'TERM'} = 'DEFAULT';
				$SIG{'PIPE'} = 'DEFAULT';
				#$SIG{'CHLD'} = 'IGNORE';
				$SIG{'HUP'} = 'IGNORE';
				
				#check ssl config for each request
				#$use_ssl = &check_sslconfig($conf, $use_ssl, $ssl_available);
				
				# Initialize SSL for this connection
				if ($sslrequest && $ssl_available) {
					$ssl_con = Net::SSLeay::new($ssl_ctx);
					Net::SSLeay::set_fd($ssl_con, fileno(SOCK));
					if($keypassword ne "")
					{
						Net::SSLeay::CTX_set_default_passwd_cb($ssl_ctx, \&pem_passwd_cb);
						#Net::SSLeay::SSL_CTX_set_default_passwd_cb_userdata($ssl_ctx, \$keypassword);
					}
					Net::SSLeay::use_RSAPrivateKey_file(
						$ssl_con, $config{'keyfile'},
						&Net::SSLeay::FILETYPE_PEM);
					Net::SSLeay::use_certificate_file(
						$ssl_con, $config{'crtfile'},
						&Net::SSLeay::FILETYPE_PEM);
					Net::SSLeay::accept($ssl_con) || exit;
				}
				
				# close useless pipes
				if ($config{'passdelay'}) {
				    foreach $p (@passin) { close($p); }
				    foreach $p (@passout) { close($p); }
				    close($PASSINr); close($PASSOUTw);
				}
				close(MAIN);
				close(SSLMAIN);
		
				# Work out the hostname for this web server
				if (!$config{'host'}) {
				    ($myport, $myaddr) =
						unpack_sockaddr_in(getsockname(SOCK));
				    $myname = gethostbyaddr($myaddr, AF_INET);
				    if ($myname eq "") {
						$myname = inet_ntoa($myaddr);
				    }
		    		$host = $myname;
				}
				else { $host = $config{'host'}; }
				while(&handle_request($acptaddr)) { }
				shutdown(SOCK, 1);
				close(SOCK);
				close($PASSINw); close($PASSOUTw);
				exit;
	    	}
		    push(@childpids, $handpid);
		    if ($config{'passdelay'}) {
				close($PASSINw); close($PASSOUTr);
				push(@passin, $PASSINr); push(@passout, $PASSOUTw);
	    	}
	    	close(SOCK);
		}
    }

    if($^O ne "MSWin32") {
		# check for password-timeout messages from subprocesses
		for($i=0; $i<@passin; $i++) {
		    if (vec($rmask, fileno($passin[$i]), 1)) {
				# this sub-process is asking about a password
				$infd = $passin[$i]; $outfd = $passout[$i];
				if (<$infd> =~ /^(\S+)\s+(\S+)\s+(\d+)/) {
				    # Got a delay request from a subprocess.. for
		    		# valid logins, there is no delay (to prevent
		    		# denial of service attacks), but for invalid
		    		# logins the delay increases with each failed
		    		# attempt.
		    		#print STDERR "got $1 $2 $3\n";
		    		if ($3) {
						# login OK.. no delay
						print $outfd "0\n";
				    }
				    else {
						# login failed.. 
						$dl = $userdlay{$1} -
					    int((time() - $userlast{$1})/50);
						$dl = $dl < 0 ? 0 : $dl+1;
						print $outfd "$dl\n";
						$userdlay{$1} = $dl;
		    		}
		   			$userlast{$1} = time();
				}
				else {
				    # close pipe
				    close($infd); close($outfd);
				    $passin[$i] = $passout[$i] = undef;
				}
	    	}
		}
		@passin = grep { defined($_) } @passin;
		@passout = grep { defined($_) } @passout;
	}
}

# usage
sub usage
{
    printf("Usage: streamingadminserver.pl [-cd] [configfilepath]\n");
    printf("    Command                                           How it works\n");
    printf("    -------                                           ------------\n");
    printf("1. streamingadminserver.pl                           uses default config file\n");
    printf("                                                     if found at $_[0]\n");
    printf("                                                     else uses internal defaults\n");
    printf("2. streamingadminserver.pl -d                        uses default config as above\n");
    printf("                                                     and runs in debug mode\n");
    printf("3. streamingadminserver.pl -c  xyzfilepath           uses config file at 'xyzfilepath'\n");
    printf("4. streamingadminserver.pl -dc  xyzfilepath          like 3. above and runs in debug mode\n");
    printf("5. streamingadminserver.pl -cd  xyzfilepath          like 3. above and runs in debug mode\n");
}

# check_sslconfig(configfilename, defaultvalue, sslavailable)
# reread the config file to check if 
# ssl is on or off and return 0/1
# if file doesn't exist, return the default value
# if openssl isn't available on the OS, then return 0
sub check_sslconfig
{
	my $configfilename = $_[0];
	my $sslValue = $_[1];
	my $available = $_[2];
	my $name, $val;
	
	# if openssl isn't available on os, check_sslconfig
	# always returns 0
	if($available == 0)
	{
	    $sslValue = 0;
	    return $sslValue;
	}
	
	if(open(CONF, $configfilename))
	{
		while(<CONF>)
		{
		    chomp;
	    	if (/^#/ || !/\S/)
	    	{ 
				next; 
	    	}
	    	/^([^=]+)=(.*)$/;
	    	$name = $1; $val = $2;
	    	$name =~ s/^\s+//g; $name =~ s/\s+$//g;
	    	$val =~ s/^\s+//g; $val =~ s/\s+$//g;
	    	if ($name eq "ssl")
	    	{
	    		if ($val == 1)
	    		{
	    			$sslValue = 1;
	    		}
	    		else
	    		{
	    			$sslValue = 0;
	    		}
	    		last;
	    	}
		}
		close(CONF);
	}
	
	return $sslValue;
}

# handle_request(clientaddress)
# Where the real work is done
sub handle_request
{
	if ($config{"cacheMessageFiles"} eq "0") {
		&LoadMessageHashes();
	}
    $acptip = inet_ntoa((unpack_sockaddr_in($_[0]))[1]);  
    $datestr = &http_date(time());
    # Read the HTTP request and headers
    ($reqline = &read_line()) =~ s/\r|\n//g;
    if (!($reqline =~ /^(GET|POST|HEAD)\s+(.*)\s+HTTP\/1\..$/)) {
		&http_error(400, "Bad Request");
    }
    $method = $1; $request_uri = $page = $2;
    
    $use_ssl = &check_sslconfig($conf, $use_ssl, $ssl_available);
    
     
    # if request came over non-ssl port but ssl is on
    # redirect to the ssl request
    if(!$sslrequest && $use_ssl) { &http_redirect(1, $host, $sslport, $request_uri); }
    
    # if request came over ssl port but ssl is off
    # redirect to non-ssl request
    if($sslrequest && !$use_ssl) { &http_redirect(0, $host, $port, $request_uri); }
	
    %header = ();
    local $lastheader;
	while(1) {
		($headline = &read_line()) =~ s/\r|\n//g;
		last if ($headline eq "");
		if ($headline =~ /^(\S+):\s+(.*)$/) {
			$header{$lastheader = lc($1)} = $2;
		}
		elsif ($headline =~ /^\s+(.*)$/) {
			$header{$lastheader} .= $headline;
		}
		else {
			&http_error(400, "Bad Header $headline");
		}
	}
    if (defined($header{'host'})) {
		if ($header{'host'} =~ /^([^:]+):([0-9]+)$/) { 
	    	$host = $1; 
	    	$port = $2; 
		}
		else { $host = $header{'host'}; }
    }
    
    # Set defaults so that english html can be sent if the accept-language header is not given
    my $langDir = $config{"root"} . "/html_en";
    my $language = "en";
    
    if (defined($header{'accept-language'})) {
		@langArr =	split /,/ , $header{'accept-language'};
	    if($langArr[0] =~ m/^de/) {
	    	$langDir = $config{"root"} . "/html_de";
	    	$language = "de";
	    }
	    elsif($langArr[0] =~ m/^fr/) {
	    	$langDir = $config{"root"} . "/html_fr";
	    	$language = "fr";
	    }
	    elsif($langArr[0] =~ m/^ja/) {
	    	$langDir = $config{"root"} . "/html_ja";
	    	$language = "ja";
	    }
		else { 
			$langDir = $config{"root"} . "/html_en"; 
			$language = "en";
		}
    }
    
    $querystring = '';
    
    undef(%in);
    if ($page =~ /^([^\?]+)\?(.*)$/) {
		# There is some query string information
		$page = $1;
		$querystring = $2;
		if ($querystring !~ /=/) {
	    	$queryargs = $querystring;
	    	$queryargs =~ s/\+/ /g;
	    	$queryargs =~ s/%(..)/pack("c",hex($1))/ge;
	    	$querystring = "";
		}
		else {
			# Parse query-string parameters
			local @in = split(/\&/, $querystring);
			foreach $i (@in) {
				local ($k, $v) = split(/=/, $i, 2);
				$k =~ s/\+/ /g; $k =~ s/%(..)/pack("c",hex($1))/ge;
				$v =~ s/\+/ /g; $v =~ s/%(..)/pack("c",hex($1))/ge;
				$in{$k} = $v;
			}
		}
    }

	$posted_data = undef;
	if ($method eq 'POST' &&
    	$header{'content-type'} eq 'application/x-www-form-urlencoded') 
    {
		# Read in posted query string information
		$clen = $header{"content-length"};
		while(length($posted_data) < $clen) 
		{
			$buf = &read_data($clen - length($posted_data));
			if (!length($buf)) {
				&http_error(500, "Failed to read POST request");
			}
			$posted_data .= $buf;
		}
		local @in = split(/\&/, $posted_data);
		foreach $i (@in) 
		{
			local ($k, $v) = split(/=/, $i, 2);
			$k =~ s/\+/ /g; $k =~ s/%(..)/pack("c",hex($1))/ge;
			$v =~ s/\+/ /g; $v =~ s/%(..)/pack("c",hex($1))/ge;
			$in{$k} = $v;
		}
	}
	
    # strip NULL characters %00 from the request
    $page =~ s/%00//ge;

    # replace %XX sequences in page
    $page =~ s/%(..)/pack("c",hex($1))/ge;
  
	# delete multiple dots
	while ($page =~ m/\.{2,}/) {
		$page =~ s/\.{2,}/\./;
	}
	
	# must have a MIME type
	if ($page =~ /\.(.+)$/) {
		if ($mime{$1} eq '') {
			$page = '/';
		}
	}
	else {
		$page = '/';
	}
	
	#prevent windows ports from being opened
	#aux, con, prn, com*, lpt?, nul
	$superDir = $config{'root'};
	$foundFilename = 0;
	$lastPathComponent = '';
	if ($page =~ m/\/([^\/]+)$/) {
		$lastPathComponent = $1;
	}
	if (opendir(FILEDIR, $superDir)) {
		while (defined($subpath = readdir(FILEDIR))) {
			$foundFilename = 1 if $subpath eq $lastPathComponent;
		}
	}
	if ($foundFilename == 0 && opendir(FILEDIR, "$superDir/images")) {
		while (defined($subpath = readdir(FILEDIR))) {
			$foundFilename = 1 if $subpath eq $lastPathComponent;
		}
	}
	if ($foundFilename == 0 && opendir(FILEDIR, "$superDir/includes")) {
		while (defined($subpath = readdir(FILEDIR))) {
			$foundFilename = 1 if $subpath eq $lastPathComponent;
		}
	}
	$page = '/' if $foundFilename == 0;

    # check address against access list
    if (@deny && &ip_match($acptip, @deny) ||
		@allow && !&ip_match($acptip, @allow)) {
		&http_error(403, "Access denied for $acptip");
		return 0;
    }
    
    # check address against INADDR_LOOPBACK if we 
    # haven't gone past setup assistant yet
    if (&IsAllowedToSetup($config{'root'}, $acptip) == 0)
    {
    	&http_error(403, "Access denied for $acptip");
		return 0;
    }

    # check for the logout flag file, and if existant deny authentication once
    if ($config{'logout'} && -r $config{'logout'}) {
		&write_data("HTTP/1.0 401 Unauthorized\r\n");
		&write_data("Server: $config{server}\r\n");
		&write_data("Date: $datestr\r\n");
		&write_data("WWW-authenticate: Basic ".
			    "realm=\"$config{realm}\"\r\n");
		&write_data("Content-Type: text/html\r\n");
		&write_keep_alive(0);
		&write_data("\r\n");
		&reset_byte_count();
		&write_data("<html>\n<head>\n<title>Please Login</title>\n</head>\n");
		&write_data("<body>\n<h1>Please Login</h1>\n");
		&write_data("<p>Please login to the server as a new user.</p>\n</body>\n</html>\n");
		&log_request($acptip, undef, $reqline, 401, &byte_count());
		unlink($config{'logout'});
		return 0;
    }

    # Check for password if needed
    if (%users) {
		$validated = 0;
		
		# check for SSL authentication
		if ($sslrequest && $verified_client) {
			$peername = Net::SSLeay::X509_NAME_oneline(
					Net::SSLeay::X509_get_subject_name(
						Net::SSLeay::get_peer_certificate(
							$ssl_con)));
			foreach $u (keys %certs) {
				if ($certs{$u} eq $peername) {
					$authuser = $u;
					$validated = 2;
					last;
				}
			}
		}
	
		# Check for normal HTTP authentication
		if (!$validated && $header{authorization} =~ /^basic\s+(\S+)$/i) {
	    	# authorization given..
	    	($authuser, $authpass) = split(/:/, &b64decode($1));
	    	if($^O eq "MSWin32") {
				if ($authuser && ($users{$authuser} eq $authpass)) {
		    		$validated = 1;
				}
	    	}
	    	else {
				if ($authuser && $users{$authuser} && $users{$authuser} eq
		    				crypt($authpass, $users{$authuser})) {
		    		$validated = 1;
				}
	    	}
	    	#print STDERR "checking $authuser $authpass -> $validated\n";

	    	if($^O ne "MSWin32") {
				if ($config{'passdelay'} && !$config{'inetd'}) {
		    		# check with main process for delay
		    		print $PASSINw "$authuser $acptip $validated\n";
		    		<$PASSOUTr> =~ /(\d+)/;
		    		#print STDERR "sleeping for $1\n";
		    		sleep($1);
				}
	    	}
		}
		if (!$validated) {
		    # No password given.. ask
		    &write_data("HTTP/1.0 401 Unauthorized\r\n");
		    &write_data("Server: $config{'server'}\r\n");
		    &write_data("Date: $datestr\r\n");
		    &write_data("WWW-authenticate: Basic ".
				"realm=\"$config{'realm'}\"\r\n");
		    &write_data("Content-Type: text/html\r\n");
		    &write_keep_alive(0);
		    &write_data("\r\n");
		    &reset_byte_count();
		    &write_data("<html>\n<head>\n<title>Unauthorized</title>\n</head>\n");
		    &write_data("<body>\n<h1>Unauthorized</h1>\n");
		    &write_data("<p>A password is required to access this\n");
		    &write_data("web server. Please try again. </p>\n</body>\n</html>\n");
		    &log_request($acptip, undef, $reqline, 401, &byte_count());
	   		return 0;
		}

		# Check per-user IP access control
		if ($deny{$authuser} && &ip_match($acptip, @{$deny{$authuser}}) ||
			    $allow{$authuser} && !&ip_match($acptip, @{$allow{$authuser}})) {
			&http_error(403, "Access denied for $acptip");
			return 0;
		}	
    }
    
    # Figure out what kind of page was requested
    $simple = &simplify_path($page, $bogus);
    if ($bogus) {
		&http_error(400, "Invalid path");
    }
    $sofar = ""; $full = $config{"root"} . $sofar;
    $scriptname = $simple;
    foreach $b (split(/\//, $simple)) {
		if ($b ne "") { $sofar .= "/$b"; }
		$full = $config{"root"} . $sofar;
		@st = stat($full);
		if (!@st) {
			$full =  $langDir . $sofar;
			@st = stat($full);
			if(@st) {
				my $redirectUrl = "/html_" . "$language" . $sofar;
				&http_redirect($use_ssl, $host, $config{'port'}, $redirectUrl);
			}
			else{
				&http_error(404, "File not found"); 
			}
		}
	
		# Check if this is a directory
		if (-d $full) {
	    	# It is.. go on parsing
	    	next;
		}
	
		# Check if this is a CGI program
		if (&get_type($full) eq "internal/cgi") {
		    $pathinfo = substr($simple, length($sofar));
		    $pathinfo .= "/" if ($page =~ /\/$/);
	    	$scriptname = $sofar;
	    	last;
		}
    }

    # check filename against denyfile regexp
    local $denyfile = $config{'denyfile'};
    if ($denyfile && $full =~ /$denyfile/) {
		&http_error(403, "Access denied to $page");
		return 0;
    }

    # Reached the end of the path OK.. see what we've got
    if (-d $full) {
    	# See if the URL ends with a / as it should
		if ($page !~ /\/$/) {
	    	# It doesn't.. redirect
	   		&write_data("HTTP/1.0 302 Moved Temporarily\r\n");
	    	$portstr = ($sslrequest) ? ":$sslport" : ":$port";
	    	&write_data("Date: $datestr\r\n");
	    	&write_data("Server: $config{'server'}\r\n");
	    	$prot = $sslrequest ? "https" : "http";
	    	&write_data("Location: $prot://$host$portstr$page/\r\n");
	    	&write_keep_alive(0);
	    	&write_data("\r\n");
	    	&log_request($acptip, $authuser, $reqline, 302, 0);
	    	return 0;
		}
		# A directory.. check for index files
		foreach $idx (split(/\s+/, $config{'index_docs'})) {
	    	$idxfull = "$full/$idx";
	    	if (-r $idxfull && !(-d $idxfull)) {
				$full = $idxfull;
				$scriptname .= "/" if ($scriptname ne "/");
				last;
		    }
		}
    }

    if (-d $full) {
		# A directory should NOT be listed.
		# Instead a 404 should be returned
		&http_error(404, "File not found");
		
		# This is definitely a directory.. list it
		#&write_data("HTTP/1.0 200 OK\r\n");
		#&write_data("Date: $datestr\r\n");
		#&write_data("Server: $config{'server'}\r\n");
		#&write_data("Content-Type: text/html\r\n");
		#&write_keep_alive(0);
		#&write_data("\r\n");
		#&reset_byte_count();
		#&write_data("<html>\n<body>\n<h1>Index of $simple</h1>\n");
		#&write_data("<pre>\n");
		#&write_data(sprintf "%-35.35s %-20.20s %-10.10s\n", "Name", "Last Modified", "Size");
		#&write_data("<hr>\n");
		#opendir(DIR, $full);
		#while($df = readdir(DIR)) {
		#    if ($df =~ /^\./) { next; }
		#    (@stbuf = stat("$full/$df")) || next;
		#    if (-d "$full/$df") { $df .= "/"; }
	    #	@tm = localtime($stbuf[9]);
	    #	$fdate = sprintf "%2.2d/%2.2d/%4.4d %2.2d:%2.2d:%2.2d",
	    #	$tm[3],$tm[4]+1,$tm[5]+1900,
	    #	$tm[0],$tm[1],$tm[2];
	    #	$len = length($df); $rest = " "x(35-$len);
	    #	&write_data(sprintf 
		#		"<a href=\"%s\">%-${len}.${len}s</a>$rest %-20.20s %-10.10s\n",
		#		$df, $df, $fdate, $stbuf[7]);
		#}
		#closedir(DIR);
		#&write_data("</body>\n</html>\n");	
		#&log_request($acptip, $authuser, $reqline, 200, &byte_count());
		return 0;
    }

    # CGI or normal file
    local $rv;
    if (&get_type($full) eq "internal/cgi") {
		# A CGI program to execute
		$envtz = $ENV{"TZ"};
		$envuser = $ENV{"USER"};
		$envpath = $ENV{"PATH"};
		# workaround for windows bug - don't clear out ENV for windows
		# when PLB and MP3B get launched, their ENV vars
		# are not all there which gives rise to Win 10106 error
		if($^O ne "MSWin32")
		{	
		    foreach (keys %ENV) { delete($ENV{$_}); }
		    $ENV{'PATH'} = $envpath if ($envpath);
		    $ENV{"TZ"} = $envtz if ($envtz);
		    $ENV{"USER"} = $envuser if ($envuser);
		}
		$ENV{"HOME"} = $user_homedir;
		$ENV{"SERVER_SOFTWARE"} = $config{"server"};
		$ENV{"SERVER_NAME"} = $host;
		$ENV{"SERVER_ADMIN"} = $config{"email"};
		$ENV{"SERVER_ROOT"} = $config{"root"};
		if($sslrequest) {
			$ENV{"SERVER_PORT"} = $sslport;
    	}
    	else {
    		$ENV{"SERVER_PORT"} = $port;
    	}
        $ENV{"PLAYLISTS_ROOT"} = $config{"plroot"};
        $ENV{"GBROWSE_FLAG"} = $config{"gbrowse"};
		$ENV{"REMOTE_HOST"} = $acptip;
		$ENV{"REMOTE_ADDR"} = $acptip;
		$ENV{"REMOTE_USER"} = $authuser if (defined($authuser));
		$ENV{"SSL_USER"} = $peername if ($validated == 2);
		$ENV{"DOCUMENT_ROOT"} = $config{"root"};
		$ENV{"GATEWAY_INTERFACE"} = "CGI/1.1";
		$ENV{"SERVER_PROTOCOL"} = "HTTP/1.0";
		$ENV{"REQUEST_METHOD"} = $method;
		$ENV{"SCRIPT_NAME"} = $scriptname;
		$ENV{"REQUEST_URI"} = $request_uri;
		$ENV{"PATH_INFO"} = $pathinfo;
		$ENV{"PATH_TRANSLATED"} = "$config{root}/$pathinfo";
		$ENV{"QUERY_STRING"} = $querystring;
		$ENV{"QTSSADMINSERVER_CONFIG"} = $conf;
		$ENV{"QTSSADMINSERVER_QTSSIP"} = $config{"qtssIPAddress"};
		$ENV{"QTSSADMINSERVER_QTSSPORT"} = $config{"qtssPort"};
		$ENV{"QTSSADMINSERVER_QTSSNAME"} = $config{"qtssName"};
		$ENV{"QTSSADMINSERVER_QTSSAUTOSTART"} = $config{"qtssAutoStart"};
		$ENV{"QTSSADMINSERVER_QTSSQTPASSWD"} = $config{"qtssQTPasswd"};
		$ENV{"QTSSADMINSERVER_QTSSPLAYLISTBROADCASTER"} = $config{"qtssPlaylistBroadcaster"};
		$ENV{"QTSSADMINSERVER_QTSSMP3BROADCASTER"} = $config{"qtssMP3Broadcaster"};
		$ENV{"QTSSADMINSERVER_QTSSADMIN"} = $config{"qtssAdmin"};
		$ENV{"QTSSADMINSERVER_HELPURL"} = $config{"helpurl"};
		$ENV{"QTSSADMINSERVER_TEMPFILELOC"} = $config{"tempfileloc"};
		$ENV{"QTSSADMINSERVER_EN_MESSAGEHASH"} = $messages{"en"};
		$ENV{"QTSSADMINSERVER_DE_MESSAGEHASH"} = $messages{"de"};
		$ENV{"QTSSADMINSERVER_JA_MESSAGEHASH"} = $messages{"ja"};
		$ENV{"QTSSADMINSERVER_FR_MESSAGEHASH"} = $messages{"fr"};
		$ENV{"GENREFILE"} = 'genres';
		$ENV{"COOKIES"} = $header{'cookie'};
		$ENV{"COOKIE_EXPIRE_SECONDS"} = $config{"cookieExpireSeconds"};
		$ENV{"LANGDIR"} = $langDir;
		$ENV{"LANGUAGE"} = $language;
		$ENV{"SSL_AVAIL"} = $ssl_available;
		$ENV{"HTTPS"} =  "ON" if ($use_ssl);
		if (defined($header{"content-length"})) {
	    	$ENV{"CONTENT_LENGTH"} = $header{"content-length"};
		}
		if (defined($header{"content-type"})) {
	    	$ENV{"CONTENT_TYPE"} = $header{"content-type"};
		}
		if (defined($header{"user-agent"})) {
			$ENV{"USER_AGENT"} = $header{"user-agent"};
		}
		foreach $h (keys %header) {
		    ($hname = $h) =~ tr/a-z/A-Z/;
		    $hname =~ s/\-/_/g;
		    $ENV{"HTTP_$hname"} = $header{$h};
		}
		$full =~ /^(.*\/)[^\/]+$/; $ENV{"PWD"} = $1;
		foreach $k (keys %config) {
		    if ($k =~ /^env_(\S+)$/) {
				$ENV{$1} = $config{$k};
	    	}
		}
	
		# Check if the CGI can be handled internally
		open(CGI, $full);
		local $first = <CGI>;
		close(CGI);
		$perl_cgi = 0;
		if ($^O eq "MSWin32") {
		    if ($first =~ m/^#!(.*)perl$/i) {
				$perl_cgi = 1;
				undef($postinput);
				undef($postpos);
	    	}
		}
		else {
	    	if ($first =~ m/#!$perl_path(\r|\n)/ && $] >= 5.004) {
				$perl_cgi = 1;
	    	}
		}
		if($perl_cgi == 1) {
	    	# setup environment for eval
	    	chdir($ENV{"PWD"});
	    	@ARGV = split(/\s+/, $queryargs);
	    	$0 = $full;
	    	if ($posted_data) {
				# Already read the post input
				$postinput = $posted_data;
			}
	    	elsif ($method eq "POST") {
				$clen = $header{"content-length"};
				while(length($postinput) < $clen) {
		    		$buf = &read_data($clen - length($postinput));
		    		if (!length($buf)) {
						&http_error(500, "Failed to read ".
				    	"POST request");
		    		}
		    		$postinput .= $buf;
				}
	    	}
	    
	    	if($^O ne "MSWin32") {
				$SIG{'CHLD'} = 'DEFAULT';
		    	eval {
		    		# Have SOCK closed if the perl exec's something
					use Fcntl;
					fcntl(SOCK, F_SETFD, FD_CLOEXEC);
				};
			}
	    
	    	if ($config{'log'}) {
				open(QTSSADMINSERVERLOG, ">>$config{'logfile'}");
				chmod(0600, $config{'logfile'});
	    	}
	    	# set doneheaders = 1 so that the cgi spits out all the headers
	    	$doneheaders = 1;
	    	
	    	$doing_eval = 1;
	    	eval {
				package main;
				tie(*STDOUT, 'streamingadminserver');
				tie(*STDIN, 'streamingadminserver');
				do $streamingadminserver::full;
				die $@ if ($@);
	    	};
	    	$doing_eval = 0;
	    	if ($@) {
				# Error in perl!
				# Uncomment the first line (and comment the second) for debug
				# Error message has security implications.
				&http_error(500, "Perl execution failed", $@);
				#&http_error(500, "Perl execution failed");
	    	}
	    	elsif (!$doneheaders) {
				&http_error(500, "Missing Header");
	    	}
	    
		    if($^O ne "MSWin32") {
				close(SOCK);
	    	}
	    	if($^O eq "MSWin32") {
				untie(*STDOUT);
				untie(*STDIN);
				$doneheaders = 0;
	    	}
	    	$rv = 0;
		} 
		else {
	    	if($^O ne "MSWin32") {
				# fork the process that actually executes the CGI
				pipe(CGIINr, CGIINw);
				pipe(CGIOUTr, CGIOUTw);
				pipe(CGIERRr, CGIERRw);
				if (!($cgipid = fork())) {
		    		chdir($ENV{"PWD"});
		    		close(SOCK);
		    		open(STDIN, "<&CGIINr");
		    		open(STDOUT, ">&CGIOUTw");
		    		open(STDERR, ">&CGIERRw");
		    		close(CGIINw); close(CGIOUTr); close(CGIERRr);
		    		exec($full, split(/\s+/, $queryargs));
		    		exit;
				}
				close(CGIINr); close(CGIOUTw); close(CGIERRw);
		
				# send post data
				if ($posted_data) {
					# already read the posted data
					print CGIINw $posted_data;
				}
				elsif ($method eq "POST") {
		   	 		$got = 0; $clen = $header{"content-length"};
		    		while($got < $clen) {
						$buf = &read_data($clen-$got);
						if (!length($buf)) {
						    kill('TERM', $cgipid);
						    &http_error(500, "Failed to read ".
							"POST request");
						}
						$got += length($buf);
						print CGIINw $buf;
		    		}
				}
				close(CGIINw);
				shutdown(SOCK, 0);
				
				# read back cgi headers
				select(CGIOUTr); $|=1; select(STDOUT);
				$got_blank = 0;
				$cgi_statusline = "";
				while(1) {
				    $line = <CGIOUTr>;
				    # check if the first line of the cgi is the status line
				    my $http_version = "HTTP/1.0";
					if(($cgi_statusline eq "") && !%cgiheader && ($line =~ m/$http_version\s(.*)(\r|\n)/)) {
						 $cgi_statusline = $line;
		 				 next;
		   			}
		    		$line =~ s/\r|\n//g;
		    		if ($line eq "") {
						if ($got_blank || %cgiheader) { last; }
						$got_blank++;
						next;
		    		}
		    		($line =~ /^(\S+):\s+(.*)$/) ||
						&http_error(500, "Bad Header",
				    	&read_errors(CGIERRr));
		    		$cgiheader{lc($1)} = $2;
		    	}
				if($cgi_statusline ne "") {
					&write_data($cgi_statusline);
				}
				else {
					if ($cgiheader{"location"}) {
		    			&write_data("HTTP/1.0 302 Moved Temporarily\r\n");
		    			# ignore the rest of the output. This is a hack, but
				    	# is necessary for IE in some cases :(
		    			close(CGIOUTr); close(CGIERRr);
					}	
					elsif ($cgiheader{"content-type"} eq "") {
		    			&http_error(500, "Missing Content-Type Header",
						&read_errors(CGIERRr));
					}
					else {
		    			&write_data("HTTP/1.0 200 OK\r\n");
		    			&write_data("Date: $datestr\r\n");
		    			&write_data("Server: $config{server}\r\n");
		    			&write_keep_alive(0);
					}
				}
				foreach $h (keys %cgiheader) {
		    		&write_data("$h: $cgiheader{$h}\r\n");
				}
				&write_data("\r\n");
				&reset_byte_count();
				while($line = <CGIOUTr>) { &write_data($line); }
				close(CGIOUTr); close(CGIERRr);
				$rv = 0;
	    	}
		}
    }
    else {
    	# if MIME type is text/plain, make sure the file ends in .txt
    	# prevents source code revelation on Windows
    	if ((&get_type($full) eq 'text/plain') && (!(full =~ m/\.txt$/))) {
    		&http_error(404, 'Failed to open file');
    	}
    
		# A file to output
		local @st = stat($full);
		open(FILE, $full) || &http_error(404, "Failed to open file");
	
		# The read call in Windows interprets the end of lines
		# unless it is opened in binary mode
		if ($^O eq "MSWin32") {
		    binmode( FILE );
		}
	
		&write_data("HTTP/1.0 200 OK\r\n");
		&write_data("Date: $datestr\r\n");
		&write_data("Server: $config{server}\r\n");
		&write_data("Content-Type: ".&get_type($full)."\r\n");
		&write_data("Content-Length: $st[7]\r\n");
		&write_data("Last-Modified: ".&http_date($st[9])."\r\n");
		if ($^O eq "MSWin32") {
		    # Since it is one process handling all connections, we can't keep a connection alive
		    &write_keep_alive(0);
		}
		else {
	    	&write_keep_alive();
		}	
		&write_data("\r\n");
		&reset_byte_count();
		while(read(FILE, $buf, 1024) > 0) {
		    &write_data($buf);
		}
		close(FILE);
		if($^O eq "MSWin32") {
	    	# can't do keep alive when we're just a single process
	   		$rv = 0;
		}
		else {
	    	$rv = &check_keep_alive();
		}
	}
    # log the request
    &log_request($acptip, $authuser, $reqline,
		 $cgiheader{"location"} ? "302" : "200", &byte_count());
    return $rv;
}

# http_error(code, message, body, [dontexit])
sub http_error
{
    close(CGIOUT);
    &write_data("HTTP/1.0 $_[0] $_[1]\r\n");
    &write_data("Server: $config{server}\r\n");
    &write_data("Date: $datestr\r\n");
    &write_data("Content-Type: text/html\r\n");
    &write_keep_alive(0);
    &write_data("\r\n");
    &reset_byte_count();
    &write_data("<html><body>\n");
    &write_data("<h1>Error - $_[1]</h1>\n");
    if ($_[2]) {
	&write_data("<pre>$_[2]</pre>\n");
    }
    &write_data("</body></html>\n");
    &log_request($acptip, $authuser, $reqline, $_[0], &byte_count());
    if ($^O ne "MSWin32") {
	exit if (!$_[3]);
    }
}

# http_redirect(use_ssl, host, port, redirecturl, [dontexit])
sub http_redirect
{
    close(CGIOUT);
    &write_data("HTTP/1.0 302 Temporarily Unavailable\r\n");
    &write_data("Server: $config{server}\r\n");
    &write_data("Date: $datestr\r\n");
    my $prot = $_[0] ? "https" : "http";
    my $portStr = ($_[2] == 80 && !$_[0]) ? "" : ($_[2] == 443 && $_[0]) ? "" : ":$_[2]";
    &write_data("Location: $prot://$_[1]$portStr$_[3]\r\n");
    &write_data("Connection: close\r\n");
    &write_keep_alive(0);
    &write_data("\r\n");
    &log_request($acptip, $authuser, $reqline, 302, 0);
    if ($^O ne "MSWin32") {
		exit if (!$_[4]);
    }
}

sub get_type
{
    if ($_[0] =~ /\.([A-z0-9]+)$/) {
	$t = $mime{$1};
	if ($t ne "") {
	    return $t;
	}
    }
    return "text/plain";
}

# simplify_path(path, bogus)
# Given a path, maybe containing stuff like ".." and "." convert it to a
# clean, absolute form.
sub simplify_path
{
    local($dir, @bits, @fixedbits, $b);
    $dir = $_[0];
    $dir =~ s/^\/+//g;
    $dir =~ s/\/+$//g;
    @bits = split(/\/+/, $dir);
    
    if ($#bits == 0) # the path separator in $dir is not '/' maybe it is '\' (windows)
    {
    	$dir =~ s/^\\+//g;
    	$dir =~ s/\\+$//g;
    	@bits = split(/\\+/, $dir);
    }
     
    @fixedbits = ();
    $_[1] = 0;
    foreach $b (@bits) {
        if ($b eq ".") {
	    # Do nothing..
        }
        elsif ($b eq "..") {
	    # Remove last dir
	    if (scalar(@fixedbits) == 0) {
		$_[1] = 1;
		return "/";
	    }
	    pop(@fixedbits);
	}
        else {
	    # Add dir to list
	    push(@fixedbits, $b);
	}
    }
    return "/" . join('/', @fixedbits);
}

# b64decode(string)
# Converts a string from base64 format to normal
sub b64decode
{
    local($str) = $_[0];
    local($res);
    $str =~ tr|A-Za-z0-9+=/||cd;
    $str =~ s/=+$//;
    $str =~ tr|A-Za-z0-9+/| -_|;
    while ($str =~ /(.{1,60})/gs) {
        my $len = chr(32 + length($1)*3/4);
        $res .= unpack("u", $len . $1 );
    }
    return $res;
}

# ip_match(ip, [match]+)
# Checks an IP address against a list of IPs, networks and networks/masks
sub ip_match
{
    local(@io, @mo, @ms, $i, $j);
    @io = split(/\./, $_[0]);
	local $hn;
	if (!defined($hn = $ip_match_cache{$_[0]})) {
		$hn = gethostbyaddr(inet_aton($_[0]), AF_INET);
		$hn = "" if ((&to_ipaddress($hn))[0] ne $_[0]);
		$ip_match_cache{$_[0]} = $hn;
	}    
    for($i=1; $i<@_; $i++) {
	local $mismatch = 0;
	if ($_[$i] =~ /^(\S+)\/(\S+)$/) {
	    # Compare with network/mask
	    @mo = split(/\./, $1); @ms = split(/\./, $2);
	    for($j=0; $j<4; $j++) {
		if ((int($io[$j]) & int($ms[$j])) != int($mo[$j])) {
		    $mismatch = 1;
		}
	    }
	}
	elsif ($_[$i] =~ /^\*(\S+)$/) {
		# Compare with hostname regexp
		$mismatch = 1 if ($hn !~ /$1$/);
	}
	else {
	    # Compare with IP or network
	    @mo = split(/\./, $_[$i]);
	    while(@mo && !$mo[$#mo]) { pop(@mo); }
	    for($j=0; $j<@mo; $j++) {
		if ($mo[$j] != $io[$j]) {
		    $mismatch = 1;
		}
	    }
	}
	return 1 if (!$mismatch);
    }
    return 0;
}

# restart_streamingadminserver()
# Called when a SIGHUP is received to restart the web server. This is done
# by exec()ing perl with the same command line as was originally used
sub restart_streamingadminserver
{
    close(SOCK); close(MAIN); close(SSLMAIN);
    foreach $p (@passin) { close($p); }
    foreach $p (@passout) { close($p); }
    if ($logclearer) { kill('TERM', $logclearer);	}
    exec($perl_path, $streamingadminserver_path, @streamingadminserver_argv);
    die "Failed to restart streamingadminserver with $perl_path $streamingadminserver_path";
}

sub trigger_restart
{
    $need_restart = 1;
}

sub to_ipaddress
{
    local (@rv, $i);
    foreach $i (@_) {
	if ($i =~ /(\S+)\/(\S+)/ || $i =~ /^\*\S+$/) { push(@rv, $i); }
	else { push(@rv, join('.', unpack("CCCC", inet_aton($i)))); }
    }
    return @rv;
}

# read_line()
# Reads one line from SOCK or SSL
sub read_line
{
	local($idx, $more, $rv);
	if ($sslrequest) {
		while(($idx = index($read_buffer, "\n")) < 0) {
			# need to read more..
			if (!($more = Net::SSLeay::read($ssl_con))) {
				# end of the data
				$rv = $read_buffer;
				undef($read_buffer);
				return $rv;
			}
			$read_buffer .= $more;
		}
		$rv = substr($read_buffer, 0, $idx+1);
		$read_buffer = substr($read_buffer, $idx+1);
		return $rv;
	}
	else { return <SOCK>; }
}

# read_data(length)
# Reads up to some amount of data from SOCK or the SSL connection
sub read_data
{
	if ($sslrequest) {
		local($rv);
		if (length($read_buffer)) {
			$rv = $read_buffer;
			undef($read_buffer);
			return $rv;
		}
		else {
			return Net::SSLeay::read($ssl_con, $_[0]);
		}
	}
	else {
		local($buf);
		read(SOCK, $buf, $_[0]) || return undef;
		return $buf;
	}
}

# write_data(data)
# Writes a string to SOCK or the SSL connection
sub write_data
{
	if ($sslrequest) {
		Net::SSLeay::write($ssl_con, $_[0]);
	}
	else {
		syswrite(SOCK, $_[0], length($_[0]));
	}
	$write_data_count += length($_[0]);
}

# reset_byte_count()
sub reset_byte_count { $write_data_count = 0; }

# byte_count()
sub byte_count { return $write_data_count; }

# log_request(address, user, request, code, bytes)
sub log_request
{
    if ($config{'log'}) {
    	local(@tm, $dstr, $addr, $user, $ident);
	if ($config{'logident'}) {
	    # add support for rfc1413 identity checking here
	}
	else { $ident = "-"; }
	@tm = localtime(time());
	$dstr = sprintf "%2.2d/%s/%4.4d:%2.2d:%2.2d:%2.2d %s",
	$tm[3], $make_date_marr[$tm[4]], $tm[5]+1900,
	$tm[2], $tm[1], $tm[0], $timezone;
	$addr = $config{'loghost'} ? gethostbyaddr(inet_aton($_[0]), AF_INET)
	    : $_[0];
	$user = $_[1] ? $_[1] : "-";
	if (fileno(QTSSADMINSERVERLOG)) {
	    seek(QTSSADMINSERVERLOG, 0, 2);
	}
	else {
	    open(QTSSADMINSERVERLOG, ">>$config{'logfile'}");
	    chmod(0600, $config{'logfile'});
	}
	print QTSSADMINSERVERLOG "$addr $ident $user [$dstr] \"$_[2]\" $_[3] $_[4]\n";
	close(QTSSADMINSERVERLOG);
    }
}

# read_errors(handle)
# Read and return all input from some filehandle
sub read_errors
{
    local($fh, $_, $rv);
    $fh = $_[0];
    while(<$fh>) { $rv .= $_; }
    return $rv;
}

sub write_keep_alive
{
    local $mode;
    if (@_) { $mode = $_[0]; }
    else { $mode = &check_keep_alive(); }
    &write_data("Connection: ".($mode ? "Keep-Alive" : "close")."\r\n");
}

sub check_keep_alive
{
    return $header{'connection'} =~ /keep-alive/i;
}


sub reaper
{
	local($pid);
	do {
	    $pid = waitpid(-1, WNOHANG);
	} while($pid > 0);
}

sub term_handler
{
    if (@childpids) {
		kill('TERM', @childpids);
    }
    exit(1);
}

sub http_date
{
    local @tm = gmtime($_[0]);
    return sprintf "%s, %d %s %d %2.2d:%2.2d:%2.2d GMT",
    $weekday[$tm[6]], $tm[3], $month[$tm[4]], $tm[5]+1900,
    $tm[2], $tm[1], $tm[0];
}

sub TIEHANDLE
{
    my $i; bless \$i, shift;
}

sub WRITE
{
    $r = shift;
    my($buf,$len,$offset) = @_;
    &write_to_sock(substr($buf, $offset, $len));
}

sub PRINT
{
    $r = shift;
    $$r++;
    &write_to_sock(@_);
}

sub PRINTF
{
    shift;
    my $fmt = shift;
    &write_to_sock(sprintf $fmt, @_);
}

sub READ
{
    $r = shift;
    substr($_[0], $_[2], $_[1]) = substr($postinput, $postpos, $_[1]);
    $postpos += $_[1];
}

sub OPEN
{
	print STDERR "open() called - should never happen!\n";
}
 
sub READLINE
{
    if ($postpos >= length($postinput)) {
	return undef;
    }
    local $idx = index($postinput, "\n", $postpos);
    if ($idx < 0) {
	local $rv = substr($postinput, $postpos);
	$postpos = length($postinput);
	return $rv;
    }
    else {
	local $rv = substr($postinput, $postpos, $idx-$postpos+1);
	$postpos = $idx+1;
	return $rv;
    }
}
 
sub GETC
{
    return $postpos >= length($postinput) ? undef
	: substr($postinput, $postpos++, 1);
}
 
sub CLOSE { }
 
sub DESTROY { }

# write_to_sock(data, ...)
sub write_to_sock
{
    foreach $d (@_) {
	if ($doneheaders) {
	    &write_data($d);
	}
	else {
	    $headers .= $d;
	    while(!$doneheaders && $headers =~ s/^(.*)(\r)?\n//) {
		if ($1 =~ /^(\S+):\s+(.*)$/) {
		    $cgiheader{lc($1)} = $2;
		}
		elsif ($1 !~ /\S/) {
		    $doneheaders++;
		}
		else {
		    &http_error(500, "Bad Header");
		}
	    }
	    if ($doneheaders) {
		if ($cgiheader{"location"}) {
		    &write_data(
				"HTTP/1.0 302 Moved Temporarily\r\n");
		}
		elsif ($cgiheader{"content-type"} eq "") {
		    &http_error(500, "Missing Content-Type Header");
		}
		else {
		    &write_data("HTTP/1.0 200 OK\r\n");
		    &write_data("Date: $datestr\r\n");
		    &write_data("Server: $config{server}\r\n");
		    &write_keep_alive(0);
		}
		foreach $h (keys %cgiheader) {
		    &write_data("$h: $cgiheader{$h}\r\n");
		}
		&write_data("\r\n");
		&reset_byte_count();
		&write_data($headers);
	    }
	}
    }
}

sub verify_client
{
	local $cert = Net::SSLeay::X509_STORE_CTX_get_current_cert($_[1]);
	if ($cert) {
		local $errnum = Net::SSLeay::X509_STORE_CTX_get_error($_[1]);
		$verified_client = 1 if (!$errnum);
	}
	return 1;
}

sub pem_passwd_cb
{
	return $keypassword;
}

sub BINMODE { }

sub END
{
    if ($doing_eval) {
	# A CGI program called exit! This is a horrible hack to 
	# finish up before really exiting
	close(SOCK);
	&log_request($acptip, $authuser, $reqline,
		     $cgiheader{"location"} ? "302" : "200", &byte_count());
    }
}

# urlize
# Convert a string to a form ok for putting in a URL
sub urlize {
  local($tmp, $tmp2, $c);
  $tmp = $_[0];
  $tmp2 = "";
  while(($c = chop($tmp)) ne "") {
	if ($c !~ /[A-z0-9]/) {
		$c = sprintf("%%%2.2X", ord($c));
		}
	$tmp2 = $c . $tmp2;
	}
  return $tmp2;
}

sub LoadMessageHashes {
	# Read the messages file for each language
	# and store in a hash variable
	# moved so separate sub so that message file can be reloaded later
	%messagesfile = ();
	$messagesfile{"en"} = $config{'root'} . "/html_en/" . $config{'messagesfile'}; 
	$messagesfile{"de"} = $config{'root'} . "/html_en/" . $config{'messagesfile'}; 
	$messagesfile{"fr"} = $config{'root'} . "/html_en/" . $config{'messagesfile'}; 
	$messagesfile{"jp"} = $config{'root'} . "/html_en/" . $config{'messagesfile'}; 
	
	%messages = ();
	for $lang (keys %messagesfile) {
		# Create a hash for each message file 
		# The keys are the keywords and the values are the message strings
		$messageHashRef = ();
		open(MESSAGES, $messagesfile{$lang}) or die "Couldn't find the $lang language messages file!";
		while($messageLine = <MESSAGES>) {
			if(($messageLine =~ /^#/) || ($messageLine =~ /^\s+$/)) {
				next;
			}
			if($messageLine =~ /^(\s*?)(\S+)(\s+?)\"(.*)\"(\s*)$/) {
				$keyword = $2;
				$messageStr = $4;
			}
			$messageHashRef->{$keyword} = $messageStr;
		}
		$messages{$lang} = $messageHashRef;
	
		close(MESSAGES);
	 }
}

# IsAllowedToSetup
# checks if the ip address is allowed
# needed to check if the request is coming from a local
# IP if setup assitant hasn't run yet
# input:	config root
# returns	0 => if denied
# 			1 => if allowed
sub IsAllowedToSetup
{
	my ($configRoot, $clientIP) = @_;
	
	return 1; # always allowed now

	use Sys::Hostname;
	
	my $host = hostname();
	my $addr = inet_aton($host);
    
    my $setupAssistantPath = $configRoot . "/index.html";
	if (-e $setupAssistantPath)
	{
		# if the index.html file exists, then the setup assistant
		# hasn't successfully completed yet
		
		if ($clientIP == inet_ntoa(INADDR_LOOPBACK)) # check if client is using loopback address
		{
			return 1;
		}
		elsif ($clientIP == inet_ntoa($addr))
		{
			return 1;
		}
		return 0;
	}	
	return 1;
}
