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

require('tag_vals.pl');
require('tag_types.pl');
require('tag_formats.pl');
require('adminprotocol-lib.pl');
require('cgi-lib.pl');
require('playlist-lib.pl');
require('relayxmlparser.pl');
require('password-utils.pl');

# Get the server name, QTSS IP address, and Port from ENV hash
$servername = $ENV{"SERVER_SOFTWARE"};
$qtssip = $ENV{"QTSSADMINSERVER_QTSSIP"};
$qtssport = $ENV{"QTSSADMINSERVER_QTSSPORT"};
$remoteip = $ENV{"REMOTE_HOST"};
$accessdir = $ENV{"LANGDIR"};
$nonAuthenticatedActions = ("|login|logout|AssistSetPassword|");
$displayedLoginMessage = 0;

$auth = '';
$authheader = '';
$messageHash = &adminprotolib::GetMessageHash();
$cookie = '';
$password = '';
$iteration = '';
$cookieExpireSecs = $ENV{"COOKIE_EXPIRE_SECONDS"};

# this array will get filled by the foundTag function
my %endTags = ();

# tag depth variable
my $tag_depth = 0;

sub encodeBase64 {
    my $res = '';

    pos($_[0]) = 0;                          # ensure start at the beginning
    while ($_[0] =~ /(.{1,45})/gs) {
	$res .= substr(pack('u', $1), 1);
	chop($res);
    }
    $res =~ tr|` -_|AA-Za-z0-9+/|;               # `# help emacs
    # fix padding at the end
    my $padding = (3 - length($_[0]) % 3) % 3;
    $res =~ s/.{$padding}$/'=' x $padding/e if $padding;
    return $res;
}

# b64decode(string)
# Converts a string from base64 format to normal
sub b64decode {
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

sub repeaterExists {
	my $testRepeater = $_[0];
	my $i = 0;
	my $foundItem = '';
	my $currentItem = '';
	
	foreach $theItem (@returnedKeys) {
		if ($theItem eq $testRepeater) {
			$foundItem = 1;
			last;
		}
	}
	return $foundItem;
}

sub addIterationAttribute {
	my $tagAttributes = $_[0];
	my $endTagSlash = $_[1];
	my $singleTagSlash = $_[2];
	my $iterationNumber = $_[3];
	if ($endTagSlash eq '/') {
		return '</qtssobject>';
	}
	else {
		return '<qtssobject' . $tagAttributes . " iteration=$iterationNumber" . $singleTagSlash . '>';
	}
}

# this routine, erm, expands repeater tags. Adds an iteration attribute to all contained qtssobject tags.
sub expandRepeater {
	my $tagAttributes = $_[0];
	my $tagContents = $_[1];
	my $name = '';
	my $arraySize = 0;
	my $currentIteration = 0;
	my $returnedText = '';
	$_ = $tagAttributes;
	if (/ name="[^"]*"| name=[^ (\/>)]*/si) {
		$name = $&;
		$name =~ s/ *name="*//;
		$name =~ s/"//;
	}
	$arraySize = getRepeaterArray($name);
	# return '@' . $returnedKeys[0];
	# $arraySize = scalar(eval('@' . $returnedKeys[0]));
	for ($currentIteration = 0; $currentIteration < $arraySize; $currentIteration++) {
		$_ = $tagContents;
		s{ < ( /*? ) qtssobject ( .*? ) (/*?) >}
				{ addIterationAttribute($2, $1, $3, $currentIteration) }isgxe;
		$returnedText .= $_;
	}
	return $returnedText;
}

# this routine takes the contents of a qtssobject tag and deals with it accordingly
sub foundTag {
	my $data = '';
	my $tagAttributes = $_[0];
	my $endTagSlash = $_[1];
	my $singleTagSlash = $_[2];
	my $name = '';
	my $type = '';
	my $value = '';
	my $format = '';
	my $userParam = '';
	my $final_value = '';
	$iteration = '';
	$_ = $tagAttributes;
	if ($endTagSlash eq "/") {
		$final_value = $endTags{$tag_depth};
		$tag_depth--;
		return $final_value;
	}
	if (/ name="[^"]*"| name=[^ (\/>)]*/si) {
		$name = $&;
		$name =~ s/ *name="*//;
		$name =~ s/"//;
	}
	if (/ type="[^"]*"| type=[^ (\/>)]*/si) {
		$type = $&;
		$type =~ s/ *type="*//;
		$type =~ s/"//;
	}
	else {
		$type = $defaultTypes{$name};
	}
	if (/ iteration="[^"]*"| iteration=[^ (\/>)]*/si) {
		$iteration = $&;
		$iteration =~ s/ *iteration="*//;
		$iteration =~ s/"//;
	}
	# get the end tag, if necessary
	if ($singleTagSlash eq '') {
		$tag_depth++;
		$endTags{$tag_depth} = $endTagTypes{$type};
	}
	if (/ format="[^"]*"| format=[^ (\/>)]*/si) {
		$format = $&;
		$format =~ s/ *format="*//;
		$format =~ s/"//;
	}
	else {
		$format = $defaultFormats{$name};
	}
	if (/ param="[^"]*"| param=[^ (\/>)]*/si) {
		$userParam = $&;
		$userParam =~ s/ *param="*//;
		$userParam =~ s/"//;
	}
	else {
		$userParam = '';
	}
	$value = $tagVals{$name};
	
	#check to see if there's an iteration
	#if so, check to see if a repeater with this name exists
	if ($iteration ne '') {
		# return $name;
		if (repeaterExists($name)) {
			$value = eval('$' . $name . "[$iteration]");
			$name .= $iteration;
		}
	}
	
	$_ = $value;
	
	#if it starts with / then we'll assume it's a path to a server var
	if (($_ ne '') && (/^\//) && ($iteration eq '')) {
		my $messHash = adminprotolib::GetMessageHash();
		$status = adminprotolib::EchoData($data, $messHash, $authheader, $qtssip, $qtssport, $value, $value);

		if (($status == 500) and ($data =~ /Connection refused/) and ($displayedLoginMessage == 0)) {

			$displayedLoginMessage = 1;

			$wasAuth = 0;

			my $loginText = '';

			open(LOGINFILE, "start_server.html") or die "Can't open server start file!";

			while ($line = <LOGINFILE>) {

				$loginText .= $line;

			}

			close(LOGINFILE);

			$loginText = parseTags($loginText);

			&cgilib::PrintOKTextHeader($servername);

			print $loginText;

			return 0;

		}
		if ($status == 401) {
			my $isAuthenticated = 0;
			
			if ($wasAuth == (-1)) {
				$value = '';
				return '';
			}
			
			# only try default authentication if setup assistant on mac os x
			if (($^O eq "darwin") and (-e "index.html") and ($ENV{"REMOTE_HOST"} eq '127.0.0.1') and (MacQTGroupsContainsAdminGroup() == 0)) {
				if (wasAuth >= 0) { # first pass
					open(LOGINFILE, "setup_assistant.html");
					my $loginText = '';
					while ($line = <LOGINFILE>) {
						$loginText .= $line;
					}
					close(LOGINFILE);
					$wasAuth = (-1);
					$loginText = parseTags($loginText);
					&cgilib::PrintOKTextHeader($servername);
					print $loginText;
					return 0;
				}
			}
			if (($displayedLoginMessage == 0) && ($isAuthenticated == 0)) {
				$displayedLoginMessage = 1;
				# now using cookies to store password; return login page
				my $loginText = '';
				open(LOGINFILE, "login.html") or die "Can't open login file!";
				while ($line = <LOGINFILE>) {
					$loginText .= $line;
				}
				close(LOGINFILE);
				$loginText = parseTags($loginText);
				&cgilib::PrintOKTextHeader($servername);
				print $loginText;
				$wasAuth = 0;
				return 0;
			}
		}
		$value = $data;
	}
	
	# if it starts with = then we'll evaluate it, replacing stuff first
	# small possibility for nasty recursion exists here
	# be sure not to include another evaluating tag inside this one
	$_ = $value;
	if (/^=/) {
		$value =~ s/^=//;
		$value = parseTags($value);
		$value = eval($value);
	}
	
	# format value
	$value = runFormatter($value, $format, $userParam, $name);
	
	$final_value = $tagTypes{$type};
	if ($final_value eq '') {
		$final_value = $tagTypes{'plaintext'};
	}
	$final_value =~ s/<value\/>/$value/gi;
	$final_value =~ s/<name\/>/$name/gi;
	$final_value =~ s/<param\/>/$userParam/gi;
	$final_value =~ s/<filename\/>/$filename/gi;

	$_ = $final_value;
	return $final_value;
}

#this routine replaces localized strings from the messages file
sub foundString {
	my $tagAttributes = $_[0];
	my $endTagSlash = $_[1];
	my $singleTagSlash = $_[2];
	my $name = '';
	$_ = $tagAttributes;
	if (/ name="[^"]*"| name=[^ (\/>)]*/si) {
		$name = $&;
		$name =~ s/ *name="*//;
		$name =~ s/"//;
	}
	my $messHash = adminprotolib::GetMessageHash();
	my %messages = %$messHash;
	my $QTName = 'QT' . $name;
	if (($^O eq "darwin") and ($messages{$QTName} ne '')) {
		return $messages{$QTName};
	}
	return "$messages{$name}";
}

#this routine calls foundTag for each tag found.
sub parseTags {
	$_[0] =~ s{ <qtssrepeater ( .*? ) > ( .*?) </qtssrepeater> }
		  { expandRepeater($1, $2) }isgxe;
	$_[0] =~ s{ < ( /*? ) qtssobject ( .*? ) (/*?) >}
		  { foundTag($2, $1, $3) }isgxe;
	$_[0] =~ s{ < ( /*? ) qtssstring ( .*? ) (/*?) >}
		  { foundString($2, $1, $3) }isgxe;
	return "$_[0]";
}

sub StartStopServer {
	my $messageHash = &adminprotolib::GetMessageHash();
	my $data = "";
	my $status = &adminprotolib::EchoData($data, $messageHash, $authheader, $qtssip, $qtssport, "/modules/admin/server/qtssSvrState", "/server/qtssSvrState");
	# if the server is not running, launch process
	if($status == 200) {
		# if server is running, then put it in idle mode or if server is idle/not running, then put it in running mode
		if($data == 1) {
			$status = &adminprotolib::SetAttribute($data, $messageHash, $authheader, $qtssip, $qtssport, "/admin/server/qtssSvrState", 5);
		}
		else {
			$status = &adminprotolib::SetAttribute($data, $messageHash, $authheader, $qtssip, $qtssport, "/admin/server/qtssSvrState", 1);
		}
	}
}

sub SaveGeneralSettings {
	my $messHash = adminprotolib::GetMessageHash();
	my %messages = %$messHash;
	my $settingsPath = '/admin/server/qtssSvrPreferences/';
	my $data = '';
	my $configFilePath = $ENV{"QTSSADMINSERVER_CONFIG"};
	my $sslValue = $query->{'adminSSL'};
	my $autoStartValue = $query->{'qtssExtraGenSettings0'};
	my $name = '';
	my $val = '';
	
	if ($sslValue ne '1') {
		$sslValue = '0';
	}
	
	if ($autoStartValue ne '1') {
		$autoStartValue = '0';
	}
	
	if ($query->{'qtssMovieFolder'} ne $query->{'qtssMovieFolder_shadow'}) {
		$status = &adminprotolib::SetAttribute($data, $messHash, $authheader, $qtssip, $qtssport, $settingsPath."movie_folder", $query->{'qtssMovieFolder'});
	}
	
	if ($query->{'qtssMaxConn'} ne $query->{'qtssMaxConn_shadow'}) {
		$status = &adminprotolib::SetAttribute($data, $messHash, $authheader, $qtssip, $qtssport, $settingsPath."maximum_connections", $query->{'qtssMaxConn'});
	}
	
	if (($query->{'bpsinput'} ne $query->{'bpsinput_shadow'}) or ($query->{'kbpstype'} ne $query->{'kbpstype_shadow'})) {
		my $amt = $query->{'bpsinput'};
		if ($query->{'kbpstype'} eq 'mbps') {
			$amt = $amt * 1024
		}
		$status = &adminprotolib::SetAttribute($data, $messHash, $authheader, $qtssip, $qtssport, $settingsPath."maximum_bandwidth", $amt);
	}

	if ($query->{'qtssAuthScheme'} ne $query->{'qtssAuthScheme_shadow'}) {
		$status = &adminprotolib::SetAttribute($data, $messHash, $authheader, $qtssip, $qtssport, $settingsPath."authentication_scheme", $query->{'qtssAuthScheme'});
	}

	if ($sslValue ne parseForSSL()) {
		$configLine = qq(ssl=$sslValue\n);
		if(!(-e $configFilePath)) {
			open(CONFIGFILE, ">$configFilePath");
			print CONFIGFILE $configLine;
			close(CONFIGFILE);
			FixFileGroup($configFilePath);
			if($sslValue == 1)
			{
				$ENV{"HTTPS"} = "ON";
			}
			else
			{
				$ENV{"HTTPS"} = "OFF";
			}
		}
		else {
			if( -r $configFilePath && -w _) {
				$tmpname = $configFilePath . ".tmp";
				open(TEMPFILE, ">$tmpname");
				open(CONFIGFILE, "<$configFilePath");
				while($line = <CONFIGFILE>) {
					$_ = $line;
					chop;
					if (/^#/ || !/\S/) {
						print TEMPFILE $line;
						next; 
					}
					/^([^=]+)=(.*)$/;
					$name = $1; $val = $2;
					$name =~ s/^\s+//g; $name =~ s/\s+$//g;
					$val =~ s/^\s+//g; $val =~ s/\s+$//g;
					if($name eq "ssl") {
						$val = $sslValue; 
					}
					$config{$name} = $val;
					print TEMPFILE qq($name=$val\n);
				}
				if(!defined($config{'ssl'})) {
					print TEMPFILE $configLine;
				}
				close(CONFIGFILE);
				close(TEMPFILE);
				rename $tmpname, $configFilePath;
				if($sslValue == 1)
				{
					$ENV{"HTTPS"} = "ON";
				}
				else
				{
					$ENV{"HTTPS"} = "OFF";
				}
			}
			else {
				print STDERR "couldn't open $configFilePath for writing\n";
			}	
		}
	}
	
	$confirmMessage = $messages{'GenSetSettingsSavedText'};
}

sub RunAssistant {
	my $messHash = adminprotolib::GetMessageHash();
	my %messages = %$messHash;
	my $settingsPath = '/admin/server/qtssSvrPreferences/';
	my $MP3BroadcastPasswordPath = "/admin/server/qtssSvrModuleObjects/QTSSMP3StreamingModule/qtssModPrefs/mp3_broadcast_password";
	my $data = '';
	my $configFilePath = $ENV{"QTSSADMINSERVER_CONFIG"};
	my $sslValue = $query->{'assistSSL'};
	my $name = '';
	my $val = '';
	
	if ($sslValue ne '1') {
		$sslValue = '0';
	}
	
	# set MP3 Broadcast Password
	
	$status = &adminprotolib::SetAttribute($data, $messHash, $authheader, $qtssip, $qtssport, $MP3BroadcastPasswordPath, $query->{'assistMP3Pass'});
	
	# set media folder
		
	$status = &adminprotolib::SetAttribute($data, $messHash, $authheader, $qtssip, $qtssport, $settingsPath."movie_folder", $query->{'assistMovieFolder'});
	
	# set streaming on port 80
	
	SavePortSettings();
	$confirmMessage = ''; # reset the confirm message
	
	# set SSL on/off
	
	$configLine = qq(ssl=$sslValue\n);
	if(!(-e $configFilePath)) {
		open(CONFIGFILE, ">$configFilePath");
		print CONFIGFILE $configLine;
		close(CONFIGFILE);
		FixFileGroup($configFilePath);
		if($sslValue == 1)
		{
			$ENV{"HTTPS"} = "ON";
		}
		else
		{
			$ENV{"HTTPS"} = "OFF";
		}
	}
	else {
		if( -r $configFilePath && -w _) {
			$tmpname = $configFilePath . ".tmp";
			open(TEMPFILE, ">$tmpname");
			open(CONFIGFILE, "<$configFilePath");
			while($line = <CONFIGFILE>) {
				$_ = $line;
				chop;
				if (/^#/ || !/\S/) {
					print TEMPFILE $line;
					next; 
				}
				/^([^=]+)=(.*)$/;
				$name = $1; $val = $2;
				$name =~ s/^\s+//g; $name =~ s/\s+$//g;
				$val =~ s/^\s+//g; $val =~ s/\s+$//g;
				if($name eq "ssl") {
					$val = $sslValue; 
				}
				$config{$name} = $val;
				print TEMPFILE qq($name=$val\n);
			}
			if(!defined($config{'ssl'})) {
				print TEMPFILE $configLine;
			}
			close(CONFIGFILE);
			close(TEMPFILE);
			rename $tmpname, $configFilePath;
			if($sslValue == 1)
			{
				$ENV{"HTTPS"} = "ON";
			}
			else
			{
				$ENV{"HTTPS"} = "OFF";
			}
		}
		else {
			print STDERR "couldn't open $configFilePath for writing\n";
		}	
	}
}

sub SavePortSettings {
	my $messHash = adminprotolib::GetMessageHash();
	my %messages = %$messHash;
	my $data = '';
	my $settingsPath = '/admin/server/qtssSvrPreferences/';

	if ($query->{'qtssIsStreamingOn80'} ne $query->{'qtssIsStreamingOn80_shadow'}) {
		if($query->{'qtssIsStreamingOn80'} eq "true") {
			# set the pref
			$status = &adminprotolib::AddValueToAttribute($data, $messHash, $authheader, $qtssip, $qtssport, $settingsPath."rtsp_port", 80);				
			# find out where the pid file is
			my $pidfileloc = '';
			my $status = &adminprotolib::EchoData($pidfileloc, $messageHash, $authheader, $qtssip, $qtssport, "/modules/admin/server/qtssSvrPreferences/pid_file", "/server/qtssSvrPreferences/pid_file");
			# if the pid file exists...
			if (-e $pidfileloc) {
				# read in the file into an array
				my @splitPidFile = ();
				my $line;
				if (open(PIDFILE, $pidfileloc)) {
					while ($line = <PIDFILE>) {
						push(@splitPidFile, $line);
					}
					close(PIDFILE);
				}				
				if (scalar(@splitPidFile) > 0) {
					if ($splitPidFile[1] ne '') {
						kill 2, $splitPidFile[1];
						sleep(2);
					}
				}
			}
		}
		else {
			$status = &adminprotolib::DeleteValueFromAttribute($data, $messHash, $authheader, $qtssip, $qtssport, $settingsPath."rtsp_port", 80);
		}
	}
	
	$confirmMessage = $messages{'PortSetSavedText'};
}

sub SaveLogSettings {
	my $messHash = adminprotolib::GetMessageHash();
	my %messages = %$messHash;
	my $errorPath = "/admin/server/qtssSvrPreferences/";
	my $accessPath = "/admin/server/qtssSvrModuleObjects/QTSSAccessLogModule/qtssModPrefs/";
	my $data = '';
	$nextFilename = 'log_settings.html';
	
	if ($query->{'qtssErrorLogging'} ne $query->{'qtssErrorLogging_shadow'}) {
		if ($query->{'qtssErrorLogging'} eq 'true') {
			$status = &adminprotolib::SetAttribute($data, $messHash, $authheader, $qtssip, $qtssport, $errorPath."error_logging", true);
		}
		else {
			$status = &adminprotolib::SetAttribute($data, $messHash, $authheader, $qtssip, $qtssport, $errorPath."error_logging", false);
		}
	}
	
	if ($query->{'qtssErrorLogInterval'} ne $query->{'qtssErrorLogInterval_shadow'}) {
		$status = &adminprotolib::SetAttribute($data, $messHash, $authheader, $qtssip, $qtssport, $errorPath."error_logfile_interval", $query->{'qtssErrorLogInterval'});
	}
	
	if ($query->{'qtssErrorLogSize'} ne $query->{'qtssErrorLogSize_shadow'}) {
		$status = &adminprotolib::SetAttribute($data, $messageHash, $authheader, $qtssip, $qtssport, $errorPath."error_logfile_size", ($query->{'qtssErrorLogSize'} * 1024));
	}
	
	if ($query->{'qtssRequestLogging'} ne $query->{'qtssRequestLogging_shadow'}) {
		if ($query->{'qtssRequestLogging'} eq 'true') {
			$status = &adminprotolib::SetAttribute($data, $messHash, $authheader, $qtssip, $qtssport, $accessPath."request_logging", true);
		}
		else {
			$status = &adminprotolib::SetAttribute($data, $messHash, $authheader, $qtssip, $qtssport, $accessPath."request_logging", false);
		}
	}
	
	if ($query->{'qtssRequestLogInterval'} ne $query->{'qtssRequestLogInterval_shadow'}) {
		$status = &adminprotolib::SetAttribute($data, $messHash, $authheader, $qtssip, $qtssport, $accessPath."request_logfile_interval", $query->{'qtssRequestLogInterval'});
	}
	
	if ($query->{'qtssRequestLogSize'} ne $query->{'qtssRequestLogSize_shadow'}) {
		$status = &adminprotolib::SetAttribute($data, $messageHash, $authheader, $qtssip, $qtssport, $accessPath."request_logfile_size", ($query->{'qtssRequestLogSize'} * 1024));
	}
	
	$filename = 'log_settings.html';
	$confirmMessage = $messages{'LogSetSavedText'};
}

sub ChangePassword {
	my $messHash = adminprotolib::GetMessageHash();
	my %messages = %$messHash;
	my $usersFileAttributePath = "/server/qtssSvrModuleObjects/QTSSAccessModule/qtssModPrefs/modAccess_usersfilepath";
	my $groupsFileAttributePath = "/server/qtssSvrModuleObjects/QTSSAccessModule/qtssModPrefs/modAccess_groupsfilepath";
	my $usersFilePath = '';
	my $groupsFilePath = '';
	my $qtssPasswdName = $ENV{"QTSSADMINSERVER_QTSSQTPASSWD"};
	my $data = '';
	my $line = '';
	my $oldUsername = $query->{'old_username'};
	my $newUsername = $query->{'new_user'};
	my $groupsFileText = '';
	my $usersFileText = '';
	$nextFilename = 'change_password.html';
	
	# if username or password is blank
	if (($query->{'new_user'} eq '') or ($query->{'new_password1'} eq '')) {
		$dialogHeader = $messages{'SetupAssistNoUsernameHeader'};
		$dialogText = $messages{'SetupAssistNoUsername'};
		return;
	}
	
	# if username has more than 255 characters
	if (length($query->{'new_user'}) > 255) {
		$dialogHeader = $messages{'ChPassUsernameNotLongerThan255Header'};
		$dialogText = $messages{'ChPassUsernameNotLongerThan255Text'};
		return;
	}
	
	# if username has a colon
	if ($query->{'new_user'} =~ /:/) {
		$dialogHeader = $messages{'ChPassUsernameCannotHaveColonHeader'};
		$dialogText = $messages{'ChPassUsernameCannotHaveColonText'};
		return;
	}
	
	# if username or password has a single or a double quote
	if ( ($query->{'new_user'} =~ /['"]/) || ($query->{'new_password1'} =~ /['"]/) ) {
		$dialogHeader = $messages{'ChPassCannotHaveQuotesHeader'};
		$dialogText = $messages{'ChPassCannotHaveQuotesText'};
		return;
	}
	
	# if password has more than 80 characters
	if (length($query->{'new_password1'}) > 80) {
		$dialogHeader = $messages{'ChPassNotLongerThan80Header'};
		$dialogText = $messages{'ChPassNotLongerThan80Text'};
		return;
	}
	
	# if old username:password doesn't match the current username:password
	if (encodeBase64($oldUsername.':'.$query->{'old_password'}) ne getCookie('qtsspassword')) {
		$dialogHeader = $messages{'ChPassOldPasswdWrongHeader'};
		$dialogText = $messages{'ChPassOldPasswdWrongText'};
		return;
	}
	
	# if new password #1 and new password #2 don't match
	if ($query->{'new_password1'} ne $query->{'new_password2'}) {
		$dialogHeader = $messages{'ChPassNoMatchHeader'};
		$dialogText = $messages{'ChPassNoMatchText'};
		return;
	}
	
	my $status = &adminprotolib::EchoData($groupsFilePath, $messHash, $authheader, $qtssip, $qtssport, "/modules/admin$groupsFileAttributePath", "/modules/admin$groupsFileAttributePath");

	if ($status != 200) {
		$dialogHeader = $messages{'ChPassErrorHeader'};
		$dialogText = $messages{'ChPassErrorText'}." ($status - $data)";
		return;
	}
	
	$status = &adminprotolib::EchoData($usersFilePath, $messHash, $authheader, $qtssip, $qtssport, "/modules/admin$usersFileAttributePath", "/modules/admin$usersFileAttributePath");

	if ($status != 200) {
		$dialogHeader = $messages{'ChPassErrorHeader'};
		$dialogText = $messages{'ChPassErrorText'}." ($status - $data)";
		return;
	}
	
	open(FILEHDL, "$groupsFilePath") or die "Can't open groups file '$groupsFilePath'!";
	while ($line = <FILEHDL>) {
		$groupsFileText .= $line;
	}
	close(FILEHDL);            
	my $quotedOldUsername = quotemeta($oldUsername);
	$groupsFileText =~ s/([ \t:]+)$quotedOldUsername([\r\n\s]+)/$1$newUsername$2/;
	
	$status = &adminprotolib::SetPassword($data, $messageHash, $authheader, $qtssip, $qtssport, $usersFileAttributePath, $query->{'new_password1'}, $qtssPasswdName, $newUsername);
	sleep(2);

	if ($status != 200) {
		$dialogHeader = $messages{'ChPassErrorHeader'};
		$dialogText = $messages{'ChPassErrorText'}." ($status - $data)";
		return;
	}
	
	open(FILEHDL, ">$groupsFilePath") or die "Can't open groups file '$groupsFilePath'!";
	print FILEHDL $groupsFileText;
	close(FILEHDL);
	FixFileGroup($groupsFilePath);
	
	$newcookieval = encodeBase64($newUsername.':'.$query->{'new_password1'});
	$cookie = 'qtsspassword='.$newcookieval.';path=/';
	$auth = $newcookieval;
	$authheader = "Authorization: Basic $auth\r\n"; 
	
	if ($oldUsername ne $newUsername)
	{
		&adminprotolib::DeleteUsername($data, $messageHash, $authheader, $qtssip, $qtssport, $usersFileAttributePath, $qtssPasswdName, $oldUsername);
	}
	
	# $confirmMessage = $messages{'ChPassSavedText'};
	$filename = 'change_password_redirect.html';
 
}

sub ChangeBroadcastPassword {
	my $messHash = adminprotolib::GetMessageHash();
	my %messages = %$messHash;
	my $filedelim = &playlistlib::GetFileDelimChar();
	my $moviesFolderPath;
	my $status = &adminprotolib::EchoData($moviesFolderPath, $messHash, $authheader, $qtssip, $qtssport, "/modules/admin/server/qtssSvrPreferences/movie_folder", "movie_folder");
	my $accessFilename;
	$status = &adminprotolib::EchoData($accessFilename, $messHash, $authheader, $qtssip, $qtssport, "/modules/admin/server/qtssSvrModuleObjects/QTSSAccessModule/qtssModPrefs/modAccess_qtaccessfilename", "modAccess_qtaccessfilename");
	my $usersFilename;
	$status = &adminprotolib::EchoData($usersFilename, $messHash, $authheader, $qtssip, $qtssport, "/modules/admin/server/qtssSvrModuleObjects/QTSSAccessModule/qtssModPrefs/modAccess_usersfilepath", "modAccess_usersfilepath");
	my $groupsFilename;
	$status = &adminprotolib::EchoData($groupsFilename, $messHash, $authheader, $qtssip, $qtssport, "/modules/admin/server/qtssSvrModuleObjects/QTSSAccessModule/qtssModPrefs/modAccess_groupsfilepath", "modAccess_groupsfilepath");
	$moviesFolderPath =~ s/[\/\\]$//o;
	my $filename = "$moviesFolderPath$filedelim$accessFilename";
	my $viewingUsersArrayRef = &passwordutils::GetViewingRestrictionsFromFile($filename);
	my @viewingUsersArray = @$viewingUsersArrayRef;
	my $viewingUsersString = join(' ', @viewingUsersArray);
	my $broadcastUsersArrayRef = &passwordutils::GetBroadcastRestrictionsFromFile($filename);
	my @broadcastUsersArray = @$broadcastUsersArrayRef;
	my $oldBroadcastUser = '';
	my $broadcastRestrictionString = '';
	my ($currentAdminUsername, $currentAdminPass) = split(/:/, b64decode($auth));
	my $qtpasswdpath = $ENV{"QTSSADMINSERVER_QTSSQTPASSWD"};
	
	if ($broadcastUsersArray[1] eq 'user') {
		$oldBroadcastUser = $broadcastUsersArray[2];
	}
	
	# change the password in the passwords file
	# work on a copy if it's the current admin user
	if ($query->{'new_user'} ne $oldBroadcastUser) {
		if ($oldBroadcastUser ne $currentAdminUsername) {
			&passwordutils::DeleteUser($qtpasswdpath, $usersFilename, $groupsFilename, $oldBroadcastUser);
		}
		if (($query-{'allowUnrestrictedBroadcast'} ne '1') && ($query->{'new_user'} ne '')) {
			&passwordutils::AddOrEditUser($qtpasswdpath, $usersFilename, $query->{'new_user'}, $query->{'new_password1'});
		}
	}

	if ($query->{'allowUnrestrictedBroadcast'} eq '1') {
		$broadcastRestrictionString = "require any-user";
	}
	elsif (($query->{'new_user'} ne '') && ($query->{'new_password1'} ne '')) {
		$broadcastRestrictionString = "require user " . $query->{'new_user'};
	}
	my $viewingRestrictionString = join(' ', @$viewingUsersArrayRef);
	&passwordutils::WriteRestrictionsToFile($filename, $broadcastRestrictionString, $viewingRestrictionString);
	
	$confirmMessage = $messages{'ChMP3PassSavedText'};
	$filename = 'general_settings.html';
}

sub ChangeMP3Password {
	my $messHash = adminprotolib::GetMessageHash();
	my %messages = %$messHash;
	my $MP3BroadcastPasswordPath = "/admin/server/qtssSvrModuleObjects/QTSSMP3StreamingModule/qtssModPrefs/mp3_broadcast_password";
	my $qtssPasswdName = $ENV{"QTSSADMINSERVER_QTSSQTPASSWD"};
	my $qtssAdmin = $ENV{"QTSSADMINSERVER_QTSSADMIN"};
	my $data = '';
	$nextFilename = 'change_mp3_password.html';

	if ($query->{'new_password1'} ne $query->{'new_password2'}) {
		$dialogHeader = $messages{'ChMP3PassNoMatchHeader'};
		$dialogText = $messages{'ChMP3PassNoMatchText'};
		return;
	}
	
	$status = &adminprotolib::SetAttribute($data, $messHash, $authheader, $qtssip, $qtssport, $MP3BroadcastPasswordPath, $query->{'new_password1'});
	
	$confirmMessage = $messages{'ChMP3PassSavedText'};
	$filename = $query->{'replaceFilename'};
	if ($filename eq '') {
		$filename = 'general_settings.html';
	}
}

# AssistSetPassword
# returns	0 => failure
#			1 => success
sub AssistSetPassword {
	my $messHash = adminprotolib::GetMessageHash();
	my %messages = %$messHash;
	my $usersFileAttributePath = "/server/qtssSvrModuleObjects/QTSSAccessModule/qtssModPrefs/modAccess_usersfilepath";
	my $groupsFileAttributePath = "/server/qtssSvrModuleObjects/QTSSAccessModule/qtssModPrefs/modAccess_groupsfilepath";
	my $usersFilePath = '';
	my $groupsFilePath = '';
	my $qtssPasswdName = $ENV{"QTSSADMINSERVER_QTSSQTPASSWD"};
	my $qtssAdmin = $ENV{"QTSSADMINSERVER_QTSSADMIN"};
	my $data = '';
	my $line = '';
	my $newUsername = $query->{'new_user'};
	my $newPassword = $query->{'new_password1'};
	my ($oldUsername, $authpass) = split(/:/, b64decode($auth));
	$nextFilename = 'setup_assistant.html';
	
	# if username or password is blank
	if (($query->{'new_user'} eq '') or ($query->{'new_password1'} eq '')) {
		$dialogHeader = $messages{'SetupAssistNoUsernameHeader'};
		$dialogText = $messages{'SetupAssistNoUsername'};
		return 0;
	}
	
	# if username has more than 255 characters
	if (length($query->{'new_user'}) > 255) {
		$dialogHeader = $messages{'ChPassUsernameNotLongerThan255Header'};
		$dialogText = $messages{'ChPassUsernameNotLongerThan255Text'};
		return 0;
	}
	
	# if username has a colon
	if ($query->{'new_user'} =~ /:/) {
		$dialogHeader = $messages{'ChPassUsernameCannotHaveColonHeader'};
		$dialogText = $messages{'ChPassUsernameCannotHaveColonText'};
		return 0;
	}
	
	# if username or password has a single quote or a double quote
	if ( ($query->{'new_user'} =~ /['"]/) || ($query->{'new_password1'} =~ /['"]/) ) {
		$dialogHeader = $messages{'ChPassCannotHaveQuotesHeader'};
		$dialogText = $messages{'ChPassCannotHaveQuotesText'};
		return 0;
	}
	
	# if password has more than 80 characters
	if (length($query->{'new_password1'}) > 80) {
		$dialogHeader = $messages{'ChPassNotLongerThan80Header'};
		$dialogText = $messages{'ChPassNotLongerThan80Text'};
		return 0;
	}
	
	# if new password #1 and new password #2 don't match
	if ($query->{'new_password1'} ne $query->{'new_password2'}) {
		$dialogHeader = $messages{'ChPassNoMatchHeader'};
		$dialogText = $messages{'ChPassNoMatchText'};
		return 0;
	}
	
	my $status = 200;
	
	if (($^O eq "darwin") and (-e "index.html") and (MacQTGroupsContainsAdminGroup() == 0)) {
		my $line = '';
		$groupsFileText = '';
		if (-e '/Library/QuickTimeStreaming/Config/qtgroups') {
			open(GROUPSFILE, '/Library/QuickTimeStreaming/Config/qtgroups') or die("Can't open groups file!");
			while ($line = <GROUPSFILE>) {
				$groupsFileText .= $line;
			}
			close(GROUPSFILE);
		}
		$groupsFileText .= "admin: $newUsername\n";
		$groupsFilePath = '/Library/QuickTimeStreaming/Config/qtgroups';
		my $extraargs = '';
		my $qtpasswdpath = $ENV{'QTSSADMINSERVER_QTSSQTPASSWD'};
		if (!(-e '/Library/QuickTimeStreaming/Config/qtusers')) {
			$extraargs = ' -c';
		}
		if(system("$qtpasswdpath$extraargs -p \'$newPassword\' \'$newUsername\'") != 0) {
			$dialogHeader = $messages{'ChPassErrorHeader'};
			$dialogText = $messages{'ChPassErrorText'};
			return 0;
		}
		else {
			$status = 200
		}
	}
	else {
		$status = &adminprotolib::EchoData($groupsFilePath, $messHash, $authheader, $qtssip, $qtssport, "/modules/admin$groupsFileAttributePath", "/modules/admin$groupsFileAttributePath");
		
		if ($status == 401) {
			$auth = encodeBase64('aGFja21l:aGFja21l');
			$authheader = "Authorization: Basic $auth\r\n";
			$oldUsername = 'aGFja21l';
			$status = &adminprotolib::EchoData($groupsFilePath, $messHash, $authheader, $qtssip, $qtssport, "/modules/admin$groupsFileAttributePath", "/modules/admin$groupsFileAttributePath");
		}
		
		if ($status != 200) {
			$dialogHeader = $messages{'ChPassErrorHeader'};
			$dialogText = $messages{'ChPassErrorText'}." ($status - $data)";
			return 0;
		}
			
		$status = &adminprotolib::EchoData($usersFilePath, $messHash, $authheader, $qtssip, $qtssport, "/modules/admin$usersFileAttributePath", "/modules/admin$usersFileAttributePath");
	
		if ($status != 200) {
			$dialogHeader = $messages{'ChPassErrorHeader'};
			$dialogText = $messages{'ChPassErrorText'}." ($status - $data)";
			return 0;
		}
		
		open(FILEHDL, "$groupsFilePath") or die "Can't open groups file '$groupsFilePath'!";
		while ($line = <FILEHDL>) {
			$groupsFileText .= $line;
		}
		close(FILEHDL);
		
		my $quotedOldUsername = quotemeta($oldUsername);
		$groupsFileText =~ s/([ \t:]+)$quotedOldUsername([\r\n\s]+)/$1$newUsername$2/;
		
		$status = &adminprotolib::SetPassword($data, $messageHash, $authheader, $qtssip, $qtssport, $usersFileAttributePath, $query->{'new_password1'}, $qtssPasswdName, $newUsername);
		
		if ($status != 200) {
			$dialogHeader = $messages{'ChPassErrorHeader'};
			$dialogText = $messages{'ChPassErrorText'}." ($status - $data)";
			return 0;
		}
	}
	
	open(FILEHDL, ">$groupsFilePath") or die "Can't open groups file '$groupsFilePath'!";
	print FILEHDL $groupsFileText;
	close(FILEHDL);
	FixFileGroup($groupsFileText);
	
	# set the cookie and the auth header before calling DeleteUsername as the server expects the new username:password now
	my $newcookieval = encodeBase64($newUsername.':'.$query->{'new_password1'});
	$cookie = 'qtsspassword='.$newcookieval.'; path=/';
	$auth = $newcookieval;
	$authheader = "Authorization: Basic $auth\r\n";
	
	if ($oldUsername ne $newUsername)
	{
		&adminprotolib::DeleteUsername($data, $messageHash, $authheader, $qtssip, $qtssport, $usersFileAttributePath, $qtssPasswdName, $oldUsername);
	}
		
	$dialogHeader = $messages{'ChPassSavedHeader'};
	$dialogText = $messages{'ChPassSavedText'};
	$filename = 'setup_assistant2.html';
	
	return 1;
}

sub StartPlaylist {
	my $messHash = adminprotolib::GetMessageHash();
	my %messages = %$messHash;
	my $curplaylist = $query->{'curplaylist'};
	my $isRunning = &playlistlib::GetPlayListState($curplaylist);
    my $filedelim = &playlistlib::GetFileDelimChar();
    my $plroot = &playlistlib::GetPLRootDir();
    my $filedelim = &playlistlib::GetFileDelimChar();
    my $targ = '';
    my $targline = '';
    my $plfiletext = '';
    my $success = 0;
	my $targ = "$plroot$curplaylist$filedelim$curplaylist";
	my $isRunning = &playlistlib::GetPlayListState($curplaylist);
	
	# open the playlist and re-save it so that the MP3 broadcast password is updated if necessary
	
	my $playlistdataref = &playlistlib::ParsePlayListEntry($curplaylist, $messHash);
	my $movieDir = '';
	my $mp3BroadcastPassword = '';
	my $status = adminprotolib::EchoData($movieDir, $messHash, $authheader, $qtssip, $qtssport, "/modules/admin/server/qtssSvrPreferences/movie_folder", "/modules/admin/server/qtssSvrPreferences/movie_folder");
	$status = adminprotolib::EchoData($mp3BroadcastPassword, $messHash, $authheader, $qtssip, $qtssport, "/modules/admin/server/qtssSvrModuleObjects/QTSSMP3StreamingModule/qtssModPrefs/mp3_broadcast_password", "/modules/admin/server/qtssSvrModuleObjects/QTSSMP3StreamingModule/qtssModPrefs/mp3_broadcast_password");
	if (&playlistlib::CreatePlayListEntry($curplaylist, $playlistdataref, $movieDir, $mp3BroadcastPassword) == 0) {
		$confirmMessage = '';
		$filename = 'confirm.html';
		$dialogHeader = $messages{'PLErrorHeader'};
		$dialogText = $messages{'PLErrorHeader'};
		$nextFilename = 'playlists.html';
		return;
	}
	
	# playlist is re-saved
	
	if ("$isRunning" ne 1) {
		open(PLFILE, "$targ.config");
		while ($targline = <PLFILE>) {
			$plfiletext .= $targline;
		}
		close(PLFILE);
		if ($plfiletext =~ /broadcast_genre /) {
			$isMP3 = 1;
		}
		else {
			$isMP3 = 0;
		}
		
	
		$success = &playlistlib::StartPlayList($curplaylist, $isMP3);
		

		if ($success != 1) {
			$filename = 'confirm.html';
			$nextFilename = 'playlists.html';
			$dialogHeader = $messages{'PLErrorHeader'};
			$dialogText = $messages{'PLErrorText'};
			return;
		}
		else
		{
			# successfully started the playlist!
			my $startfile = "$plroot$curplaylist$filedelim" . '.started';
			# create a file in the playlist directory called .started
			# which we shall delete when we stop the playlist later
			open(STARTFILE, ">$startfile");
			close(STARTFILE);
			FixFileGroup($startfile);
			chmod(0644, $startfile);
		}
	}
	# $confirmMessage = $messages{'PLChangedText'};
}

sub StopPlaylist
{
	my $messHash = adminprotolib::GetMessageHash();
	my %messages = %$messHash;
    my $plroot = &playlistlib::GetPLRootDir();
    my $filedelim = &playlistlib::GetFileDelimChar();
	my $curplaylist = $query->{'curplaylist'};
	my $isRunning = &playlistlib::GetPlayListState($curplaylist);
    my $filedelim = &playlistlib::GetFileDelimChar();
    my $targ = '';
    my $targline = '';
    my $plfiletext = '';
	my $targ = "$plroot$curplaylist$filedelim$curplaylist";
	my $isRunning = &playlistlib::GetPlayListState($curplaylist);
	
	if ("$isRunning" ne $startstop{$i})
	{
		# delete the file created when we started the playlist
		# even if we don't succeed in stopping the playlist
		# (which would only happen if we were reporting the wrong status
		# and the playlist was already stopped)
		my $startfile = "$plroot$curplaylist$filedelim" . '.started';
		if ( -e $startfile)
		{
			unlink($startfile);
		}
	
		if (&playlistlib::StopPlayList($curplaylist) != 1)
		{
			$dialogHeader = $messages{'PLErrorHeader'};
			$dialogText = $messages{'PLErrorText'};
			return;
		}
	}
	# $confirmMessage = $messages{'PLChangedText'};
}

sub ShowPlaylistLog {
	my $curplaylist = $query->{'curplaylist'};
	$playlistErrorLogText = &playlistlib::EmitPlayListErrLogFile($curplaylist);
}

sub PLOpenDir {
	my $messHash = adminprotolib::GetMessageHash();
	my %messages = %$messHash;
	my $genreArrayRef = adminprotolib::GetGenreArray();
	$curplaylist = $query->{'curplaylist'};
	$movieDir = $query->{'submitcurrentdir'};
}

sub GetPlaylist {
	my $messHash = adminprotolib::GetMessageHash();
	my %messages = %$messHash;
	my $genreArrayRef = adminprotolib::GetGenreArray();
	$curplaylist = $query->{'curplaylist'};
	my $playlistdataref = &playlistlib::ParsePlayListEntry($curplaylist, $messHash);
	my @playlistdata = @$playlistdataref;
	my $status = adminprotolib::EchoData($movieDir, $messHash, $authheader, $qtssip, $qtssport, "/modules/admin/server/qtssSvrPreferences/movie_folder", "/modules/admin/server/qtssSvrPreferences/movie_folder");
	$currentDir = $movieDir;
	$plfilename = $playlistdata[0];
	$plmode = $playlistdata[1];
	$pllogging = $playlistdata[2];
	$plfilesref = $playlistdata[3];
	@plfiles = @$plfilesref;
	$plrep = $playlistdata[4];
	$plgenre = $playlistdata[5];
	$plbroadcastip = $playlistdata[6];
	$plbroadcastusername = $playlistdata[7];
	$plbroadcastpassword = $playlistdata[8];
	$pltitle = $playlistdata[9];
	if ($plgenre eq '') {
		$isMP3 = 0;
		$doctitle = $messages{'PLMoviePlaylistDetails'};
		$extraFieldLabel = '';
		$extraFieldHTML = '<input type=hidden name=PLGenre value="">';
		$playlistUsernameHTML = '<tr><td align=left>&nbsp;</td><td align=right>'.$messages{'Username'}.'</td><td align=left><input type=text name=plbroadcastusername value="' . $plbroadcastusername . '"></td></tr>';
	}
	else {
		$isMP3 = 1;
		$doctitle = $messages{'PLMP3PlaylistDetails'};
		$extraFieldLabel = $messages{'PLGenre'};
		$extraFieldHTML = '<select name=PLGenre>'.&playlistlib::GetGenreOptions($plgenre, $messages{'PLDefaultGenre'}, $genreArrayRef).'</select>';
		$playlistUsernameHTML = '';
	}
	if ($plbroadcastip eq '127.0.0.1') {
		$plexternal = '0';
		$plbroadcastusername = '';
		$plbroadcastpassword = '';
	}
	else {
		$plexternal = '1';
	}
}

sub CreatePlaylist {
	my $messHash = adminprotolib::GetMessageHash();
	my %messages = %$messHash;
    my $plroot = &playlistlib::GetPLRootDir();
	my $fileDelimChar = &playlistlib::GetFileDelimChar();
	my $movieDir = '';
	my $mp3BroadcastPassword = '';
	my $status = adminprotolib::EchoData($movieDir, $messHash, $authheader, $qtssip, $qtssport, "/modules/admin/server/qtssSvrPreferences/movie_folder", "/modules/admin/server/qtssSvrPreferences/movie_folder");
	my $status = adminprotolib::EchoData($mp3BroadcastPassword, $messHash, $authheader, $qtssip, $qtssport, "/modules/admin/server/qtssSvrModuleObjects/QTSSMP3StreamingModule/qtssModPrefs/mp3_broadcast_password", "/modules/admin/server/qtssSvrModuleObjects/QTSSMP3StreamingModule/qtssModPrefs/mp3_broadcast_password");
	my @plcontents = ();
	my $item = '';
	my $plname = $query->{'qtssCurPlaylistName'};
	my $i = 2;
		
	if ($plname eq '') {
		# no playlist filename yet... means this is a new playlist
		# set it to the playlist title
		$plname = $query->{'qtssCurPlaylistTitle'};
		# drop all non-alphanumeric characters
		$plname =~ s/[^a-zA-Z0-9]//go;
		if (($plname eq '') or (-e "$plroot$plname$fileDelimChar")) {
			while (-e "$plroot$plname$fileDelimChar$i") {
				$i++;
			}
			$plname = "$plname$i";
		}
	}
	else {
		if (-e "$plroot$plname$fileDelimChar$plname.err") {
			unlink "$plroot$plname$fileDelimChar$plname.err";
		}
	}
	
	$i = 0;
	$nextFilename = 'playlists.html';
	$confirmMessage = $messages{'PLCreatedText'};
	my $qtssCurPlaylistURL = $plname.'.sdp';
	if ($query->{'qtssCurPlaylistURL'} ne '') {
		$qtssCurPlaylistURL = $query->{'qtssCurPlaylistURL'};
	}
	my $qtssCurPlaylistMode = $query->{'qtssCurPlaylistMode'};
	my $playlistFiles = $query->{'submitplaylistfiles'};
	$playlistFiles =~ s/%(..)/pack("c",hex($1))/ge;
	@plcontents = split(/\t/, $playlistFiles);
	my @submitplaylistweights = split(/\t/, $query->{'submitplaylistweights'});
	foreach $item (@plcontents) {
		$item = "$item:$submitplaylistweights[$i++]";
	}
	my $qtssCurPlaylistRep = '1';
	if ($query->{'qtssCurPlaylistRep'} ne '') {
		$qtssCurPlaylistRep = $query->{'qtssCurPlaylistRep'};
	}
	my $destipaddr = $query->{'plbroadcastip'};
	my $broadcastusername = $query->{'plbroadcastusername'};
	my $broadcastpassword = $query->{'plbroadcastpassword'};
	if (($query->{'plexternal'} ne '1') or ($destipaddr eq '')) {
		$destipaddr = '127.0.0.1';
		$broadcastusername = '';
		$broadcastpassword = '';
	}
	my @plsettings = ($qtssCurPlaylistURL,$qtssCurPlaylistMode,$query->{'pllogging'},\@plcontents,$qtssCurPlaylistRep,$query->{'PLGenre'},$destipaddr,$broadcastusername,$broadcastpassword,$query->{'qtssCurPlaylistTitle'});
	if (&playlistlib::CreatePlayListEntry($plname, \@plsettings, $movieDir, $mp3BroadcastPassword) == 0) {
		$confirmMessage = '';
		$filename = 'confirm.html';
		$dialogHeader = $messages{'PLCreateErrorHeader'};
		$dialogText = $messages{'PLCreateErrorText'};
		$nextFilename = 'playlists.html';
	}
}

# NewPlaylist expects the var isMP3 to be set to 0 or 1

sub NewPlaylist {
	my $messHash = adminprotolib::GetMessageHash();
	my %messages = %$messHash;
	my $genreArrayRef = &adminprotolib::GetGenreArray();
	my @genreArray = @$genreArrayRef;
	my $status = adminprotolib::EchoData($movieDir, $messHash, $authheader, $qtssip, $qtssport, "/modules/admin/server/qtssSvrPreferences/movie_folder", "/modules/admin/server/qtssSvrPreferences/movie_folder");
	$currentDir = useDefaultIfBlank($query->{'currentdir'}, $movieDir);
	$plrep = 1;
	@plfiles = ();
	$plrep = '1';
	$curplaylist = '';
	$pltitle = '';
	$plfilename = '';
	$plmode = '';
	$pllogging = '';
	$plbroadcastip = '127.0.0.1';
	$plbroadcastusername = '';
	$plbroadcastpassword = '';
	if ($isMP3 == 1) {
		$doctitle = $messages{'PLMP3PlaylistDetails'};
		$extraFieldLabel = $messages{'PLGenre'};
		$extraFieldHTML = '<select name=PLGenre>'.&playlistlib::GetGenreOptions('', $messages{'PLDefaultGenre'}, $genreArrayRef).'</select>';
		$playlistUsernameHTML = '';
		$pltitle = $messages{'PLDefaultPlaylistName'};
		$plfilename = $messages{'PLDefaultMP3PlaylistMountPoint'};
	}
	else {
		$doctitle = $messages{'PLMoviePlaylistDetails'};
		$extraFieldLabel = '';
		$extraFieldHTML = '';
		$playlistUsernameHTML = '<tr><td align=left>&nbsp;</td><td align=right>'.$messages{'Username'}.'</td><td align=left><input type=text name=plbroadcastusername></td></tr>';
		$pltitle = $messages{'PLDefaultPlaylistName'};
		$plfilename = $messages{'PLDefaultMoviePlaylistSDP'};
	}
}

sub RefreshPlaylistDir() {
	my $messHash = adminprotolib::GetMessageHash();
	my %messages = %$messHash;
	my $genreArrayRef = &adminprotolib::GetGenreArray();
	my @genreArray = @$genreArrayRef;
	my $i = 0;
	my $playlistFiles = $query->{'submitplaylistfiles'};
	$playlistFiles =~ s/%(..)/pack("c",hex($1))/ge;
	my @plcontents = split(/\t/, $playlistFiles);
	my @submitplaylistweights = split(/\t/, $query->{'submitplaylistweights'});
	@plfiles = ();
	my $status = adminprotolib::EchoData($movieDir, $messHash, $authheader, $qtssip, $qtssport, "/modules/admin/server/qtssSvrPreferences/movie_folder", "/modules/admin/server/qtssSvrPreferences/movie_folder");
	foreach $item (@plcontents) {
		push(@plfiles, "$item:$submitplaylistweights[$i++]");
	}
	$currentDir = $query->{'submitcurrentdir'};
	$currentDir =~ s/%(..)/pack("c",hex($1))/ge;
	$query->{'submitcurrentdir'} = '';
	$isMP3 = $query->{'isMP3'};
	$plrep = $query->{'qtssCurPlaylistRep'};
	$curplaylist = $query->{'qtssCurPlaylistName'};
	$pltitle = $query->{'qtssCurPlaylistTitle'};
	$plfilename = $query->{'qtssCurPlaylistURL'};
	$plmode = $query->{'qtssCurPlaylistMode'};
	$plrep = $query->{'qtssCurPlaylistRep'};
	$plgenre = $query->{'PLGenre'};
	$pllogging = $query->{'pllogging'};
	$plbroadcastip = $query->{'plbroadcastip'};
	$plbroadcastusername = $query->{'plbroadcastusername'};
	$plbroadcastpassword = $query->{'plbroadcastpassword'};
	
	if ($isMP3 == 0) {
		$doctitle = $messages{'PLMoviePlaylistDetails'};
		$extraFieldLabel = '';
		$extraFieldHTML = '<input type=hidden name=PLGenre value="">';
		$playlistUsernameHTML = '<tr><td>&nbsp;</td><td align=right>'.$messages{'Username'}.'</td><td><input type=text name=plbroadcastusername value="' . $plbroadcastusername . '"></td></tr>';
	}
	else {
		$doctitle = $messages{'PLMP3PlaylistDetails'};
		$extraFieldLabel = $messages{'PLGenre'};
		$extraFieldHTML = '<select name=PLGenre>'.&playlistlib::GetGenreOptions($plgenre, $messages{'PLDefaultGenre'}, $genreArrayRef).'</select>';
		$playlistUsernameHTML = '';
	}
	if (($plbroadcastip eq '127.0.0.1') or ($plbroadcastip eq '')) {
		$plexternal = '0';
		$plbroadcastusername = '';
		$plbroadcastpassword = '';
	}
	else {
		$plexternal = '1';
	}
}

sub DeletePlaylist {
	my $messHash = adminprotolib::GetMessageHash();
	my %messages = %$messHash;
	if (&playlistlib::RemovePlaylistDir($query->{'curplaylist'}) == 1) {
		$confirmText = $messages{'PLDeleteText'};
	}
	else {
		$filename = 'confirm.html';
		$nextFilename = 'playlists.html';
		$dialogHeader = $messages{'PLDeleteErrorHeader'};
		$dialogText = $messages{'PLDeleteErrorText'};
	}
}

sub ResetErrorLog {
	my $chdelim = &playlistlib::GetFileDelimChar();
	my $messHash = adminprotolib::GetMessageHash();	
	my %messages = %$messHash;
	my $responseText = '';
	my $status = adminprotolib::GetData($responseText, $messHash, $authheader, $qtssip, $qtssport, '/modules/admin/server/qtssSvrPreferences/error_logfile_dir');
	$_ = $responseText;
	$confirmMessage = 'redirect';
	if (!(/error_logfile_dir="([^"]+)"/)) {
		die('Error getting logfile dir.');
	}
	my $dirname = $1;
	$status = adminprotolib::GetData($responseText, $messHash, $authheader, $qtssip, $qtssport, '/modules/admin/server/qtssSvrPreferences/error_logfile_name');
	$_ = $responseText;
	if (!(/error_logfile_name="([^"]+)"/)) {
		die('Error getting filename.');
	}
	$logname = $1;
	$logfilename = $dirname . $chdelim . $logname . '.log';
	$logfilename =~ s/\/{2,}/\//g; # remove duplicate slashes
	if (-e $logfilename) {
		$rolldatestr = sprintf("%02d%02d%02d", sub {($_[5] % 100, $_[4]+1, $_[3])}->(localtime));
		$rollfilenumber = 0;
		$rollfilename = "$dirname$chdelim" . $logname . ".$rolldatestr" . '000.log';
		while (-e $rollfilename) {
			$rollfilenumber++;
			$rollfilename = "$dirname$chdelim" . $logname . ".$rolldatestr" . sprintf("%03d", $rollfilenumber) . '.log';
		}
		$rollfilename =~ s/\/{2,}/\//g; # remove duplicate slashes
		`/bin/mv "$logfilename" "$rollfilename"`;
		#unlink($dirname);
	}
	$confirmMessage = $messages{'ErrorLogResetConf'};
}

sub SaveBroadcasterSettings {
	my $restartBroadcaster = 0;
	my $changedNetworkSetting = 0;
	my %messages = %$messageHash;
	if (($broadcasterConn->state != 0) && ($theAction eq 'SaveBroadcasterSettings')) {
		$restartBroadcaster = 1;
		$broadcasterConn->stopBroadcast;
	}
	if ($query->{'qtbCurrentAudioPreset'} ne $query->{'qtbCurrentAudioPreset_shadow'}) {
		$changedNetworkSetting = 1;
		&broadcasterlib::SetCurrentPresetForType($broadcasterConn, 0, $query->{'qtbCurrentAudioPreset'});
	}
	if ($query->{'qtbCurrentVideoPreset'} ne $query->{'qtbCurrentVideoPreset_shadow'}) {
		$changedNetworkSetting = 1;
		&broadcasterlib::SetCurrentPresetForType($broadcasterConn, 1, $query->{'qtbCurrentVideoPreset'});
	}
	if ($query->{'qtbAudioStreamEnabled'} ne $query->{'qtbAudioStreamEnabled_shadow'}) {
		&broadcasterlib::SetStreamEnabledForType($broadcasterConn, 0, $query->{'qtbAudioStreamEnabled'});
	}
	if ($query->{'qtbVideoStreamEnabled'} ne $query->{'qtbVideoStreamEnabled_shadow'}) {
		&broadcasterlib::SetStreamEnabledForType($broadcasterConn, 1, $query->{'qtbVideoStreamEnabled'});
	}
	if ($query->{'qtbRecordingPath'} ne $query->{'qtbRecordingPath_shadow'}) {
		&broadcasterlib::SetRecordingPath($broadcasterConn, $query->{'qtbRecordingPath'});
	}
	if ($query->{'qtbNetworkPresetSDPFilename'} ne $query->{'qtbNetworkPresetSDPFilename_shadow'}) {
		$changedNetworkSetting = 1;
		&broadcasterlib::SetNetworkFilepath($query->{'qtbNetworkPresetSDPFilename'});
	}
	if ($query->{'qtbBufferDelay'} ne $query->{'qtbBufferDelay_shadow'}) {
		$changedNetworkSetting = 1;
		&broadcasterlib::SetBufferDelay($query->{'qtbBufferDelay'});
	}
	if ($changedNetworkSetting == 1) {
		&broadcasterlib::RereadSettingsFile($broadcasterConn);
	}
	if (($restartBroadcaster) && ($theAction eq 'SaveBroadcasterSettings')) {
		StartStopBroadcast();
	}
	if ($confirmMessage ne $messages{'QTBErrBroadcastSettings'}) {
		$confirmMessage = $messages{'QTBConfSaved'};
	}
}

sub StartStopBroadcast {
	if ($theAction eq 'StartStopBroadcast') {
		SaveBroadcasterSettings();
	}
	my %messages = %$messageHash;
	my $messageName = &broadcasterlib::StartStopBroadcast($broadcasterConn);
	$confirmMessage = $messages{$messageName};
	if ($messageName eq '') { # couldn't start broadcast
		$confirmMessage = $messages{'QTBErrBroadcastSettings'};
	}
	if ($messageName eq 'QTBConfStarted') {
		my $value = '/modules/admin/server/qtssSvrDefaultDNSName';
		my $data = '';
		my $status = adminprotolib::EchoData($data, $messHash, $authheader, $qtssip, $qtssport, $value, $value);
		&broadcasterlib::WriteRefMovie($data);
		my $cycles = 0;
		my $continue = 1;
		my $state;
		while ($continue == 1) {
			sleep(1);
			$state = &broadcasterlib::GetBroadcasterStateID($broadcasterConn);
			$cycles = $cycles + 1;
			if (($cycles > 7) || ($state == 3)) {
				$continue = 0;
			}
		}
		if ($state != 3) {
			$confirmMessage = $messages{'QTBErrBroadcastSettings'};
		}
	}
}

sub RestartBroadcaster {
	eval("require 'broadcaster_lib.pl';");
	&broadcasterlib::KillServer(1);
	sleep(1);
	ConnectToBroadcaster(1);
}


# this routine performs an action, if there is any
sub PerformAction {
	my $messHash = adminprotolib::GetMessageHash();
	my %messages = %$messHash;
	if ($theAction eq 'refreshmessages') {
		# refresh the message hashes from the correct files.
		&streamingadminserver::LoadMessageHashes();
	}
	elsif ($theAction eq 'login') {
		$cookie = 'qtsspassword='.encodeBase64($query->{'qtssusername'}.':'.$query->{'qtsspassword'}).'; path=/';
		return true;
	}
	elsif ($theAction eq 'logout') {
		$cookie = 'qtsspassword=; path=/';
		return true;
	}
	elsif ($theAction eq 'StartStopServer') {
		StartStopServer();
	}
	elsif ($theAction eq 'restartadminserver') {
		restart_streamingadminserver();
		return true;
	}
	elsif ($theAction eq 'setrefresh') {
		if (getCookie('pageRefreshInterval') ne $query->{'pageRefreshInterval'}) {
			$cookie = 'pageRefreshInterval='.$query->{'pageRefreshInterval'}.'; path=/';
		}
		else {
			$cookie = 'displayCount='.$query->{'displayCount'}.'; path=/';
		}
		return true;
	}
	elsif ($theAction eq 'setconnusersort') {
		$cookie = 'connUserSort='.$query->{'connUserSort'};
	}
	elsif ($theAction eq 'setrelaystatsort') {
		$cookie = 'relayStatSort='.$query->{'relayStatSort'};
	}
	elsif ($theAction eq 'SaveGeneralSettings') {
		SaveGeneralSettings();
	}
	elsif ($theAction eq 'ChangePassword') {
		ChangePassword();
	}
	elsif ($theAction eq 'ConfirmPassChanged') {
		$confirmMessage = $messages{'ChPassSavedText'};
	}
	elsif ($theAction eq 'ChangeMP3Password') {
		ChangeMP3Password();
	}
	elsif ($theAction eq 'ChangeBroadcastPassword') {
		ChangeBroadcastPassword();
	}
	elsif ($theAction eq 'SaveLogSettings') {
		SaveLogSettings();
	}
	elsif ($theAction eq 'SavePortSettings') {
		SavePortSettings();
	}
	elsif ($theAction eq 'StartPlaylist') {
		StartPlaylist();
	}
	elsif ($theAction eq 'StopPlaylist') {
		StopPlaylist();
	}
	elsif ($theAction eq 'ShowPlaylistLog') {
		ShowPlaylistLog();
	}
	elsif ($theAction eq 'GetPlaylist') {
		GetPlaylist();
	}
	elsif ($theAction eq 'CreatePlaylist') {
		CreatePlaylist();
	}
	elsif ($theAction eq 'NewMP3Playlist') {
		$isMP3 = 1;
		NewPlaylist();
	}
	elsif ($theAction eq 'NewMoviePlaylist') {
		$isMP3 = 0;
		NewPlaylist();
	}
	elsif ($theAction eq 'RefreshPlaylistDir') {
		RefreshPlaylistDir();
	}
	elsif ($theAction eq 'DeletePlaylist') {
		DeletePlaylist();
	}
	elsif ($theAction eq 'getValsForRelay') {
		getValsForRelay();
	}
	elsif ($theAction eq 'getNewRelay') {
		getNewRelay();
	}
	elsif ($theAction eq 'getRelayDestData') {
		getRelayDestData();
	}
	elsif ($theAction eq 'SetRelayDestData') {
		SetRelayDestData();
	}
	elsif ($theAction eq 'AddRelayDestination') {
		AddRelayDestination();
	}
	elsif ($theAction eq 'DeleteRelayDest') {
		DeleteRelayDest();
	}
	elsif ($theAction eq 'SaveRelay') {
		SaveRelay();
	}
	elsif ($theAction eq 'DeleteRelay') {
		DeleteRelay();
		$confirmMessage = $messages{'RelayDeleteText'};
	}
	elsif ($theAction eq 'RunAssistant') {
		RunAssistant();
		if (-e "index.html") {
			unlink("index.html");
		}
	}
	elsif ($theAction eq 'AssistSetPassword') {
		my $setupAssistantPasswordSuccess = AssistSetPassword();
		if (($setupAssistantPasswordSuccess == 1) && (-e "index.html")) {
			unlink("index.html");
		}
	}
	elsif ($theAction eq 'ResetErrorLog') {
		ResetErrorLog();
	}
	elsif ($theAction eq 'SaveBroadcasterSettings') {
		SaveBroadcasterSettings();
	}
	elsif ($theAction eq 'StartStopBroadcast') {
		StartStopBroadcast();
	}
	elsif ($theAction eq 'StartBroadcaster') {
		eval("require 'broadcaster_lib.pl';");
		ConnectToBroadcaster(1);
		sleep(3);
	}
	elsif ($theAction eq 'RestartBroadcaster') {
		RestartBroadcaster();
	}
	elsif ($theAction eq 'QuitBroadcaster') {
		eval("require 'broadcaster_lib.pl';");
		ConnectToBroadcaster(0);
		if (!(!$broadcasterConn || !$$broadcasterConn)) {
			&broadcasterlib::QuitBroadcaster($broadcasterConn);
		}
		my %messages = %$messageHash;
		$confirmMessage = $messages{'QTBConfQuit'};
	}
	elsif ($theAction eq '') {
		return true;
	}
	else {
		die("Action not found!");
	}
}

# post method environment variable
$cl = $ENV{"CONTENT_LENGTH"};

if ($ENV{"REQUEST_METHOD"} eq "POST")
{
	# put the data into a variable
	read(STDIN, $qs, $cl);
	$query = &adminprotolib::ParseQueryString($qs);
}
elsif ($ENV{"REQUEST_METHOD"} eq "GET")
{
 	$qs = $ENV{"QUERY_STRING"};
 	$query = &adminprotolib::ParseQueryString($qs);
}

# get the filename
$filename = $query->{'filename'};
if (($filename =~ /[^A-Za-z0-9_\-\.\/]/) or ($filename =~ /\.{2,}/) or ($filename =~ /\/{2,}/)) {
	die "Can't access HTML file!";
}
$auth = $query->{'qtsspassword'};
$username = $query->{'qtssusername'};
$cookie = $query->{'cookie'};
$confirmMessage = '';
$chdelim = &playlistlib::GetFileDelimChar();
$serverRoot = $ENV{"SERVER_ROOT"};

# fix for 3148849
# if the filename starts with /, remove the slash
$filename =~ s/^\///;

# fix for 3064725
# if the setup assistant is being called and the index file no longer exists,
# clear $filename so we get the frameset instead
if (($filename =~ m/setup_assistant2/) && (!(-e "$serverRoot/index.html")))
{
      $filename = '';
}

# new auth code
if ($auth eq '') {
	#if ($cookies{'qtsspassword'}) {
	#	$auth = $cookies{'qtsspassword'}->value;
	#}
	# can't use CGI library; parsing by hand
	if (getCookie('qtsspassword')) {
		$auth = getCookie('qtsspassword');
	}
}
else {
	$auth = encodeBase64("$username:$auth");
}
$authheader = "Authorization: Basic $auth\r\n";  
$theAction = $query->{'action'};
$wasAuth = 1;

# fake a found tag to force authentication before performing an action
if (($theAction ne '') && !($nonAuthenticatedActions =~ m/\|$theAction\|/o)) {
	foundTag(' name="qtssSvrDefaultDNSName"', '', '/');
	
	if ($wasAuth <= 0) {
		undef($query);
		undef($qs);
		return 0;
	}
}

# run the action if there is one
PerformAction();

# hack for QT Broadcaster library on Mac OS X Only
if ($filename eq 'broadcaster_settings.html') {
	if (!(-e '/Applications/QuickTime Broadcaster.app')) {
		my %messages = %$messageHash;
		$confirmMessage = $messages{'QTBErrNotInstalledText'};
		$filename = 'welcome.html';
	}
	else {
		my $result = ConnectToBroadcaster(0);
		if ($result == 0) { # couldn't connect to broadcaster
			$filename = 'start_broadcaster.html';
		}
		elsif ($result == (-1)) {
			$filename = 'restart_broadcaster.html';
		}
	}
}

if ($confirmMessage ne '') { # if we're confirming a save, then do a redirect from the post operation.
	if ($confirmMessage eq 'redirect') {
		$confirmMessage = '';
	}
	else {
		$confirmMessage =~ s/\s/%20/g;
		$confirmMessage =~ s/&/%26/g;
	}
	&cgilib::PrintRedirectHeader($ENV{"SERVER_SOFTWARE"}, "/parse_xml.cgi?filename=$filename&confirmMessage=$confirmMessage");
	return 0;
}

else {

	$confirmMessage = $query->{'confirmMessage'};
	
	chdir($ENV{"SERVER_ROOT"});
	
	# default here
	if (($filename eq '') or (($filename eq 'login.html') and ($query->{'action'} eq 'login'))) {
		$filename = "frameset.html";
	}
	if ($templatefile eq '') {
		$templatefile = "template.html";
	}
	
	#prevent source code revelation
	if (!($filename =~ m/\.html$/)) {
		die "Can't access HTML file '$filename'!";
	}
	
	#prevent windows ports from being opened
	#aux, con, prn, com*, lpt?, nul
	$foundFilename = 0;
	opendir(FILEDIR, $ENV{"SERVER_ROOT"}) or die "Can't access HTML file '$filename'!";
	while (defined($subpath = readdir(FILEDIR))) {
		$foundFilename = 1 if $subpath eq $filename;
	}
	die "Can't access HTML file '$filename'!" if $foundFilename == 0;
	
	$text = '';
	$templatetext = '';
		
	if (!(-e "$filename")) {
		die "Can't access HTML file '$filename'!";
	}
	
	open(HTMLFILE, $filename) or die "Can't open HTML file '$filename'!";
	
	# read the entire file into 
	
	while ($line = <HTMLFILE>) {
		$text .= $line;
	}
	
	# we're done with the file; now close it
	close(HTMLFILE);
	
	# if the template contains the <bodytext/> tag, replace it with the body text from the file
	if ($templatetext =~ /<bodytext\/>/gix) {
		$templatetext =~ s/<bodytext\/>/$text/gix;
		$text = $templatetext;
	}
		
	# parse the tags in the file's text
	$text = parseTags($text);
	
	if ($wasAuth <= 0) {
		undef($query);
		undef($qs);
		return 0;
	}

	# used to be makeSecureRoot()	
	if ($^O ne "MSWin32") {
		chroot($ENV{"SERVER_ROOT"});
		die "Can't open HTML file '$filename!'" if (!(-e $ENV{"SERVER_ROOT"}.'/'.$filename));
	}
	if (($^O eq "MSWin32") && &adminprotolib::CheckIfForbidden($ENV{"SERVER_ROOT"}, $filename)) {
		die "Can't open HTML file '$filename'!";
	}	
	
	open(HTMLFILE, $filename) or die "Can't open HTML file '$filename'!";
	close(HTMLFILE);
	
	# give them a new cookie unless we have a better plan for them
	if ($cookie eq '') {
		$cookie = 'qtsspassword='.getCookie('qtsspassword').'; path=/';
	}

	# CGI programs must print their own HTTP response headers
	&cgilib::PrintOKTextHeader($servername, $cookie);
	
	#print the replaced HTML
	print $text;
	
}

# done!
undef($query);
undef($qs);
return 0;
