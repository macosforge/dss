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

require('playlist-lib.pl');


my $pldir = $config{'plroot'};
my $plbpath = $config{'qtssPlaylistBroadcaster'};
my $mpbpath = $config{'qtssMP3Broadcaster'};
my $slept = 0;

my $pathdelim = &PathDelimiter();

# make sure there is a delimiter at the end of the playlists dir
if (($pldir !~ /\/$/) && ($pldir !~ /\\$/))
{
	$pldir .= $pathdelim;
}  

# open the playlists root directory   
if (opendir(PLDIR, $pldir))
{
	my $pl = "";
	
	# for each directory inside it
	while( defined ($pl = readdir PLDIR) )
	{
		# get the playlist dir path
		my $playlist = "$pldir$pl$pathdelim$pl";
		my $started = "$pldir$pl$pathdelim" . '.started';
		# if playlist did crash
		if (&PlaylistCrashed("$playlist.pid", $started) == 1)
		{
			# restart it
			if ($slept == 0)
			{
				sleep(10);
				$slept = 1;
			}
			
			&RestartPlaylist($playlist, $plbpath, $mpbpath);
		}
	}
	
	closedir(PLDIR);
	# to make sure that storage associated with the foll. will be recovered for reuse
	undef $pl;
	undef $playlist;
	undef &PlaylistCrashed;
	undef &RestartPlaylist;
	
}

undef $pldir;
undef $pathdelim;
undef &PathDelimiter;
return 1;

# sub PathDelimiter
# no input arguments
# returns the path delimeter for the OS
# returns 	=> "\\" for windows
#			=> "/" for all other platforms 
sub PathDelimiter
{
	if ($^O eq "MSWin32")
	{
		return "\\";
	}
	else
	{
		return "/";
	}
}

# sub PlaylistCrashed
# input		=> $_[0] = path to the pid file; $_[1] = path to the started file
# returns 	=> 1 if playlist crashed
#			=> 0 if playlist is stopped (cleanly) or if it is running
sub PlaylistCrashed
{
	# if the .started file exists in the playlist dir
	if (-e $_[1])
	{
		# but the process isn't running
		if (&playlistlib::CheckIfPidExists($_[0]) == 0)
		{
			# the playlist crashed
			return 1;
		}
	}

	# if the .started file doesn't exist or
	# if it exists, but the process is already running
	# playlist is either stopped cleanly from the UI, or it
	# is being run from the command line
	return 0;
}

# sub RestartPlaylist
# input		=> $_[0] = path to the playlist directory
#			=> $_[1] = path to the PLB binary
#			=> $_[2] = path to the MP3B binary
# has no return value
sub RestartPlaylist
{
	my ($playlist, $plb, $mpb) = @_;
	my $processObject;
	my $program = "";
    my $bcaster = "";
    my $args = "";
    	
	if (open(PLCONF, "$playlist.config"))
	{
		my $confline = "";
                my $confBuffer = "";
		while ($confline = <PLCONF>)
		{
			$confBuffer .= $confline;
		}
		close(PLCONF);
		
		if ($confBuffer =~ /broadcast_genre /)
		{
			# this is an mp3 broadcast
			$program = $mpb;
    		$broadcaster = "MP3Broadcaster";
    		$args = "-e \"$playlist.err\" -c";
		}
		else
		{
			# this is a movie broadcast
			$program = $plb;
    		$broadcaster = "PlaylistBroadcaster";
    		$args = "-a -f -e \"$playlist.err\"";
		}
		
		if ($^O eq "MSWin32")
    	{
    		my $result = &playlistlib::LaunchWin32Process($program, $broadcaster, "$args \"$playlist.config\"", 0);
    	}
    	else
		{
			system "$program $args \"$playlist.config\"";
		}
	}
}