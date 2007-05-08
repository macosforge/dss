#!/usr/bin/perl
#----------------------------------------------------------
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
#
#---------------------------------------------------------

# local *FILEHDL;
# local $parser = "";

# An array containing references to a relay array
# local @relays;

# Each relay array contains
# [0] name = (value of attribute NAME from the relay OBJECT tag)
# [1] enabled = (0 or 1)
# [2] source = source hash
# [3] numdest =
# [4] number of dest hashes

# Each source (destination) hash
# (1) always contains the keyword "type" for the type of source (destination)
# (2) each pref it has with the name as a keyword and a value associated with it
# (3) for any list pref, it has the name as the keyword and an array ref as value
#				where the array is the list of values for the pref

# $relayfile = $ARGV[0];

# open(FILEHDL, $relayfile) or die "Can't open file $xmlfile\n";

# read(FILEHDL, $parser, -s $relayfile);

# close(FILEHDL); 

# -------------------------------------------------
# getNewRelay()
#
# -------------------------------------------------
sub getNewRelay {
	$relayDestCount = 1;
	$relayEnabled = 1;
	$currentRelay = 'untitled';
	$relayType = 'rtsp_source';
	$relaySourceHostname = '';
	$relaySourceMountPoint = '';
	$relaySourceUsername = '';
	$relaySourcePassword = '';
	@relayDestType = ('announced_destination');
	@relayDestHostname = ();
	@relayDestMountPoint = ();
	@relayDestType = ();
	@relayDestUsername = ();
	@relayDestPassword = ();
	@relayDestPort = ();
	@relayDestTTL = ();
	
}

# -------------------------------------------------
# AddRelayDestination()
#
# adds a dest to the window and saves vals
# -------------------------------------------------

sub AddRelayDestination() {
	my $i;
	@relayDestHostname = ();
	@relayDestMountPoint = ();
	@relayDestType = ();
	@relayDestUsername = ();
	@relayDestPassword = ();
	@relayDestPort = ();
	@relayDestTTL = ();
	$relayDestCount = $query->{'relayDestCount'};
	for ($i = 0; $i < $relayDestCount; $i++) {
		push(@relayDestHostname, $query->{'relayDestHostname'.$i});
		push(@relayDestMountPoint, $query->{'relayDestMountPoint'.$i});
		push(@relayDestType, $query->{'relayDestType'.$i});
		push(@relayDestUsername, $query->{'relayDestUsername'.$i});
		push(@relayDestPassword, $query->{'relayDestPassword'.$i});
		push(@relayDestPort, $query->{'relayDestPort'.$i});
		push(@relayDestTTL, $query->{'relayDestTTL'.$i});
	}
	$relayDestCount++;
}

# -------------------------------------------------
# getValsForRelay()
#
# expects $query->{'currentRelay'} to be
# populated with the current relay name.
#
# returns a javascript string. put it in
# <script></script> tags. also make sure you have
# a hidden field named "relaydata" to hold the data
# -------------------------------------------------
sub getValsForRelay {
	my $messHash = adminprotolib::GetMessageHash();
	my $relayConfigDir = '';
	my $status = adminprotolib::EchoData($relayConfigDir, $messHash, $authheader, $qtssip, $qtssport, "/modules/admin/server/qtssSvrModuleObjects/QTSSRelayModule/qtssModPrefs/relay_prefs_file", "/modules/admin/server/qtssSvrModuleObjects/QTSSRelayModule/qtssModPrefs/relay_prefs_file");
	my $relayName = $query->{'currentRelay'};
	my $relayarrayref = getArraysFromFile($relayConfigDir);
	my $sourcehashref;
	my %sourcehash;
	my $desthashref;
	my %desthash;
	my @relays = @$relayarrayref;
	@relayDestHostname = ();
	@relayDestMountPoint = ();
	@relayDestType = ();
	@relayDestUsername = ();
	@relayDestPassword = ();
	@relayDestPort = ();
	@relayDestTTL = ();
	foreach $relayRef (@relays) {
		@relay = @$relayRef;
		$relayEnabled = $relay[1];
		$sourcehashref = $relay[2];
		%sourcehash = %$sourcehashref;
		if ((($sourcehash{'type'} eq 'rtsp_source') and ($sourcehash{'source_addr'} eq '') and ($relayName eq '***qtssDefaultRelay***')) or (($sourcehash{'type'} ne 'udp_source') and ($relay[0] eq $relayName))) {
			$relayDestCount = $relay[3];
			$relayType = $sourcehash{'type'};
			$relaySourceHostname = $sourcehash{'source_addr'};
			$relaySourceMountPoint = $sourcehash{'url'};
			
			if ($relayType eq 'announced_source') {
				$relaySourceUsername = '';
				$relaySourcePassword = '';
			}
			elsif ($relayType eq 'rtsp_source') {
				$relaySourceUsername = $sourcehash{'name'};
				$relaySourcePassword = $sourcehash{'password'};
			}
			last;
		}
	}
	for ($i = 4; $i < ($relayDestCount+4); $i++) {
		$desthashref = $relay[$i];
		%desthash = %$desthashref;
		push(@relayDestHostname, $desthash{'dest_addr'});
		push(@relayDestType, $desthash{'type'});
		if ($desthash{'type'} eq 'announced_destination') {
			push(@relayDestMountPoint, $desthash{'url'});
			push(@relayDestUsername, $desthash{'name'});
			push(@relayDestPassword, $desthash{'password'});
			push(@relayDestPort, '');
			push(@relayDestTTL, '');
		}
		elsif ($desthash{'type'} eq 'udp_destination') {
			push(@relayDestMountPoint, '');
			push(@relayDestUsername, '');
			push(@relayDestPassword, '');
			push(@relayDestPort, $desthash{'udp_base_port'});
			push(@relayDestTTL, $desthash{'ttl'});
		}
		else {
			push(@relayDestUsername, '');
			push(@relayDestPassword, '');
			push(@relayDestPort, '');
			push(@relayDestTTL, '');
		}
	}
	if ($relayDestCount == 0) {
		$relayDestCount = 1;
	}
}


# -------------------------------------------------
# getRelayDestData()
#
# populates vars for relay dest in currentDest
# param.
# -------------------------------------------------
sub getRelayDestData {
	my @allDestConfigs = split(/\r/, $query->{'relaydata'});
	@selectedDestConfig = split(/\t/, $allDestConfigs[$query->{'currentDest'}]);
	$qtssDestType = $selectedDestConfig[0];
	if ($qtssDestType eq 'announced_destination') {
		$qtssAnnouncedIP = $selectedDestConfig[1];
		$qtssUDPIP = '';
		$qtssAnnouncedPorts = $selectedDestConfig[2];
		$qtssUDPPorts = '';
		$qtssAnnouncedName = $selectedDestConfig[3];
		$qtssAnnouncedPassword = $selectedDestConfig[4];
		if ($selectedDestConfig[5] eq '') {
			$qtssAnnouncedIsPath = 'false';
		}
		else {
			$qtssAnnouncedIsPath = 'true';
		}
		$qtssAnnouncedPath = $selectedDestConfig[5];
		$qtssUDPIsTTL = '';
		$qtssUDPTTL = '';
	}
	else {
		$qtssDestType = 'udp_destination';
		$qtssAnnouncedIP = '';
		$qtssUDPIP = $selectedDestConfig[1];
		$qtssAnnouncedPorts = '';
		$qtssUDPPorts = $selectedDestConfig[2];
		$qtssUDPPorts =~ s/ /\\r/;
		$qtssAnnouncedName = '';
		$qtssAnnouncedPassword = '';
		$qtssAnnouncedIsPath = '';
		$qtssAnnouncedPath = '';
		if ($selectedDestConfig[7] eq '') {
			$qtssUDPIsTTL = 'false';
		}
		else {
			$qtssUDPIsTTL = 'true';
		}
		$qtssUDPTTL = $selectedDestConfig[7];
	}
	$qtssDestIP1 = $selectedDest;
	$jsstr = $query->{'relaydata'};
	$jsstr =~ s/[\r\n]/\\r/g;
	$jsstr =~ s/\\r\\r/\\r/g;
	$jsstr =~ s/\t/\\t/g;
	$jsstr = 'document.forms[0].elements["relaydata"].value="'.$jsstr.'";'."\r\t\t";
	$jsstr .= 'document.forms[0].elements["qtssUDPPorts"].value="'.$qtssUDPPorts.'";';
	$nextFilename = $query->{'nextFilename'};
	$relayType = $query->{'relayType'};
	$relayEnabled = $query->{'relayEnabled'};
	$relayReceiveSource = $query->{'relayReceiveSource'};
	$relayHasReceivePath = $query->{'relayHasReceivePath'};
	$relayReceivePath = $query->{'relayReceivePath'};
	$relayAcquireSource = $query->{'relayAcquireSource'};
	$relayAcquirePath = $query->{'relayAcquirePath'};
	$relayAcquireUsername = $query->{'relayAcquireUsername'};
	$relayAcquirePassword = $query->{'relayAcquirePassword'};
}

# -------------------------------------------------
# SetRelayDestData()
#
# sets the dest data in the current relaydata
# param, and returns the necessary vars
# -------------------------------------------------
sub SetRelayDestData {
	my $relaydata = $query->{'relaydata'};
	$relaydata =~ s/\r\n/\r/g;
	my @allDestConfigs = split(/[\r\n]/, $relaydata);
	my $i = 0;
	my $item;
	my $qtssUDPPorts;
	my $displayIP;
	$jsstr = 'document.forms[0].elements["relaydata"].value="';
	my $jsstr2 = '';
	my @parsedItemArray = ();
	foreach $item (@allDestConfigs) {
		$item =~ s/[\r\n]//g;
		if (($i == $query->{'currentDest'}) and ($query->{'savechanges'} eq 'true')) {
			my $qtssDestType = $query->{'qtssDestType'};
			$jsstr .= $qtssDestType.'\t';
			if ($qtssDestType eq 'announced_destination') {
				$displayIP = $query->{'qtssAnnouncedIP'};
				$jsstr .= $displayIP.'\t';
				$jsstr .= $query->{'qtssAnnouncedPorts'}.'\t';
				$jsstr .= $query->{'qtssAnnouncedName'}.'\t';
				$jsstr .= $query->{'qtssAnnouncedPassword'}.'\t';
				if ($query->{'qtssAnnouncedIsPath'} eq 'true') {
					$jsstr .= $query->{'qtssAnnouncedPath'}.'\t';
				}
				else {
					$jsstr .= '\t';
				}
			}
			else {
				$displayIP = $query->{'qtssUDPIP'};
				$jsstr .= $displayIP.'\t';
				$qtssUDPPorts = $query->{'qtssUDPPorts'};
				$qtssUDPPorts =~ s/\r\n/\r/g;
				$qtssUDPPorts =~ s/[\r\n]/ /g;
				$jsstr .= $qtssUDPPorts.'\t\t\t\t\t';
				if ($query->{'qtssUDPIsTTL'} eq 'true') {
					$jsstr .= $query->{'qtssUDPTTL'}.'\t';
				}
				else {
					$jsstr .= '\t';
				}
			}
			$jsstr .= '\r';
		}
		else {
			@parsedItemArray = split(/\t/,$item);
			if ($parsedItemArray[0] eq 'announced_destination') {
				$displayIP = $parsedItemArray[1];
			}
			else {
				$displayIP = $parsedItemArray[1];
			}
			$item =~ s/\t/\\t/g;
			$jsstr .= $item . '\r';
		}
		$jsstr2 .= "\r\t\tdocument.forms[0].elements['dests'].length++;";
		$jsstr2 .= "\r\t\tdocument.forms[0].elements['dests'].options[$i].text = '$displayIP';";
		$jsstr2 .= "\r\t\tdocument.forms[0].elements['dests'].options[$i].value = '$displayIP';";
		$i++;
	}
	if (($query->{'currentDest'} == (-1)) and ($query->{'savechanges'} eq 'true')) {
		my $qtssDestType = $query->{'qtssDestType'};
		$jsstr .= $qtssDestType.'\t';
		if ($qtssDestType eq 'announced_destination') {
			$displayIP = $query->{'qtssAnnouncedIP'};
			$jsstr .= $displayIP.'\t';
			$jsstr .= $query->{'qtssAnnouncedPorts'}.'\t';
			$jsstr .= $query->{'qtssAnnouncedName'}.'\t';
			$jsstr .= $query->{'qtssAnnouncedPassword'}.'\t';
			if ($query->{'qtssAnnouncedIsPath'} eq 'true') {
				$jsstr .= $query->{'qtssAnnouncedPath'}.'\t';
			}
			else {
				$jsstr .= '\t';
			}
		}
		else {
			$displayIP = $query->{'qtssUDPIP'};
			$jsstr .= $displayIP.'\t';
			$qtssUDPPorts = $query->{'qtssUDPPorts'};
			$qtssUDPPorts =~ s/\r\n/\r/g;
			$qtssUDPPorts =~ s/[\r\n]/ /g;
			$jsstr .= $qtssUDPPorts.'\t\t\t\t\t';
			if ($query->{'qtssUDPIsTTL'} eq 'true') {
				$jsstr .= $query->{'qtssUDPTTL'}.'\t';
			}
			else {
				$jsstr .= '\t';
			}
		}
		$jsstr .= '\r';
		$jsstr2 .= "\r\t\tdocument.forms[0].elements['dests'].length++;";
		$jsstr2 .= "\r\t\tdocument.forms[0].elements['dests'].options[$i].text = '$displayIP';";
		$jsstr2 .= "\r\t\tdocument.forms[0].elements['dests'].options[$i].value = '$displayIP';";
	}
	$jsstr =~ s/\\r\\r/\\r/g;
	$jsstr .= '";'."\r\t\t";
	$jsstr .= $jsstr2;
	$jsstr .= "\r\t\t";
	$relayType = $query->{'relayType'};
	$relayEnabled = $query->{'relayEnabled'};
	$relayReceiveSource = $query->{'relayReceiveSource'};
	$relayHasReceivePath = $query->{'relayHasReceivePath'};
	$relayReceivePath = $query->{'relayReceivePath'};
	$relayAcquireSource = $query->{'relayAcquireSource'};
	$relayAcquirePath = $query->{'relayAcquirePath'};
	$relayAcquireUsername = $query->{'relayAcquireUsername'};
	$relayAcquirePassword = $query->{'relayAcquirePassword'};
}

# -------------------------------------------------
# DeleteRelayDest()
#
# deletes the destination in currentDest
# query param
# -------------------------------------------------
sub DeleteRelayDest {
	my $i;
	@relayDestHostname = ();
	@relayDestMountPoint = ();
	@relayDestType = ();
	@relayDestUsername = ();
	@relayDestPassword = ();
	@relayDestPort = ();
	@relayDestTTL = ();
	$relayDestCount = $query->{'relayDestCount'};
	for ($i = 0; $i < $relayDestCount; $i++) {
		if ($i != ($query->{'currentDest'} - 1)) {
			push(@relayDestHostname, $query->{'relayDestHostname'.$i});
			push(@relayDestMountPoint, $query->{'relayDestMountPoint'.$i});
			push(@relayDestType, $query->{'relayDestType'.$i});
			push(@relayDestUsername, $query->{'relayDestUsername'.$i});
			push(@relayDestPassword, $query->{'relayDestPassword'.$i});
			push(@relayDestPort, $query->{'relayDestPort'.$i});
			push(@relayDestTTL, $query->{'relayDestTTL'.$i});
		}
	}
	$relayDestCount--;	
}

# -------------------------------------------------
# SaveRelay()
#
# saves array in currentRelay param to file
# -------------------------------------------------
sub SaveRelay {
	my $messHash = adminprotolib::GetMessageHash();
	my $relayConfigDir = '';
	my $status = adminprotolib::EchoData($relayConfigDir, $messHash, $authheader, $qtssip, $qtssport, "/modules/admin/server/qtssSvrModuleObjects/QTSSRelayModule/qtssModPrefs/relay_prefs_file", "/modules/admin/server/qtssSvrModuleObjects/QTSSRelayModule/qtssModPrefs/relay_prefs_file");
	my $relayName = $query->{'currentRelay'};
	my $relayEnabled = $query->{'relayEnabled'};
	my $relayarrayref = getArraysFromFile($relayConfigDir);
	my @relaylist = @$relayarrayref;
	my %sourcehash = ();
	my $i = 0;
	my $i2 = 0;
	my $item;
	my $item2;
	my @newRelay = ();
	my $relayDestCount = $query->{'relayDestCount'};
	
	# delete the old relay, if the name changed
	
	if ($query->{'currentRelay_shadow'} ne $query->{'currentRelay'}) {
		my @newrelayarrays = ();
		foreach $item (@relaylist) {
			my @currentRelay = @$item;
			if ($currentRelay[0] ne $query->{'currentRelay_shadow'}) {
				push(@newrelayarrays, $item);
			}
		}
		@relays = @newrelayarrays;
	}
	
	if ($relayEnabled ne '1') {
		$relayEnabled = '0';
	}	
	$sourcehash{'type'} = $query->{'relayType'};
	if ($query->{'currentRelay'} ne '***qtssDefaultRelay***') {
		$sourcehash{'source_addr'} = $query->{'relaySourceHostname'};
		$sourcehash{'url'} = $query->{'relaySourceMountPoint'};
		$_ = $query->{'relayType'};
		if ($_ eq 'announced_source') {
			$sourcehash{'name'} = '';
			$sourcehash{'password'} = '';
		}
		else {
			$sourcehash{'name'} = $query->{'relaySourceUsername'};
			$sourcehash{'password'} = $query->{'relaySourcePassword'};
		}
	}
	push(@newRelay, $relayName);
	push(@newRelay, $relayEnabled);
	push(@newRelay, \%sourcehash);
	push(@newRelay, $relayDestCount);
	for ($i = 0; $i < $relayDestCount; $i++) {
		my %desthash = ();
		$desthash{'type'} = $query->{'relayDestType'.$i};
		$desthash{'dest_addr'} = $query->{'relayDestHostname'.$i};
		$desthash{'url'} = $query->{'relayDestMountPoint'.$i};
		if ($desthash{'type'} eq 'announced_destination') {
			$desthash{'name'} = $query->{'relayDestUsername'.$i};
			$desthash{'password'} = $query->{'relayDestPassword'.$i};
		}
		else {
			$desthash{'udp_base_port'} = $query->{'relayDestPort'.$i};
			if ($query->{'relayDestTTL'.$i} ne '') {
				$desthash{'ttl'} = $query->{'relayDestTTL'.$i};
			}
		}
		push(@newRelay, \%desthash);
	}
	
	my $foundIt = 0;
	
	foreach $item (@relays) {
		my @currentRelay = @$item;
		my $oldsourcehashref = $relay[2];
		my %oldsourcehash = %$sourcehashref;
		if ((($sourcehash{'type'} eq 'rtsp_source') and ($sourcehash{'source_addr'} eq '') and ($query->{'currentRelay'} eq '***qtssDefaultRelay***')) or ($currentRelay[0] eq $query->{'currentRelay'})) {
			$foundIt = 1;
			$item = \@newRelay;
			last;
		}
		$i++;
	}
	
	if ($foundIt == 0) {
		push (@relays, \@newRelay)
	}
	$myHdl = select();
	# my $relayarrayref = getArraysFromFile($relayConfigDir);
	open(FILEHDL, ">$relayConfigDir") or die "Can't open relay file '$relayfile'!";
	print FILEHDL WriteRelayConfigToFile();
	close(FILEHDL);
	FixFileGroup($relayConfigDir);
	chmod 0600, $relayConfigDir;
	$status = &adminprotolib::SetAttribute($data, $messHash, $authheader, $qtssip, $qtssport, '/admin/server/qtssSvrModuleObjects/QTSSRelayModule/qtssModPrefs/relay_prefs_file', $relayConfigDir);
	$confirmMessage = $messages{'RelaySaveText'};
}

# -------------------------------------------------
# DeleteRelay()
#
# deletes selected relay
# -------------------------------------------------
sub DeleteRelay {
	my $messHash = adminprotolib::GetMessageHash();
	my $relayConfigDir = '';
	my $status = adminprotolib::EchoData($relayConfigDir, $messHash, $authheader, $qtssip, $qtssport, "/modules/admin/server/qtssSvrModuleObjects/QTSSRelayModule/qtssModPrefs/relay_prefs_file", "/modules/admin/server/qtssSvrModuleObjects/QTSSRelayModule/qtssModPrefs/relay_prefs_file");
	my @allDestConfigs = split(/\r/, $query->{'relaydata'});
	my $relayName = $query->{'currentRelay'};
	my $item;
	my $relayarrayref = getArraysFromFile($relayConfigDir);
	my @newrelayarrays = ();
	foreach $item (@relays) {
		my @currentRelay = @$item;
		if ($currentRelay[0] ne $query->{'currentRelay'}) {
			push(@newrelayarrays, $item);
		}
	}
	@relays = @newrelayarrays;
	open(FILEHDL, ">$relayConfigDir") or die "Can't open relay file '$relayfile'!";
	print FILEHDL WriteRelayConfigToFile();
	close(FILEHDL);
	FixFileGroup($relayConfigDir);
	chmod 0600, $relayConfigDir;
	$status = &adminprotolib::SetAttribute($data, $messHash, $authheader, $qtssip, $qtssport, '/admin/server/qtssSvrModuleObjects/QTSSRelayModule/qtssModPrefs/relay_prefs_file', $relayConfigDir);
}

# -------------------------------------------------
# getArraysFromFile($relayfile)
#
# returns a reference to the array.
# -------------------------------------------------
sub getArraysFromFile {
	my $relayfile = $_[0];
	my $parser = "";
	my $line = "";
	@relays = ();
	if (open(FILEHDL, $relayfile)) {
	
		# read the entire file into 
		
		while ($line = <FILEHDL>) {
			$parser .= $line;
		}
	}
	else { # couldn't open file - try creating a new one
		open(FILEHDL, ">$relayfile") or die "Can't open relay file '$relayfile'!";
		$parser = "<RELAY_CONFIG>\n\t<OBJECT TYPE=\"relay\" NAME=\"***qtssDefaultRelay***\">\n\t\t<OBJECT CLASS=\"source\" TYPE=\"announced_source\">\n\t\t</OBJECT>\n\t</OBJECT>\n</RELAY_CONFIG>\n";
		print FILEHDL $parser;
	}
	
	# we're done with the file; now close it
	close(FILEHDL);
	FixFileGroup($relayConfigDir);
	chmod 0600, $relayConfigDir;
	
	if (ParseXML($parser) == 1) {
		return \@relays;
	}
	else {
		return 0;
	}
}

# $success = ParseXML($parser);

# if($success == 1)
#{
#	PrintRelayConfig();
#    WriteRelayConfigToFile();    
#}

# ParseXML function
sub ParseXML 
{
	my $buf = $_[0];
	
	while ($buf =~ m/^(\s*?)<!--(.*?)-->(.*)/s)
	{
		$buf = $3;
	}
	
	if ( $buf =~ m/^(.*?)<RELAY_CONFIG>(.*?)<\/RELAY_CONFIG>/s )
	{
		$buf = $2;	
	}
	else
	{
		print "Valid <RELAY_CONFIG> tag not found!\n";
		return 0;
	}
	
	while ($buf !~ m/^(\s*?)$/s)
	{
		if ($buf =~ m/^(\s*?)<!--(.*?)-->(.*)/s)
		{
		    $buf = $3;
		    next;
		}
		elsif ($buf =~ m/^(\s*?)<OBJECT TYPE="relay" NAME="(.*?)">(.*)/s)	
		{
		    $buf = ParseRelay($3, $2);
		}
		elsif ($buf =~ m/^(\s*?)<OBJECT TYPE="relay">(.*)/s)	
		{
		    $buf = ParseRelay($2);
		}
		else
		{
		    print "Invalid XML file\n";
		    print "$buf";
		    exit -1;
		}
       }
	
	return 1;
}

# Each relay array contains
# [0] name = 
# [1] enabled = (0 or 1)
# [2] source = source hash
# [3] numdest = 
# [4] number of dest hashes
sub ParseRelay
{
	my $buf = $_[0];
	my $relayname = (defined($_[1]))? $_[1]: "";

	my @relay = ($relayname, 1, undef, 0);
	# we will append destinations array to relay array at the very end;
	my @destinations;
	
	while ($buf !~ m/^(\s*?)$/s)
	{
		# ignore comment tags
		if ($buf =~ m/^(\s*?)<!--(.*?)-->(.*)/s)
		{
			$buf = $3;
			next;
		}
		# parse pref ENABLED and store 0 or 1 in the second element of relay arr 
		elsif ($buf =~ m/^(\s*?)<PREF NAME="enabled">(.*?)<\/PREF>(.*)/s)
		{
			if($2 eq "false")
			{
			    $relay[1] = 0;
			}

			$buf = $3;
			next;
		}
		# parse source/destination tag
		elsif ($buf =~ m/^(\s*?)<OBJECT CLASS="(.*?)" TYPE="(.*?)">(.*?)<\/OBJECT>(.*)/s )
		{
			$buf = $5;
			if($2 eq "source")
			{
				$relay[2] = ParseClass($3, $4);
			}
			elsif ($2 eq "destination")
			{
				$relay[3]++;
				push(@destinations, ParseClass($3, $4));
			}
			next;
		}
		elsif ($buf =~ m/^(\s*?)<\/OBJECT>(.*)/s)
		{
			$buf = $2;
			last;
		}
		else
                {
                    print "Invalid XML file\n";
                    print "$buf";
		    exit -1;
                }
	}
	
	push(@relay, @destinations);
	
	push(@relays, \@relay);
	
	return $buf;
}

# takes in the type of source/destination and the buffer
# returns a ref to the source/destination hash
sub ParseClass
{
	# Each source (destination) hash
	# (1) always contains the keyword "type" for the type of source (destination)
	# (2) each pref it has with the name as a keyword and a value associated with it
	# (3) for any list pref, it has the name as the keyword and an array ref as value
	#				where the array is the list of values for the pref


	my %objectHash;
	$objectHash{'type'} = $_[0];
	my $objectBuf = $_[1];

	while ($objectBuf !~ m/^(\s*?)$/s)
	{
		# ignore comment tags
		if ($objectBuf =~ m/^(\s*?)<!--(.*?)-->(.*)/s)
		{
			$objectBuf = $3;
			next;
		}
		# parse pref
		elsif ($objectBuf =~ m/^(\s*?)<PREF NAME="(.*?)">(.*?)<\/PREF>(.*)/s)
		{
			$objectHash{$2} = $3;
			$objectBuf = $4;
			next;
		}
		# parse list pref
		elsif ($objectBuf =~ m/^(\s*?)<LIST-PREF NAME="(.*?)">(.*?)<\/LIST-PREF>(.*)/s)
		{
			my @listArr;
			my $listName = $2;
			my $listBuf = $3;
			$objectBuf = $4;
			while($listBuf !~ m/^(\s*?)$/s) 
			{
				# ignore comment tags
				if ($listBuf =~ m/^(\s*?)<!--(.*?)-->(.*)/s)
				{
					$listBuf = $3;
					next;
				}
				elsif ($listBuf =~ m/^(\s*?)<VALUE>(.*?)<\/VALUE>(.*)/s)
				{
					push(@listArr, $2);
					$listBuf = $3;
					next;
				}
				else
				{
				    print "Invalid XML file\n";
				    print "$listBuf";
				    exit -1;
				}
		        }
			
			$objectHash{$listName} = \@listArr;
			next;
		    }
		    else
		    {
			print "Invalid XML file\n";
			print "$objectBuf";
			exit -1;
		    }
	}

	return \%objectHash;
}

# Each relay array contains
# [0] name = 
# [1] enabled = (0 or 1)
# [2] source = source hash
# [3] numdest = 
# [4] number of source hashes
sub PrintRelayConfig
{
	my $i, $j;
	
	for ($i = 0; $i <= $#relays; $i++)
	{
		my $relRef = $relays[$i];
		my @rel = @$relRef;
	
		print "Relay Name=$rel[0] Enabled=$rel[1]\n";
		
		if (defined($rel[2]))
		{
			print "		Source\n";
			PrintHash($rel[2]);
			print " ---\n";
		}

		print "Number of destinations = $rel[3]\n";
		
		for ($j = 4; $j <= $#rel; $j++)
		{
			print "		Destination\n";
			PrintHash($rel[$j]);
			print " ---\n";
		}
		
		print " -------\n";
	}
}

sub PrintHash
{
	my $hashRef = $_[0];
	my $key;
	
	foreach $key (keys %$hashRef)
	{
		print "			$key = $hashRef->{$key}\n";
	}		
}

sub WriteRelayConfigToFile
{
#    my $filename = $_[0];
    my $fileBuf = qq(<RELAY_CONFIG>\n);
    my $i, $j;

    for ($i = 0; $i <= $#relays; $i++)
    {
	my $relRef = $relays[$i];
	my @rel = @$relRef;
	if($rel[0] eq "")
	{
	    $fileBuf .= qq(<OBJECT TYPE="relay">\n);
	}
	else
	{
	    $fileBuf .= qq(<OBJECT TYPE="relay" NAME="$rel[0]">\n);
	}
	if($rel[1] == 0)
	{
	    	$fileBuf .= qq(    <PREF NAME="enabled">false</PREF>\n);
	}
	
	my $sourceRef = $rel[2];
	$fileBuf .= qq(    <OBJECT CLASS="source" TYPE="$sourceRef->{'type'}">\n);
	$fileBuf .= WriteClassConfigToBuffer($sourceRef);
	$fileBuf .= qq(    </OBJECT>\n);
	
	for($j = 4; $j <= $#rel; $j++)
	{
	    my $destRef = $rel[$j];
	    $fileBuf .= qq(    <OBJECT CLASS="destination" TYPE="$destRef->{'type'}">\n);
	    $fileBuf .= WriteClassConfigToBuffer($destRef);
	    $fileBuf .= qq(    </OBJECT>\n);
	}

	$fileBuf .= qq(</OBJECT>\n);
    }

    $fileBuf .= qq(</RELAY_CONFIG>);
    # $fileBuf = "archived version\n------------------\n$fileBuf";
    # print "archived version\n";
    # print "------------------\n";
    # print "$fileBuf";
    return $fileBuf
}

sub WriteClassConfigToBuffer
{
    my $buf = "";
    my $hashRef = $_[0];
    my $key;
    my $i;

    foreach $key (keys %$hashRef)
    {
	if($key eq "type")
	{
	    next;
	}

	$val = $hashRef->{$key};

	if(not ref $val)
	{
	    $buf .= qq(        <PREF NAME="$key">$val</PREF>\n);
	}
	else
	{
	    @vallist = @$val;
	    $buf .= qq(        <LIST-PREF NAME="$key">\n);
	    for($i = 0; $i <= $#vallist; $i++)
	    {
		$buf .= qq(            <VALUE>$vallist[$i]</VALUE>\n);
	    }
	    $buf .= qq(         </LIST-PREF>\n);
	}
    }

    return $buf;
}

1; # return true