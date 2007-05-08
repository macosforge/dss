# password-utils.pl
# Common functions for talking to the admin module of QTSS
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

require('adminprotocol-lib.pl');

package passwordutils;

# GetLineEndingChar
# Returns the line ending character for the current platform.
sub GetLineEndingChar
{
	my $lineEnding = "\n";
	if ($^O ne "MSWin32") {
		$lineEnding = "\r\n";
	}
	return $lineEnding;
}

# GetUserList(usersFilepath, groupsFilePath)
# Given the path to the qtusers file, returns an array ref of users.
sub GetUserList
{
	my $usersFilepath = $_[0];
	my $groupsFilePath = $_[1];
	my %usersList = ();
	my $line;
	my @splitItem = ();
	
	if (open(USERFILE, $usersFilepath)) {
		while ($line = <USERFILE>) {
			if ($line =~ /:/o) { # not a realm statement
				@splitItem = split(/:/, $line);
				$line = $splitItem[0];
				$usersList{$line} = 'user';
			}
		}
		close(USERFILE);
	}
	
	if (open(GROUPSFILE, $groupsFilePath)) {
		while ($line = <GROUPSFILE>) {
			if ($line =~ /:/o) { # a valid line
				@splitItem = split(/:/, $line);
				$line = $splitItem[0];
				$usersList{$line} = 'group';
			}
		}
		close(GROUPSFILE);
	}
	
	return \%usersList;
}

# GetBroadcastRestrictionsFromFile(filepath)
# Given a path to a qtaccess file, returns the type and an array
sub GetBroadcastRestrictionsFromFile {
	my $filepath = $_[0];
	my $line;
	my @splitText = ();
	my $restrictionType = '';
	my @userList = ();
	my $addToList = 0;
	
	if (open(ACCESSFILE, $filepath)) {
		while ($line = <ACCESSFILE>) {
			if ($addToList == 1) {
				if ($line =~ /<\/limit>/i) {
					$addToList = 0;
				}
				else {
					if ($line =~ /^require/i) {
						$line =~ s/[\r\n]+//s;
						push(@splitText, $line);
					}
				}
			}
			else {
				if ($line =~ /<limit write>/i) {
					$addToList = 1;
				}
			}
		}
		close(ACCESSFILE);
		if (scalar(@splitText) > 0) {
			@userList = split /\s+/, $splitText[0];
		}
	}
	
	return \@userList;
}

# GetViewingRestrictionsFromFile(filepath)
# Given a path to a qtaccess file, returns the type and an array
sub GetViewingRestrictionsFromFile {
	my $filepath = $_[0];
	my $line;
	my @splitText = ();
	my $restrictionType = '';
	my @userList = ();
	my $addToList = 0;
	
	if (open(ACCESSFILE, $filepath)) {
		while ($line = <ACCESSFILE>) {
			if ($addToList == 1) {
				if ($line =~ /<limit write>/i) {
					$addToList = 0;
				}
				else {
					if ($line =~ /^require/i) {
						$line =~ s/[\r\n]+//s;
						push(@splitText, $line);
					}
				}
			}
			else {
				if ($line =~ /<\/limit>/i) {
					$addToList = 1;
				}
			}
		}
		close(ACCESSFILE);
		if (scalar(@splitText) > 0) {
			@userList = split /\s+/, $splitText[0];
		}
	}
	
	return \@userList;
}

# WriteRestrictionsToFile(filepath, broadcastRestrictionString, viewingRestrictionString)
# Given a path to a qtaccess file and a reference to an array,
# write the access data to the specified file.
sub WriteRestrictionsToFile {
	my $filepath = $_[0];
	my $broadcastRestrictionString = $_[1];
	my $viewingRestrictionString = $_[2];
	my $lineEnding = GetLineEndingChar();
	
			
	if (open(ACCESSFILE, ">$filepath")) {
		if ($broadcastRestrictionString ne '') {
			print ACCESSFILE "<Limit WRITE>$lineEnding";
			print ACCESSFILE $broadcastRestrictionString;
			print ACCESSFILE "$lineEnding</Limit>$lineEnding";
		}
		if ($viewingRestrictionString eq '') {
			$viewingRestrictionString = 'require any-user';
		}
		print ACCESSFILE "$viewingRestrictionString$lineEnding";
		close ACCESSFILE;
	}
}

# ParseGroupsFile(groupsfilepath)
# Returns a ref to a hash table
# each entry contains a string-delimited list of usernames.
sub ParseGroupsFile {
	my $groupsfilepath = $_[0];
	my %groups = ();
	my $line;
	my $lineUsernames;
	
	if (open(GROUPSFILE), $groupsfilepath) {
		while ($line = <GROUPSFILE>) {
			if ($line =~ /([^:]*):(.*)/) {
				$lineUsernames = $2;
				$lineUsernames =~ s/^\s+//; # remove leading white space
				$groups{$1} = $lineUsernames;
			}
		}
	}
	return \%groups;
}

# SaveGroupsFile(groupsfilepath, groupshashref)
sub SaveGroupsFile {
	my $groupsfilepath = $_[0];
	my $groupshashref = $_[1];
	my %groups = %$groupshashref;
	my $selectedGroup;
	
	if (open(GROUPSFILE, ">$groupsfilepath")) {
		foreach $selectedGroup (keys %groups) {
			print GROUPSFILE "$selectedGroup: " . $groups{$selectedGroup};
		}
		close(GROUPSFILE);
	}
}

# RemoveUserFromGroup(groupsfilepath, username, groupname)
# Remove the specified user from the specified group.
# If groupname is an empty string, remove from all groups.
sub RemoveUserFromGroup {
	my $groupsfilepath = $_[0];
	my $username = $_[1];
	my $groupname = $_[2];
	my %groupsRef = ParseGroupsFile($groupsfilepath);
	my %groups = %$groupsRef;
	my $selectedGroup;
	my $selectedUser;
	my @usernames;
	my @newUsernames;
	
	foreach $selectedGroup (keys %groups) {
		if (($groupname eq '') || ($selectedGroup eq $groupname)) {
			@newUsernames = ();
			@usernames = split(/\s/, $groups{$selectedGroup});
			foreach $selectedUser (@usernames) {
				if ($selectedUser ne $username) {
					push(@newUsernames, $selectedUser);
				}
			}
			$groups{$selectedGroup} = join(' ', @newUsernames);
		}
	}
	SaveGroupsFile(groupsfilepath, \%groups);
}

# DeleteUser(qtpasswdpath, userfilepath, groupsfilepath, username)
sub DeleteUser {
	my $qtpasswdpath = $_[0];
	my $userfilepath = $_[1];
	my $groupsfilepath = $_[2];
	my $username = $_[3];
	
	RemoveUserFromGroup($groupsfilepath, $username, '');
	
	if ($^O eq "MSWin32")
	{
		my $programArgs = "\"$qtpasswdpath\" -f \"$userfilepath\" -F -d \"$username\"";
		$progName = qq($qtpasswdpath);
		eval "require Win32::Process";
		if(!$@) {
		Win32::Process::Create(
					  $processObj,
					  $progName,
					  $programArgs,
					  1,
					  DETACHED_PROCESS,
					  ".") || return $code;
		
		$processObj->SetPriorityClass(NORMAL_PRIORITY_CLASS);
		$processObj->Wait(0);
		sleep(2);
		$code = 200;
		}
	}
	else
	{
		my $programArgs = "\"$qtpasswdpath\" -f \"$userfilepath\" -F -d \'$username\'";
		if(system($programArgs) == 0) {
			$code = 200;
		}
		else {
			$code = 500;
			return $code;
		}
	}
	return $code;
}

# AddOrEditUser(qtpasswdpath, userfilepath, username, password)
sub AddOrEditUser {
	my $qtpasswdpath = $_[0];
	my $userfilepath = $_[1];
	my $username = $_[2];
	my $password = $_[3];
		
	if ($^O eq "MSWin32")
	{
		my $programArgs = "\"$qtpasswdpath\" -f \"$userfilepath\" -p \"$password\" \"$username\"";
		$progName = qq($qtpasswdpath);
		eval "require Win32::Process";
		if(!$@) {
		Win32::Process::Create(
					  $processObj,
					  $progName,
					  $programArgs,
					  1,
					  DETACHED_PROCESS,
					  ".") || return $code;
		
		$processObj->SetPriorityClass(NORMAL_PRIORITY_CLASS);
		$processObj->Wait(0);
		sleep(2);
		$code = 200;
		}
	}
	else
	{
		my $programArgs = "\"$qtpasswdpath\" -f \"$userfilepath\" -p \'$password\' \'$username\'";
		if(system($programArgs) == 0) {
			$code = 200;
		}
		else {
			$code = 500;
			$_[0] = "Error running password application.";
			return $code;
		}
		$_[0] = "";
	}
	return $code;
}