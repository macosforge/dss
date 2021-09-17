#!/usr/bin/perl
#
# @APPLE_LICENSE_HEADER_START@
#
#
# Copyright (c) 1999-2008 Apple Inc.  All Rights Reserved.
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

# Setup script... shell script works fine for all but Windows

require Win32::Process;

$username = '';

while ($username eq '') {

	print "\n\nDarwin Streaming Server Setup\n\n";
	print "In order to administer the Darwin Streaming Server you must create an administrator user [Note: The administrator user name cannot contain spaces, or single or double quote characters, and cannot be more than 255 characters long].\n";
	print "Please enter a new administrator user name: ";
	
	$username = readline STDIN;
	
	if ($username eq '') {
		print "\n\nError: No username entered!";
	}
}

$password = '';

while ($password eq '') {

	print "\n\nYou must also enter a password for the administrator user [Note: The administrator password cannot contain spaces, or quotes, either single or double, and cannot be more than 80 characters long].\n";
	print "Please enter a new administrator Password: ";
	
	$password = readline STDIN;
	
	print "\nRe-enter the new administrator password: ";
	
	$password1 = readline STDIN;
	
	if ($password eq '') {
		print "\n\nError: No password entered!\n\n";
	}
	
	if ($password ne $password1) {
		print "\n\nError: passwords entered do not match!";
		$password = '';
	}

}

$extraargs = '';

if (!(-e 'c:\\Program Files\\Darwin Streaming Server\\qtusers')) {
	$extraargs = ' -c';
}

$username =~ s/[\r\n]//go;
$password =~ s/[\r\n]//go;
$exitCode = 'notyetexited';

$extraargs = "qtpasswd$extraargs -f \"c:\\Program Files\\Darwin Streaming Server\\qtusers\" -p \"$password\" \"$username\"";

Win32::Process::Create($processObj,"c:\\Program Files\\Darwin Streaming Server\\qtpasswd.exe",$extraargs,1,DETACHED_PROCESS,".");

$processObj->Wait(INFINITE); # wait until the process completes

$processObj->GetExitCode($exitCode);

while ($exitCode eq 'notyetexited') {
	
}

$groupsFileText = '';

if (-e "c:\\Program Files\\Darwin Streaming Server\\qtgroups") {
	$line = '';
	open (GROUPSFILE, "c:\\Program Files\\Darwin Streaming Server\\qtgroups");
	while ($line = <FILEHDL>) {
		if (!($line =~ /^admin:/)) {
			$groupsFileText .= $line;
		}
	}
	close(GROUPSFILE);
}

$groupsFileText = "admin:$username\n" . $groupsFileText;

open (GROUPSFILE, ">c:\\Program Files\\Darwin Streaming Server\\qtgroups") or die "Can't open groups file!";
print GROUPSFILE $groupsFileText;
close GROUPSFILE;

print "\n\nSetup Complete!\n";

exit 0;
