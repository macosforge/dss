# adminprotocol-lib.pl
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

require ('playlist-lib.pl');

package adminprotolib;

# Vital libraries
#use IO::Socket;
use Socket;

@weekdayStr = ( "SunStr", "MonStr", "TueStr", "WedStr", "ThuStr", "FriStr", "SatStr" );
@monthStr = ( "JanStr", "FebStr", "MarStr", "AprStr", "MayStr", "JunStr", "JulStr", "AugStr", "SepStr", "OctStr", "NovStr", "DecStr" );

$enMessageHash = $ENV{"QTSSADMINSERVER_EN_MESSAGEHASH"};
$deMessageHash = $ENV{"QTSSADMINSERVER_EN_MESSAGEHASH"};
$jaMessageHash = $ENV{"QTSSADMINSERVER_EN_MESSAGEHASH"};
$frMessageHash = $ENV{"QTSSADMINSERVER_EN_MESSAGEHASH"};

# GetMessageHash()
# Returns the messages hash given the language
sub GetMessageHash 
{
	return $ENV{"QTSSADMINSERVER_EN_MESSAGEHASH"};  
}

# GetGenreArray()
# Returns the messages hash given the language
sub GetGenreArray 
{
	my $lang = $ENV{"LANGUAGE"};
	@genreArray = ();
	my $genreFilename = $ENV{'SERVER_ROOT'} . "/html_en/" . $ENV{"GENREFILE"};
	
	open(GENRES, $genreFilename) or die "Couldn't find the $lang genre file $genreFilename!";
	while($genreLine = <GENRES>) {
		$genreLine =~ s/[\r\n]//g;
		push(@genreArray, $genreLine);
	}
	
	return \@genreArray;  
}

my $confPath = $ENV{"QTSSADMINSERVER_CONFIG"};

# GetData(data, messageHash, authheader, serverName, port, uri) 
# Does an HTTP GET to a server and puts the body in a scalar variable
# Returns the status code of the response from the server
sub GetData
{ 
    my ($messHash, $authheader, $remote,$port, $iaddr, $paddr, $proto, $uri);
    $messHash = $_[1];
    $authheader = $_[2];
    $remote = $_[3];
    $port = $_[4];
    $uri = $_[5];
	
	my %messages = %$messHash;
	
    my $status = 500;
    if(!($iaddr = inet_aton($remote))) {
    	$_[0] = "$messages{'NoHostError'}: $remote";
    	return $status;
    }
    $paddr = sockaddr_in($port, $iaddr);
    $proto = getprotobyname('tcp');
    if(!socket(CLIENT_SOCK, PF_INET, SOCK_STREAM, $proto)) {
    	$_[0] = "$messages{'SocketFailedError'}: $!";
    	return $status;
    }
    if(!connect(CLIENT_SOCK, $paddr)) {
     	$_[0] = "$messages{'ConnectFailedError'}: $!";
     	close (CLIENT_SOCK);
     	return $status;
 	}
 	
    # send request
    $request = "GET $uri HTTP/1.1\r\nUser-Agent: PerlScript\r\nAccept: */*\r\nConnection: close\r\n" . "$authheader\r\n";
    my $bytesSent = 0;
    while($bytesSent < length($request)) {
		$partOfRequest = substr($request, $bytesSent);
		if(!($bytes = send(CLIENT_SOCK, $partOfRequest, 0))) {
			$_[0] = "$messages{'SendFailedError'}: $!";
			close (CLIENT_SOCK);
			return $status;
		}
		$bytesSent += $bytes;
    }
		 
    # read response
    my $partOfResponse;
    $response = "";
    while(1) {

		$partOfResponse = "";
		#if($^O eq "MSWin32") {
	    #	($servipaddr = recv(CLIENT_SOCK, $partOfResponse, 1024, 0)) || last;
		#}
		#else {
			($numBytesRead = read(CLIENT_SOCK, $partOfResponse, 1024)) || last;
		#}	   
		$response .= $partOfResponse;
    }
        
    # read response headers
    my @lines = split /\n/m, $response; 
    my $line = shift @lines;
  
    # Check the status code of the response
    if ($line =~ m/^(\S*?)(\s)(.*?)(\s)(\S*?)(\s*)$/) {
		$status = $3;
    }
    
   # Go through the rest of the headers
    while(@lines) {
		$line = shift @lines;
		if ($line =~ m/^\s*$/) { last; }
		if($line =~ /^(\S+):\s+(.*)$/) {
			if(lc($1) eq "www-authenticate") {
				$challenge = $line;
			} 
		}
    }
    
    # Read the response body
    if ($status == 200) { 
		$responseText = "";
		while(@lines) {
	   		$line = shift @lines;
	    	$responseText .= "$line\n";
		}
		$_[0] = $responseText;
    }
    elsif ($status == 401) {
    	$_[0] = $challenge;
    }
    
    close (CLIENT_SOCK);
    return $status;
}

# EchoData(data, messageHash, authheader, serverName, port, uri, param)
# Uses GetData to fetch the uri and parses the value in param=value 
# into a scalar variable.
# Returns the value as a scalar
sub EchoData {
	my $messHash = $_[1];
	my $authheader = $_[2];
    my $serverName = $_[3];
    my $serverPort = $_[4];
    my $uri = $_[5];
    my $param = $_[6];
    my $responseText = "";
    my $status = GetData($responseText, $messHash, $authheader, $serverName, $serverPort, $uri);
    if($status != 200) {
    	$_[0] = $responseText;
		return $status;
    }

    my $paramName = "";
    my $paramValue = "";
    if ($param =~ m/^(.*)\/(\w+)$/) {
		$paramName = $2;
    }
    else {
		$paramName = $param;
    }
    
    my @lines = split /\n/, $responseText;
    my $line;
    
    while(@lines) {
		$line = shift @lines;
		if($line =~ m/^$paramName=\"(.*)\"(\s*)$/) {
		    $paramValue = $1;
		}
    }
    if($paramValue eq "") {
		undef($paramValue);
    }
    $_[0] = $paramValue;
    return $status;
}

# GetMovieDir(dirname, messageHash, authheader, serverName, port)
# Uses GetData to fetch the location of the Movies
# directory from the QTSS server.
# Returns the value as a scalar in the first parameter.
# Also returns an error code.
sub GetMovieDir {
	my $messHash = $_[1];
	my $authheader = $_[2];
    my $server = $_[3];
    my $port = $_[4];
    my $uri = "/modules/admin/server/qtssSvrPreferences/movie_folder";
	my $param = "/server/qtssSvrPreferences/movie_folder";
    my $dirname = "";
    my $status = EchoData($dirname, $messHash, $authheader, $server, $port, $uri, $param);
                           
    if ($status eq "401") {
		$dirname = "Authorization_Failure";
    }
    elsif ($dirname eq "") {
	    if ($^O =~/[Dd]arwin/) {
            $dirname = "/Library/QuickTimeStreaming/Movies";
        }
        elsif ($^O eq "MSWin32") {
            $dirname = "c:\\Program Files\\Darwin Streaming Server\\Movies";
        }
        else {
            $dirname = "/usr/local/movies/";
        }
    }
	$_[0] = $dirname;
    return $status;
}

# MakeArray(text, name, [size]) 
# Parses the scalar text for the container name and 
# returns an array of all the values. If size is given 
# it looks for size number of elements else it finds all
sub MakeArray
{
    my $text = $_[0];
    my $name = $_[1];
    my $size = 0;
    my $count = 0;

    if($_[3]) { $size = $_[3]; }
    
    my @lines = split /\r|\n/, $text;
    my $line;
    my @arr;
    $#arr = $size - 1;   # pre-grow the array if we know its size

    while(@lines) {
		$line = shift @lines;	
#		if($line =~ m/^Container=\"(.*)$name\"(\s*)$/) {
		if($line =~ m/^Container=\"(.*)\"$/) {
		    while(1) {
				$line = shift @lines;
				if($line =~ m/^$count=\"(.*)\"(\s*)$/) {
				    $arr[$count] = $1;
		    		$count++;
		    		if(($size != 0) && ($size == $count)) { last; }
				}
				else { last; }
	    	}
	    	last;
		}
		elsif($line =~ m/^(.*?)=\"(.*?)\"/) {
			$arr[0] = $2;
			last;
    	}
    }
    return \@arr;
}


#sub FormatArray (\@arrName, beginIndex, endIndex, prefix, suffix) 
# Formats the elements of the array by applying the
# prefix and the suffix to each element in the array
# returns the formatted text
sub FormatArray {
    my $arRef = $_[0];
    my @arr = @$arRef;
    my $index = $_[1];
    my $endIndex = ($_[2] == -1) ? $#arr : $_[2];
    my $prefix = $_[3];
    my $suffix = $_[4];
    
    local $responseText= "";
    for($index; $index <= $endIndex; $index++) {
		$responseText .= $prefix.$arr[$index].$suffix;
    }
    return scalar $responseText;
}
 
# sub HasValue (\@arrOfHash, value, ["num" | alpha"])
# Returns 1 if the array contains the value, 0 otherwise. 
sub HasValue {
    my $arRef = $_[0];
    my @arr = @$arRef;
    my $value = $_[1];
    my $type = $_[2];

	if($type eq "num") {
		for($i = 0; $i <= $#arr; $i++) {
			if($arr[$i] == $value) {
				return 1;
			}
		}
	}
	elsif($type eq "alpha") {
		for($i = 0; $i <= $#arr; $i++) {
			if($arr[$i] eq $value) {
				return 1;
			}
		}
	}
	return 0;
}

# sub SetAttribute (data, messageHash, authheader, server, port, fullpath, value, [type])
# Sends an admin protocol set command and returns the error value
sub SetAttribute {
	my $uri = "/modules".$_[5]."?command=set+value="."\"$_[6]\"";
	my $code = 400;
	if($_[7]) {
		$uri .= "+type=$_[7]";
	}
	my $data = "";
	$status = GetData($data, $_[1], $_[2], $_[3], $_[4], $uri); 
	if($status == 200) {
		if($data =~ m/^error:\((.*)\)/) {
			$code = $1;
		}
	}
	else {
		$code = $status;
		$_[0] = $data;
	}
	return $code;
}

# sub SetPassword (data, messageHash, authheader, server, port, qtssUsersFileAttr, value, qtssPasswdName, qtssAdmin)
# Sends an admin protocol set command for the admin password and returns the error value
sub SetPassword {
	my $code = 200;
	my $data = "";
	my $password = "";

	if($_[6] eq ""){
		$code = 200;
		$_[0] = "No password given";
		return;
	}
	
	#if($_[6] !~ /^[a-zA-Z_0-9\t\r\n\f]+$/)
	#{
	#	# the password contains other than alphanumeric ascii characters
	#	$code = 500;
	#	$_[0] = "The password contains other than alphanumeric ascii characters.";
	#	return $code;
	#}
	 
	#if($_[6] =~ /\s+/) {
	#	$password = qq("). $_[6] . qq(");
	#}
	#else {
	#	$password = $_[6];
	#}
	
	#Get the name of the default users file from QTSS 
	# that's where the current username:password record is
	my $uri = "/modules/admin". $_[5];
	my $status = EchoData($data, $_[1], $_[2], $_[3], $_[4], $uri, $_[5]);
	
	if ($status != 200) {
		$code = $status;
		$_[0] = $data;	
	}
	else {
		if ($^O eq "MSWin32")
		{
			# for windows, we need to use double quotes around the args and not single quotes
			$programArgs = "\"$_[7]\" -f \"$data\" -p \"$_[6]\" \"$_[8]\"";
		}
		else
		{
			# for macosx and other unixes, we need to use single quotes around the args
			$programArgs = "\"$_[7]\" -f \"$data\" -p \'$_[6]\' \'$_[8]\'";
		}
		
		if($^O ne "MSWin32") {
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
		else {
			$progName = qq($_[7]);
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
		    $_[0] = "Password Set";
			$code = 200;
		    }
		}
	}
	return $code;
}

# Runs qtpasswd to delete the username record from the users file
# DeleteUsername( outputresultstring, messagesHash, authHeader, QTSSIP, QTSSport, UsersFileAttribute, QTPasswdpath, oldUsername)
sub DeleteUsername {
	my $code = 200;
	my $data = "";
	my $password = "";

	if($_[7] eq ""){
		$code = 200;
		$_[0] = "No username given";
		return;
	}
	
	#Get the name of the default users file from QTSS 
	# that's where the current username:password record is
	my $uri = "/modules/admin". $_[5];
	my $status = EchoData($data, $_[1], $_[2], $_[3], $_[4], $uri, $_[5]);
	
	if ($status != 200) {
		$code = $status;
		$_[0] = $data;	
	}
	else {
		# commandWithArgs is used on macosx and other unixes
		# so enclose args in single quotes
		my $commandWithArgs = "\"$_[6]\" -f \"$data\" -F -d \'$_[7]\'";
		
		# args is used on windows
		# so enclose args in double quotes
		my $args = "-f \"$data\" -F -d \"$_[7]\"";
		if($^O ne "MSWin32") {
			if(system($commandWithArgs) == 0) {
				$code = 200;
			}
			else {
				$code = 500;
				$_[0] = "Error running password application.";
				return $code;
			}
			$_[0] = "";
		}
		else {
			&playlistlib::LaunchWin32Process($_[6], "\"$_[6]\"", $args, 1);
			sleep(2);
		    $_[0] = "Username deleted";
			$code = 200;    
		}
	}
	return $code;
}

# sub AddValueToAttribute (data, messageHash, authheader, server, port, fullpath, value)
sub AddValueToAttribute {
	my $uri = "/modules".$_[5]."?command=add+value="."\"$_[6]\"";
	my $code = 0;
	my $data = "";
	$status = GetData($data, $_[1], $_[2], $_[3], $_[4], $uri);
	if($status == 200) { 
		if($data =~ m/^error:\((.*?)\)$/) {
			$code = $1;
		}
	}
	else {
		$code = $status;
		$_[0] = $data;
	}
	return $code;
}

# sub DeleteValueFromAttribute (data, messageHash, authheader, server, port, fullpath, value)
sub DeleteValueFromAttribute {
	my $server = $_[3];
	my $port = $_[4];
	my $fullpath = $_[5];
	my $value = $_[6];
	my $code = 0;
	my $data = "";
	my $status = GetData($data, $_[1], $_[2], $server, $port, "/modules".$fullpath."/*");
	if($status != 200) {
		$code = $status;
		$_[0] = $data;
		return $code;
	}
	my $arRef = MakeArray($data, $fullpath."/");
	my @arr = @$arRef;
	my $index = -1;
	for($i = 0; $i <= $#arr; $i++) {
		if($arr[$i] eq $value) {
			$index = $i;
			last;
		}
	}
	if($index != -1) {
		my $uri = "/modules".$fullpath."/$index"."?command=del";
		$data = "";
		$status = GetData($data, $_[1], $_[2], $server, $port, $uri); 
		if($status == 200) {
			if($data =~ m/^error:\((.*?)\)$/) {
				$code = $1;
			}
		}
		else {
			$code = $status; 
			$_[0] = $data;
		}
	}
	return $code;
}
 
# sub ParseFile (data, authheader, server, port, filename, [func], [param], [value]....)
# Parses the file for all the server side includes and processes them
# returns the processed file data in a scalar
# The multiple sets of arguments func, param, and value are for taking 
# some input in the cgi for some server side includes
# return values: 	200 - parsing okay and qtss returned values
#					data returned is the output
#					401 - parsing okay but qtss returned authorization failed
#					data returned is the auth challenge http headers
# 					500 - qtss is not responding
#					data - must be empty
sub ParseFile {
	my $authheader = $_[1];
	my $server = $_[2];
	my $port = $_[3];
	my $filename = $_[4];
	my %funcparam;
	my $fkey;
	my $fvalue;
	for($i = 5; $i <= $#_; $i = $i + 3) {
		$fkey = $_[$i] . ":" . $_[$i+1];
		$fvalue = $_[$i+2];
		$funcparam{$fkey} = $fvalue;
	}
	
	my $messHash = GetMessageHash();
	my %messages = %$messHash;
	
	local (*TEMPFILE, $_);
	# Open the file
	if(!open(TEMPFILE, $filename)) {
		$_[0] = "$messages{'FileOpenError'} $filename: $!\n";
		return;
	}
	# Read the entire file into a buffer and close file handle
	read(TEMPFILE, $_, -s $filename);
	close(TEMPFILE);
	my %varHash = ();
	my $data = "";
	my $status;
	
	# Look for <%% Func param%%> tags
	while(/^(.*?)<%%(.*?)%%>(.*)$/s) {
    	$_[0] .= $1;
    	$_ = $3;    
	    $tag = $2;
   		if($tag =~ m/^ECHODATA\s+(.*)/s) {
			@params = split /\s+/, $1;
			$uri = "/modules/admin".$params[0];
			$data = "";
			$status = EchoData($data, $messHash, $authheader, $server, $port, $uri, $params[0]);
		    if($status == 401) {
		    	$_[0] = $data;
		    	return $status;
		    }
		    elsif($status == 500) {
		    	$data = "";
		    }
		    $_[0] .= $data;
	   	}
 		elsif($tag =~ m/^GETDATA\s+(.*)/s) {
			#storing the retrieved text in a variable hashed to the name
			@params = split /\s+/, $1;
			$uri = "/modules/admin".$params[1];
			$data = "";
			$status =  GetData($data, $messHash, $authheader, $server, $port, $uri);
			if($status == 401) {
		    	$_[0] = $data;
		    	return $status;
		    }
		    elsif($status == 500) {
		    	undef($data);
		    }
			$varHash{$params[0]} = $data;
    	}
    	elsif($tag =~ m/^GETVALUE\s+(.*)/s) {
			#extract the value from the retreived text and store in a variable for later use
			@params = split /\s+/, $1;
			$uri = "/modules/admin".$params[1];
			$data = "";
			$status = EchoData($data, $messHash, $authheader, $server, $port, $uri, $params[1]);
			if($status == 401) {
		    	$_[0] = $data;
		    	return $status;
		    }
		    elsif($status == 500) {
		    	undef($data);
		    }
			$varHash{$params[0]} = $data;
    	}
    	elsif($tag =~ m/^MAKEARRAY\s+(.*)/s) {
			#storing the array reference returned hashed to the name
			@params = split /\s+/, $1;
			if(defined($varHash{$params[2]})) {
				$arRef = MakeArray($varHash{$params[2]}, $params[1]);
				$varHash{$params[0]} = $arRef;
    		}
    		else {
    			undef($varHash{$params[0]});
      		}
    	}
	    elsif($tag =~ m/^HASVALUE\s+(.*)/s) {
			#returning 1 if the value exists in the array, 0 otherwise
			@params = split /\s+/, $1;
			$params[2] = ($params[2] =~ m/^\'(.*)\'/) ? $1 : $params[2];
			if(defined($varHash{$params[1]})) {
				$found = HasValue($varHash{$params[1]}, $params[2], $params[3]);
				$varHash{$params[0]} = $found;
    		}
    		else {
    			undef($varHash{$params[0]});
    		}
    	}
    	elsif($tag =~ m/^IFVALUEEQUALS\s+(.*)/s) {
			#returning 1 if the value exists in the array, 0 otherwise
			@params = split /\s+/, $1;
			$params[2] = ($params[2] =~ m/^\'(.*)\'/) ? $1 : $params[2];
			if(!defined($varHash{$params[1]})) {
				undef($found);
			}
			elsif($varHash{$params[1]} eq $params[2]) {
				$found = 1;
			}
			else { $found = 0; }
			$varHash{$params[0]} = $found;
    	}
    	elsif($tag =~ m/^CONVERTTOLOCALTIME\s+(\S+)/) {
    		my $timeval = $varHash{$1};
    		if(!defined($timeval)) {
				$_[0] .= "";
			}
			else {
				my @tm = localtime($timeval/1000);
				my $lang = $ENV{"LANGUAGE"};
				if($lang eq "de") {
					$_[0] .= sprintf "%s, %d %s %d %2.2d:%2.2d:%2.2d",
    						$messages{$weekdayStr[$tm[6]]}, $tm[3], $messages{$monthStr[$tm[4]]}, $tm[5]+1900,
    						$tm[2], $tm[1], $tm[0];		
    			}
    			elsif($lang eq "ja") {
    				$_[0] .= sprintf "%d %s %d %s, %2.2d:%2.2d:%2.2d",
    						$tm[5]+1900, $messages{$monthStr[$tm[4]]}, $tm[3], $messages{$weekdayStr[$tm[6]]}, 
    						$tm[2], $tm[1], $tm[0];
    			}
    			elsif($lang eq "fr") {
    				$_[0] .= sprintf "%s %d %s %d %2.2d:%2.2d:%2.2d",
    						$messages{$weekdayStr[$tm[6]]}, $tm[3], $messages{$monthStr[$tm[4]]}, $tm[5]+1900,
    						$tm[2], $tm[1], $tm[0];	
    			}
    			else {
    				$_[0] .= sprintf "%s, %d. %s %d %2.2d:%2.2d:%2.2d",
    						$messages{$weekdayStr[$tm[6]]}, $tm[3], $messages{$monthStr[$tm[4]]}, $tm[5]+1900,
    						$tm[2], $tm[1], $tm[0];			
    			}

    		}
    	}
		elsif($tag =~ m/^ACTIONONDATA\s+(\S+)\s+(\S+)\s+(\S+)\s+\'(.*?)\'(\s*)/s) {
			$refKey = $1;
			if(defined($varHash{$2}) && defined($varHash{$3})) {
				$varHash{$refKey} = eval($varHash{$2} . $4 . $varHash{$3});
			}
			else {
				undef($varHash{$refKey});
			}
		}
		elsif($tag =~ m/^FORMATFLOAT\s+(\S+)/s) {
			if(defined($varHash{$1})) {
				$_[0] .= sprintf "%3.2f", $varHash{$1};
			}
			else {
				$_[0] .= "";
			}
		}
		elsif($tag =~ m/^CONVERTMSECTIMETOSTR\s+(\S+)/) {
			if(defined($varHash{$1})) {
				my $timeStr = ConvertTimeToStr($varHash{$1}, $messHash);
				$_[0] .= $timeStr;
			}
			else {
				$_[0] .= "";
			}
		}
    	elsif($tag =~ m/^MODIFYDATA\s+(\S+?)\s+\'(.*?)\'\s+\'(.*?)\'/s) {
    		$value = $varHash{$1};
    		$condition = $2;
    		$action = $3;
    		if(defined($value)) {
    			$newVal = ModifyData($value, $condition, $action);
    			$_[0] .= $newVal;
    		}
    		else {
    			$_[0] .= "";
    		}
    	}
    	elsif($tag =~ m/^PRINTFILE\s+(\S+?)\s+(\S+)/s) {
    		if(!defined($varHash{$1}) || !defined($varHash{$2})) {
    			$_[0] .= "";
    		}
    		else {
    			$_[0] .= GetFile($varHash{$1}, $varHash{$2}, $messHash);
    		}
    	}
    	elsif($tag =~ m/^PRINTHTMLFORMATFILE\s+(\S+?)\s+(\S+)/s) {
    		if(!defined($varHash{$1}) || !defined($varHash{$2})) {
    			$_[0] .= "";
    		}
    		else {
    			$_[0] .= GetFormattedFile($varHash{$1}, $varHash{$2}, $messHash);
    		}
    	}
    	elsif($tag =~ m/PROCESSFILE\s+(\S+?)\s+(\S+?)\s+(\S+?)\s+(\S+)/s) {
    		my $ref = $1;
    		if(defined($varHash{$2}) && defined($varHash{$2})){
    		   $varHash{$ref} = ProcessFile($varHash{$2}, $varHash{$3}, $4);
    		}
    		else {
    			undef($varHash{$ref});
    		}
    	}
    	elsif($tag =~ m/^HTMLIZE\s+(\S+)/s) {
 			$text = $varHash{$1};
 			if(defined($text)) {
 				$htmlText = HtmlEscape($text);
 				$_[0] .= $htmlText;
 			}
 			else {
 				$_[0] .= "";
 			}
 		}
 		elsif($tag =~ m/^PRINTDATA\s+(\S+)\s+\'(.*?)\'\s+\'(.*?)\'/s) {
 			if(!defined($varHash{$1})) {
 				$_[0] .= "";
 			} elsif( $varHash{$1} == 1) {
 				$_[0] .= $2;
 			} else {
 				$_[0] .= $3;
 			}
 		}
 		elsif($tag =~ m/^CONVERTTOVERSIONSTR\s+(\S+)/s) {
 			if(defined($varHash{$1})) {
 				$_[0] .= ConvertToVersionString($varHash{$1});
 			}
 			else {
 				$_[0] .= "";
 			}
 		}
 		elsif($tag =~ m/^CREATESELECTFROMINPUTWITHFUNC\s+(\S+?)\s+(\S+?)\s+(.*)/s) {
	    	my $name = $1;
	    	$value = $funcparam{"CREATESELECTFROMINPUTWITHFUNC:$name"};
	    	if(defined($value)) {
	    		my $handler = $2;
	    		my $optstr = $3;
	    		my @options = ();
	    		my $i = 0;
	    		
	    		while($optstr =~ m/\'(.*?)\'\s+(.*)/) {
	    			$options[$i] = "<OPTION>". $1;
	    			$optstr = $2;
	    			$i++;
	    		}
	    		if($optstr =~ m/\'(.*?)\'/) {
	    			$options[$i] = "<OPTION>". $1;
	    		}
	    		
	    		$options[$value] =~ s/OPTION/OPTION SELECTED/;
	    		
	    		my $result = qq(<SELECT NAME=") . $name. qq(" onChange=") . $handler. qq(()">);
	    		for($i = 0; $i<=$#options; $i++) {
	    			$result .= "$options[$i]\n";
				}
                 $result .=qq(</SELECT>);
				$_[0] .= $result;
			}
		}
		elsif($tag =~ m/^CREATESELECTFROMINPUT\s+(\S+?)\s+(.*)/s) {
	    	my $name = $1;
	    	$value = $funcparam{"CREATESELECTFROMINPUT:$name"};
	    	if(defined($value)) {
	    		my $optstr = $2;
	    		my @options = ();
	    		my $i = 0;
	    		
	    		while($optstr =~ m/\'(.*?)\'\s+(.*)/) {
	    			$options[$i] = "<OPTION>". $1;
	    			$optstr = $2;
	    			$i++;
	    		}
	    		if($optstr =~ m/\'(.*?)\'/) {
	    			$options[$i] = "<OPTION>". $1;
	    		}
	    		
	    		$options[$value] =~ s/OPTION/OPTION SELECTED/;
	    		
	    		my $result = qq(<SELECT NAME=") . $name. qq(">);
	    		for($i = 0; $i<=$#options; $i++) {
	    			$result .= "$options[$i]\n";
				}
                 $result .=qq(</SELECT>);
				$_[0] .= $result;
			}
		}
		elsif($tag =~ m/^SORTRECORDSWITHINPUT\s+(\S+?)\s+(\S+?)\s+(\S+?)\s+(\S+)/s) {
    		my $refKey = $1;
    		$value = $funcparam{"SORTRECORDSWITHINPUT:sortOrder"};
    		if(defined($value) && defined($varHash{$2})) { 
    			$varHash{$refKey} = SortRecords($varHash{$2}, $3, $4, $value);
    		}
		}
		elsif($tag =~ m/^GENJAVASCRIPTIFSTATECHANGE\s+\'(.*)\'/s) {
    		$value = $funcparam{"GENJAVASCRIPTIFSTATECHANGE:stateChange"};
    		if(defined($value) && ($value == 1)) { 
    			$_[0] .= $1;
    		}
		}
		elsif($tag =~ m/^IFREMOTE\s+\'(.*?)\'\s+\'(.*)\'/s) {
    		my $remoteData = $1;
    		my $localData = $2;
    		$value = $funcparam{"IFREMOTE:ipaddress"};
    		$localAddress = inet_ntoa(INADDR_LOOPBACK);
    		if($value ne $localAddress) { 
    			$_[0] .= $remoteData;
    		}
    		else {
    			$_[0] .= $localData;
    		}
		}
		elsif($tag =~ m/^IFOSX\s+\'(.*)\'/s) {
		    if($^O eq "darwin") {
    			$_[0] .= $1;
		    }
		}
		elsif($tag =~ m/^IFNOTOSX\s+\'(.*)\'/s) {
		    if($^O ne "darwin") {
    			$_[0] .= $1;
		    }
		}
		elsif($tag =~ m/^IFOSXAUTOSTARTCHECKBOX$/) {
		    if($^O eq "darwin") {
				if(-r $confPath) {
					$tempBuf = $_;
			    	open(CONFFILE, "<$confPath");
			    	while(<CONFFILE>) {
						chop;
						if (/^#/ || !/\S/) {
				    		next; 
						}
						/^([^=]+)=(.*)$/;
						$name = $1; $val = $2;
						$name =~ s/^\s+//g; $name =~ s/\s+$//g;
						$val =~ s/^\s+//g; $val =~ s/\s+$//g;
						if($name eq "qtssAutoStart") {
						    $autoStart = $val;
						    last;
						}
			    	}
			    	close(CONFFILE);
					$_ = $tempBuf;
				}
    			if($autoStart == 1) {
			    	$_[0] .= qq(<INPUT TYPE=checkbox NAME="Auto Start" VALUE="1" CHECKED>);
    			}
    			else {
			    	$_[0] .= qq(<INPUT TYPE=checkbox NAME="Auto Start" VALUE="0">);
    			}
		    }
		}
 		elsif($tag =~ m/^CONVERTTOSTATESTR\s+(\S+)/s) {
 			$_[0] .= GetServerStateString($varHash{$1}, $messHash);
 		}
    	elsif($tag =~ m/^FILTERSTRUCT\s+(.*)/s) {
			#filter the elements of the data structure
			@params = split /\s+/, $1;
			$params[3] = ($params[3] =~ m/^\'(.*)\'/) ? $1 : $params[3];
			if(defined($varHash{$params[1]})) {
				$arRef = FilterStructArray($varHash{$params[1]}, $params[2], $params[3]);
				$varHash{$params[0]} = $arRef;
    		}
    		else {
    			undef($varHash{$params[0]});
    		}
    	}
    	elsif($tag =~ m/^FORMATDATA\s+(\S+?)\s+\'(.*?)\'\s+'(.*?)\'\s+'(.*?)\'\s+'(.*?)\'\s+'(.*?)\'/s) {
    		if(defined($varHash{$1})) {
    			$formatValue = FormatData($varHash{$1}, $2, $3, $4, $5, $6); 
    			$_[0] .= $formatValue;
    		}
    		else {
    			$_[0] .= "";
    		}
    	}
	elsif($tag =~ m/^FORMATBYTESTOREADABLEUNITS\s+(\S+)/s) {
	    $valueInBytes = $varHash{$1};
	    if(defined($valueInBytes)) {
		if($valueInBytes < 1024) {         
		    $_[0] .= "$valueInBytes " . $messages{'BytesStr'};
		}
		elsif($valueInBytes < (1024 * 1024)) {
		    $valueInBytes /= 1024;
		    $_[0] .= sprintf("%3.3f", $valueInBytes) . " " . $messages{'KiloBytesStr'};
		}
		elsif($valueinBytes < (1024 * 1024 * 1024)) {
		    $valueInBytes /= (1024 * 1024);
		    $_[0] .= sprintf("%3.3f", $valueInBytes) . " " . $messages{'MegaBytesStr'};
		}
		else {
		    $valueInBytes /= (1024 * 1024 * 1024);
		    $_[0] .= sprintf("%3.3f", $valueInBytes) . " " . $messages{'GigaBytesStr'};
		}
	    }
	    else {
		$_[0] .= "";
	    }
	}
    	elsif($tag =~ m/^FORMATRADIOBUTTON\s+(\S+)\s+\'(.*?)\'\s+\'(.*?)\'\s+(\S+)/s) {
    		$cond = $varHash{$1};
    		if(defined($cond)) {
	    		$formatData = FormatRadioButton($2, $3, $cond, $4);
	    		$_[0] .= $formatData;
    		}
    		else {
    			$_[0] .= "";
    		}
    	}
    	elsif($tag =~ m/^FORMATSUBMITBUTTON\s+(\S+?)\s+\'(.*?)\'\s+\'(.*?)\'\s+\'(.*?)\'\s+\'(.*?)\'/s) {
    		$expr = $varHash{$1};
    		$name = $2;
    		$cond = $3;
    		if(eval($expr . $3)) {
    			$value = $4;
    		}
    		else {
    			$value = $5;
    		}
    		$_[0] .= qq(<INPUT TYPE="submit" NAME="$name" VALUE ="$value">);
    	}
    	elsif($tag =~ m/^FORMATSELECTOPTION\s+(\S+)\s+\'(.*?)\'\s+\'(.*?)\'\s+\'(.*?)\'\s+\'(.*?)\'\s+(\S+)/s) {
    		$value = $varHash{$1};
    		$selectName = $2;
    		$condition = $3;
    		$opt1 = $4;
    		$opt2 = $5;
    		$selectOpt = $6;
    		$formatData = FormatSelectOption($value, $condition, $selectName, $opt1, $opt2, $selectOpt);
    		$_[0] .= $formatData;
    	}
	    elsif($tag =~ m/^FORMAT\s+(\S+)\s+(\S+)\s+(\S+)\s+\'(.*?)\'\s+\'(.*?)\'/s) {
			#format the elements of the array
			$arRef = $varHash{$1};
			$formatText = FormatArray($arRef, $2, $3, $4, $5);
			$_[0] .= $formatText;
	    }	
    	elsif($tag =~ m/^DEFINEINDEXHASH\s+(.*)/s) {
    		@params = split /\s+|\r|\n/, $1;
			$hRef = {};
			$hRefKey = shift @params;
			for($i=0;$i<=$#params;$i++) {
				$hRef->{$params[$i]} = ($i + 1);
			}
			$varHash{$hRefKey} = $hRef;
    	}
    	elsif($tag =~ m/^GETALLRECORDS\s+(\S+?)\s+(\S+?)\s+(\S+)/s) {
    		my $arKey = $1;
    		$data = "";
    		$status = GetAllRecords($data, $messHash, $authheader, $server, $port, $varHash{$2}, $3);
    		if($status == 401) {
    			$_[0] = $data;
    			return $status;
    		}
    		$varHash{$arKey} = $data;
	}
        elsif($tag =~ m/^FILTERRECORDS\s+(\S+?)\s+(\S+?)\s+(\S+)/s) {
	    my $refKey = $1;
	    $varHash{$refKey} = FilterRecords($varHash{$2}, $3);
	}
    	elsif($tag =~ m/^MODIFYCOLUMNWITHCONDS\s+(\S+?)\s+(\S+?)\s+(\S+?)\s+(\S+?)\s+(\S+?)\s+\'(.*?)\'\s+\'(.*?)\'\s+\'(.*?)\'\s+\'(.*?)\'\s+\'(.*?)\'/s) {
    		my $refKey = $1;
    		$varHash{$refKey} = ModifyColumnWithConds($varHash{$2}, $3, $4, $5, $6, $7, $8, $9, $10);
    	}
    	elsif($tag =~ m/^CONVERTCOLUMNTOSTRTIME\s+(\S+?)\s+(\S+?)\s+(\S+?)\s+(\S+?)\s+(\S+)/s) {
    		my $refKey = $1;
    		$varHash{$refKey} = ConvertColumnToStrTime($varHash{$2}, $3, $4, $5, $messHash);
    	}
    	elsif($tag =~ m/^SORTRECORDS\s+(\S+?)\s+(\S+?)\s+(\S+?)\s+(\S+?)\s+(\S+)/s) {
    		my $refKey = $1;
    		$varHash{$refKey} = SortRecords($varHash{$2}, $3, $4, $5);
    	}
    	elsif($tag =~ m/^FORMATPLAYLISTTABLE/s) {
    		my @labels;
    		$labels[0] = "$messages{'PLState_0'}";
    		$labels[1] = "$messages{'PLState_1'}";
    		$labels[2] = "$messages{'PLState_2'}";
    		$_[0] .= &playlistlib::EmitMainPlaylistHTML(\@labels);
    	}
     	elsif($tag =~ m/^FORMATCURRENTPLAYLIST/s) {
     	    my $trailer = $_;
     	    my $label = "$messages{'PLMovie'}";
     	    my $pln = &playlistlib::PopCurrPlayList();
    		$_[0] .= &playlistlib::GeneratePLDetailTable($pln, $label);
    		$_ = $trailer;
    	}
    	elsif($tag =~ m/^CURPLAYLISTURL/s) {
     	    my $pln = &playlistlib::PopCurrPlayList();
       	    my $url = $varHash{"pl_url"};
	   	    #
     	    # $varHash{"pl_url"} is set by CURPLAYLIST tag.
     	    #
     	    if (($url eq "") || ($url eq "sample.sdp")) {
     	    	# default value is same as playlist name
     	    	$url = "$pln.sdp";
     	    }
    		$_[0] .= $url;
    	}
 		elsif($tag =~ m/^ISCURPLAYLISTMODE\s+(\S+)/s) {
       	    my $mode = $varHash{"pl_mode"};
     	    if ($mode eq $1) {
     	    	$mode = "selected";
     	    }
     	    else {
     	    	$mode = "";
     	    }
    		$_[0] .= $mode;
    	}
    	elsif($tag =~ m/^CURPLAYLISTLOGSTATE/s) {
       	    my $logstate = $varHash{"pl_logstate"};
	   	    #
     	    # $varHash{"pl_logstate"} is set by CURPLAYLIST tag.
     	    #
     	    if ($logstate eq "enabled") {
     	    	$logstate = " checked";
     	    }
     	    else {
     	    	$logstate = "";
     	    }
    		$_[0] .= $logstate;
    	}
    	elsif($tag =~ m/^CURPLAYLISTMAXREPS/s) {
       	    my $maxreps = $varHash{"pl_maxreps"};
	   	    #
     	    # $varHash{"pl_maxreps"} is set by CURPLAYLIST tag.
     	    #
    		$_[0] .= $maxreps;
    	}
    	elsif($tag =~ m/^CURPLAYLIST/s) {
    		# this happens whenever we display the detail page for a  playlist
      	    my $trailer = $_;
    	    my $pln = &playlistlib::PopCurrPlayList();
		    my @plc = ();
            my $stat = GetMovieDir($dirname, $messHash, $authheader, $server, $port);
 	        my $temp = &playlistlib::ParsePlayListEntry($pln);
 			@plc = (@$temp);
 			$varHash{"pl_url"} = $plc[0];
 			$varHash{"pl_mode"} = $plc[1];
 			$varHash{"pl_logstate"} = $plc[2];
 			$varHash{"pl_maxreps"} = $plc[4];
  		    $_[0] .= &playlistlib::DecodePLName($pln);
  		    &playlistlib::PushCurrPWDir($dirname);
     		$_ = $trailer;
   		}
    	elsif($tag =~ m/^MOVIELIST/s) {
     	    my $trailer = $_;
     	   	my $dirname = "";
    	    $dirname = &playlistlib::PopCurrPWDir();
    		my @labels;
    		$labels[0] = "$messages{'PLDirectory'}";
    		$labels[1] = "$messages{'PLMovie'}";
    		$labels[2] = "$messages{'Http404Status'}";
    		$_[0] .= &playlistlib::EmitMovieListHtml($dirname, \@labels);
    		$_ = $trailer;
    	}
    	elsif($tag =~ m/^CURRMOVIEDIR/s) {
     	    my $trailer = $_;
     	   	my $dirname = "";
    	    $dirname = &playlistlib::PopCurrPWDir();
    	    if ($dirname eq "") {
            	my $stat = GetMovieDir($dirname, $messHash, $authheader, $server, $port);
    	    }
    		$_[0] .= $dirname;
    		$_ = $trailer;
    	}
    	elsif($tag =~ m/^REMOVEMOVIETBL/s) {
     	    my $trailer = $_;
      	    my $label = "$messages{'PLMovie'}";
    	    my $pln = &playlistlib::PopCurrPlayList();
    		$_[0] .= &playlistlib::GeneratePLRemoveMovieTable($pln, $label);
    		$_ = $trailer;
    	}
    	elsif($tag =~ m/FORMATDDARRAYWITHINPUT\s+(\S+?)\s+(\S+?)\s+\'(.*?)\'\s+\'(.*?)\'\s+(.*)/s) {
			my $dArrRef = $varHash{$1};
			my @da = @$dArrRef;
			my $begIndex = $2;
			my $endIndex = -1;
			$value = $funcparam{"FORMATDDARRAYWITHINPUT:numEntries"};
    		if(defined($value)) { 
    			$endIndex = $value;
    		}
			my $begRowFormat = $3;
			my $endRowFormat = $4;
			my @formatArr = ();
			my $format = $5;
			my $i = 0;
			while ($format =~ m/^(\S+)\s+\'(.*?)\'\s+\'(.*?)\'\s+(.*)/s) {
			    $formatArr[$i] = $1;
			    $formatArr[++$i] = $2;
			    $formatArr[++$i] = $3;
			    $format = $4;
			    $i++;
			}
			if($format =~ m/^(\S+)\s+\'(.*?)\'\s+\'(.*?)\'(\s*)/s) {
				$formatArr[$i] = $1;
				$formatArr[++$i] = $2;
				$formatArr[++$i] = $3;
			}
			$formatText = FormatDDArray($dArrRef, $begIndex, $endIndex, $begRowFormat, $endRowFormat, @formatArr);
			$_[0] .= $formatText;
		}
		elsif($tag =~ m/FORMATDDARRAY\s+(\S+?)\s+(\S+?)\s+(\S+?)\s+\'(.*?)\'\s+\'(.*?)\'\s+(.*)/s) {
			my $dArrRef = $varHash{$1};
			my @da = @$dArrRef;
			my $begIndex = $2;
			my $endIndex = $3;
			my $begRowFormat = $4;
			my $endRowFormat = $5;
			my @formatArr = ();
			my $format = $6;
			my $i = 0;
			while ($format =~ m/^(\S+)\s+\'(.*?)\'\s+\'(.*?)\'\s+(.*)/s) {
			    $formatArr[$i] = $1;
			    $formatArr[++$i] = $2;
			    $formatArr[++$i] = $3;
			    $format = $4;
			    $i++;
			}
			if($format =~ m/^(\S+)\s+\'(.*?)\'\s+\'(.*?)\'(\s*)/s) {
				$formatArr[$i] = $1;
				$formatArr[++$i] = $2;
				$formatArr[++$i] = $3;
			}
			$formatText = FormatDDArray($dArrRef, $begIndex, $endIndex, $begRowFormat, $endRowFormat, @formatArr);
			$_[0] .= $formatText;
		}
	}
	$_[0] .= $_;
	return $status;
}

# sub GetAllRecords($data, $messageHash, $authheader, $server, $port, \%IndexHash, $requestStr)
sub GetAllRecords {
	my $messHash = $_[1];
	my $authheader = $_[2];
	my $uri = "/modules/admin".$_[6]."*?command=get+";
	my $hRef = $_[5];
	my $filterstr;
	my $num = 1;
	foreach $filterstr (keys %$hRef) {
		$uri .= "filter$num=$filterstr+";
		$num++;
	}
	my $data = "";
	print ($uri);
	my $status = GetData($data, $messHash, $authheader, $_[3], $_[4], $uri);		
	if($status != 200) {
		$_[0] = $data;
		return $status;
	}
	my @lines = split /\r|\n/, $data;	
	my @ddArr;
	my $i, $j, @elem;
	my @indexArr;
	
	if($lines[0] =~ m/^Container=\".*?\/(\w+)\/\"/) {
		$ddArr[0]->[0] = $1;
		for($j = 0; $j < ($num-1) ; $j++) {
			if($lines[$j + 1] =~ m/^(.*?)=\"(.*?)\"\s*$/) {
				my $ind = $hRef->{$1};
				$indexArr[$j] = $ind;
				$ddArr[0]->[$ind] = $2;
			}
		 }
	}
	
	$k = 0;
	for($i = $num; $i <= $#lines; $i += $num) {
		if($lines[$i] =~ m/^Container=\".*?\/(\w+)\/\"/) {
			$k++;
			$ddArr[$k]->[0] = $1;
			for($j = 0; $j < ($num-1); $j++) {
				if($lines[$i + $j + 1] =~ m/^(.*?)=\"(.*?)\"\s*$/) {
					$ddArr[$k]->[($indexArr[$j])] = $2;
	    		}
			}
		}
	}
	$_[0] = \@ddArr;
	return $status;		
}


# sub GetAllRecords_WithoutFilters($data, $messageHash, $authheader, $server, $port, \%IndexHash, $requestStr)
sub GetAllRecords_WithoutFilters {
	my $data = "";
	my $status = GetData($data, $_[1], $_[2], $_[3], $_[4], "/modules/admin".$_[6]."*");
	if($status != 200) {
		$_[0] = $data;
		return $status;
	}
	
	my @lines = split /\n/, $data;
	my @ddArr;
	my $hRef = $_[5];
	my $i = 0;
	
	my $line = shift @lines;
	while(@lines) {
		if($line =~ m/^Container=\".*?\/(\w+)\/\"/) {
			$ddArr[$i] = ();
			$ddArr[$i]->[0] = $1;
			while(@lines) {
				$line = shift @lines;
				if($line =~ /^Container=.*$/) {
		    		last;
				}
				if($line =~ m/^(.*?)=\"(.*?)\"\s*$/) {
					my $ind = $hRef->{$1};
					if(defined($ind)) {
						$ddArr[$i]->[$ind] = $2;
		    		}
				}
			}
			$i++;
		}
	}
	$status = \@ddArr;
	return $status; 	
}

# sub FilterRecords(\@dArrRef, $column)
sub FilterRecords {
    my ($dArrRef, $col) = @_;
    my @dArr = @$dArrRef;
    my @newDArr = ();
    my $i;
    for($i = 0; $i <= $#dArr; $i++) {
	        my $arRef = $dArr[$i];
		my @newArr = @$arRef;
		if($newArr[$col] eq "") {
		    push(@newDArr, \@newArr);
		}
    }
    return \@newDArr;
}

# sub ModifyColumnWithConds(\@dArrRef, $column, $begIndex, $endIndex, $cond, $truAction, $truSuffix, $falAction, $falSuffix)
sub ModifyColumnWithConds {
	my ($dArrRef, $col, $b, $e, $cond, $truAct, $truSuf, $falAct, $falSuf) = @_;
	my @dArr = @$dArrRef;
	my @newDArr = ();
	$e = ($e == -1)? $#dArr : $e;
	my $i;
	for($i = $b; $i <= $e; $i++) {
		my $arRef = $dArr[$i];
		my @newAr = @$arRef;
		my $colValue = $newAr[$col];
		if(eval($colValue . $cond)) {
			$colValue = int(eval($colValue . $truAct)) . $truSuf;
		}
		else {
			$colValue = int(eval($colValue . $falAct)) . $falSuf;
		}
		$newAr[$col] = $colValue;
		$newDArr[$i] = \@newAr;
	}
	return \@newDArr;
}

# sub ConvertColumnToStrTime(\@dArrRef, $col, $begIndex, $endIndex, $messageHash)
sub ConvertColumnToStrTime {
	my ($dArrRef, $col, $b, $e, $messHash) = @_;
	my @dArr = @$dArrRef;
	my @newDArr = ();
	$e = ($e == -1)? $#dArr : $e;
	my $i;
	for($i = $b; $i <= $e; $i++) {
		my $arRef = $dArr[$i];
		my @newAr = @$arRef;
		$newAr[$col] = ConvertTimeToStr($newAr[$col], $messHash);
		$newDArr[$i] = \@newAr;
	}
	return \@newDArr;
}
 
 
sub byAlphaAscending {
    $a->[0] cmp $b->[0];
}

sub byAlphaDescending {
    $b->[0] cmp $a->[0];
}

sub byNumberAscending {
    $a->[0] <=> $b->[0];
}

sub byNumberDescending {
    $b->[0] <=> $a->[0];
} 
 
# sub SortRecords(\@dArrRef, $index, [num|alpha], [0|1])
sub SortRecords {
	my ($dArrRef, $index, $type, $order) = @_;
	my @dArr = @$dArrRef;
	my @sortArr = ();
	my $i;
	for($i = 0; $i <= $#dArr; $i++) {
		my $ar = ();
		$ar->[0] = $dArr[$i][$index];
		$ar->[1] = $dArr[$i];
		$sortArr[$i] = $ar;
	}
	
	my @sortedArr;
	if($type eq "num") {
		if($order == 0) {
			@sortedArr = sort byNumberAscending @sortArr;
		} elsif($order == 1) {
			@sortedArr = sort byNumberDescending @sortArr;	
		}
	} elsif($type eq "alpha") {
		if($order == 0){
			@sortedArr = sort byAlphaAscending @sortArr;
		} elsif($order == 1) {
			@sortedArr = sort byAlphaDescending @sortArr;	
		}
	}
	my @resultArr;
	for($i = 0; $i <= $#sortedArr; $i++) {
		$resultArr[$i] = $sortedArr[$i][1];
	}
	return \@resultArr;
}

# sub FormatDDArray(\@dArrRef, $begIndex, $endIndex, $begRowFormat, $endRowFormat, @formatArr)
sub FormatDDArray {
	my $dArrRef = shift @_;
	my @dArr = @$dArrRef;
	my $r, $dumbR, $dumbA;
	my $b = shift @_;
	my $e = shift @_;
	my $e = ($e == -1)? $#dArr : $e;
	my $bformat = shift @_;
	my $eformat = shift @_;
	my @formatArr = @_;
	my %prefix;
	my %suffix;
	my $i = 0;
	while($i<=$#formatArr) {
		my $key = $formatArr[$i];
		$prefix{$key} = $formatArr[++$i];
		$suffix{$key} = $formatArr[++$i];
		$i++;
	}
	my $result = "";
	# if the end exceeds the array size, cut it down
	if($e > $#dArr) {
		$e = $#dArr;
	}
	for($i=$b; $i <= $e; $i++) {
		my $arRef = $dArr[$i];
		$result .= $bformat;
		for $prekey (sort keys %prefix) {
			$result .= $prefix{$prekey} . ($arRef->[$prekey]) . $suffix{$prekey};
		}
		$result .= $eformat;
	}
	return $result;
}

# sub ModifyData(value, condition, action)
sub ModifyData {
	$oldVal = $_[0];
	$expr = $oldVal . $_[1];
	$result = $oldVal . $_[2];
	if(eval($expr)) {
		return (int(eval($result)));
	}
	else {
		return $oldVal;
	}
}

# sub GetFile(dirname, filename, messageHash) 
sub GetFile {
	my ($dirname, $filename, $messHash) = @_;
	my %messages = %$messHash;
	my $path = $dirname . qq(/) . $filename . ".log";
	my ($line, $text);
	$text = "";
	open(FILE, $path) or print "$messages{'FileOpenError'} $path: $!\n";
	while($line = <FILE>) {
		$text .= $line;
	}
	close(FILE);
	return $text;
}

# sub GetFormattedFile(dirname, filename, messageHash) 
sub GetFormattedFile {
	my ($dirname, $filename, $messHash) = @_;
	my %messages = %$messHash;
	
	my $path;
	if($^O eq "MSWin32") {
	    $path = $dirname . qq(\\) . $filename . ".log";
	}
	else {
	    $path = $dirname . qq(/) . $filename . ".log";
	}
		
	my ($line, $text);
	$text = "";
	
	if(open(FILE, $path)) {
		while($line = <FILE>) {
			if($line =~ m/^#/) {
				$line = qq(<B>) . $line . qq(</B>) . qq(<BR>);
			}
			else {
				$line .= qq(<BR>);
			}		 
			$text .= $line;
		}
		close(FILE);
	}
	else {
		$text = qq(<B>) . "$messages{'FileOpenError'}: $path. $!" . qq(</B>) . qq(<BR>);
	}
	return $text;
}

# sub ProcessFile($dirname, $filename, $index);
sub ProcessFile {
	my ($dirname, $filename, $index) = @_;
	my $path = $dirname . qq(/) . $filename . ".log";
	
	sysopen(FILE, $path, 0);
	my $numBytesRead = 0;
	my ($chunk, $isincomplete);
	my $offset = 0;
	my %samples;
	my @params;
	my $count;
	while($numBytesRead = sysread(FILE, $chunk, 10240, $offset)) {
		if(!defined($numBytesRead)) {
			next if $! =~ /^Interrupted/;
			die "system read error: $!\n";
		}
		if($chunk !~ m/^(.*)[\r\n]$/) {
			$isincomplete = 1;
		}
		else {
			$isincomplete = 0;
		}
		my @lines = split /\r|\n/, $chunk;
		$offset = 0;
		if($isincomplete == 1) {
			$chunk = pop @lines;
			$offset = length $chunk;
		}
		while(@lines) {
			$line = shift @lines;
			if(($line !~ m/^#/) && ($line !~ m/^(\s*)$/)){
				@params = split /\s+/, $line;
				$count = $samples{$params[$index]};
				$samples{$params[$index]} = (defined($count))?($count+1):1; 
			}
		}
		undef @lines;
	}
	close(FILE);
	
	if(($isincomplete == 1) && ($chunk !~ m/^#(.*)/)) {
		@params = split /\s+/, $chunk;
		$count = $samples{$params[$index]};
		$samples{$params[$index]} = (defined($count))?($count+1):1;  	
	}
	
	my @dArr;
	my $sampl;
	my $i = 0;
	foreach $sampl (keys %samples) {
		$dArr[$i] = ();
		$dArr[$i]->[0] = $sampl;
		$dArr[$i]->[1] = $samples{$sampl};
		$i++;
	}
	return \@dArr;
}


# sub ConvertTimeToStr(timeInmSec, messageHash)
sub ConvertTimeToStr {
	my $timeStr;
	my $messHash = $_[1];
	my %messages = %$messHash;
	
	my $sec = $_[0]/1000;
	my $days = int ($sec / 86400);
	if($days != 0) { $timeStr = "$days $messages{'DaysStr'}"; }	
	$sec %= 86400;
	my $hr = int ($sec / 3600);
	if($hr != 0) { $timeStr .= " $hr $messages{'HoursStr'}"; }	
	$sec %= 3600;
	my $min = int ($sec / 60);
	if($min != 0) { $timeStr .= " $min $messages{'MinutesStr'}"; }	
	$sec %= 60;
	if($sec != 0) { $timeStr .= " $sec $messages{'SecondsStr'}"; }
	return $timeStr; 
}

# sub FormatData(value, condition, trueAction, trueSuffix, falseAction, falseSuffix)
sub FormatData {
	$expr = $_[0] . $_[1];
	$trueResult = $_[0] . $_[2];
	$falseResult = $_[0] . $_[4]; 
	if(eval($expr)) {
		$result = int(eval($trueResult));
		return ("$result" . $_[3]);
	}
	else {
	 	$result = int(eval($falseResult));
		return ("$result" . $_[5]);
	}
}

# sub FormatSelectOption(value, condition, selectName, option1, option2, selectOptionNumberIfTrue) 
sub FormatSelectOption {
	$expr = $_[0] . $_[1];
	$name = $_[2];
	$opt1Name = $_[3];
	$opt2Name = $_[4];
	$selectOpt = $_[5];
	$result = eval($expr); 
	if(($result && ($selectOpt == 1)) || (!$result && ($selectOpt == 2))) {
		return (qq(<SELECT NAME="$_[2]"><OPTION VALUE="0" SELECTED>$opt1Name<OPTION VALUE="1">$opt2Name</SELECT>));
	}
	elsif(($result && ($selectOpt == 2)) || (!$result && ($selectOpt == 1))) {
		return (qq(<SELECT NAME="$_[2]"><OPTION VALUE="0">$opt1Name<OPTION VALUE="1" SELECTED>$opt2Name</SELECT>));
	}
	else {
	 	return (qq(<SELECT NAME="$_[2]"><OPTION>$opt1Name<OPTION>$opt2Name</SELECT>));
	}
}

# sub FormatRadioButton(name, value, 1|0, checked|unchecked)  
sub FormatRadioButton {
	if((($_[2] == 1) && ($_[3] eq "checked")) || (($_[2] == 0) && ($_[3] eq "unchecked"))) {
		return (qq(<INPUT TYPE=radio NAME="$_[0]" VALUE=$_[1] CHECKED>));
	}
	elsif((($_[2] == 1) && ($_[3] eq "unchecked")) || (($_[2] == 0) && ($_[3] eq "checked"))){
	 	return (qq(<INPUT TYPE=radio NAME="$_[0]" VALUE=$_[1]>));
	}
}

# HtmlEscape
# Convert &, < and > codes in text to HTML entities
sub HtmlEscape
{
	local($tmp);
	$tmp = $_[0];
	$tmp =~ s/&/&amp;/g;
	$tmp =~ s/</&lt;/g;
	$tmp =~ s/>/&gt;/g;
	$tmp =~ s/\"/&#34;/g;
	return $tmp;
}

# sub StartServer(prog)
sub StartServer() {
	my $prog = $_[0];
	if($^O eq "MSWin32") {
		eval "require Win32::Service";
		if(!$@) {
                  #my %serviceList = ();
		  #Win32::Service::GetServices("", \%serviceList);
		  #foreach $key (keys %serviceList)
		  #{
		  #    print "key: $key value: $serviceList{$key}\n";
		  #}
		  Win32::Service::StartService("", "Darwin Streaming Server");
		}
	}
	else {
		# fork off a child and exec the server
		if(!($pid = fork())) {
			exec $prog, '-I';
			exit;
		}
	}
}

# GetServerStateString(state, messageHash)
# Maps the given number to the server state
# returns the corresponding string
# qtssStartingUpState|qtssRunningState|qtssRefusingConnectionsState|qtssFatalErrorState|qtssShuttingDownState
sub GetServerStateString {
	my $state = $_[0];
	my $messHash = $_[1];
	my %messages = %$messHash;
		
	if(!defined($state)) {
		$state = -1;
	}
	my @serverStateArr = (
		"$messages{'ServerStartingUpStr'}",
		"$messages{'ServerRunningStr'}",
		"$messages{'ServerRefusingConnectionsStr'}",
		"$messages{'ServerInFatalErrorStateStr'}",
		"$messages{'ServerShuttingDownStr'}",
		"$messages{'ServerIdleStr'}"
	);
	if($state < 0 || $state > $#serverStateArr) {
		return "$messages{'ServerNotRunningStr'}";
	}
	return $serverStateArr[$state];
}

# ParseQueryString (queryString)
# Parses the name=value&name=value ... query string 
# and creates a hash of with names as keys
# Returns the reference to the hash
sub ParseQueryString {
	%qs = ();
	@qs = ();
    $qs = shift @_;
    # split it up into an array by the '&' character
    @qs = split(/&/,$qs);
    foreach $i (0 .. $#qs)
    {
	# convert the plus chars to spaces
	$qs[$i] =~ s/\+/ /g;
	
	# convert the hex characters
	$qs[$i] =~ s/%(..)/pack("c",hex($1))/ge;
	
	# remove backticks (for security reasons)
	$qs[$i] =~ s/[`]//g;
	
	# split each one into name and value
	($name, $value) = split(/=/,$qs[$i],2);
	
	# create the associative element
	$qs{$name} = $value;
    }
    return \%qs;
}

# ConvertToVersionString ( version )
# converts the number to a hex string 
sub ConvertToVersionString {
    my $version = sprintf "%lx", $_[0];
    
    my @resultArr = unpack "h", $version;
    my $result = ($resultArr[0] == 0)? "0" : "$resultArr[0]";
    $result .= "\.";
    $result .= ($resultArr[1] == 0)? "0" : "$resultArr[1]";
    
    return $result;
}

# StripPath ( filename )
# Strips out any .. and . from a path
sub StripPath
{
    local($dir, @bits, @fixedbits, $b);
    $dir = $_[0];
    $dir =~ s/^\/+//g;
    $dir =~ s/\/+$//g;
    @bits = split(/\/+/, $dir);    
    
	if( $#bits == 0)
	{
		$dir =~ s/^\\+//g;
		$dir =~ s/\\+$//g;
		@bits = split(/\\+/, $dir);
	}

    @fixedbits = ();
    foreach $b (@bits) {
        if ($b eq ".") {
	    	# Do nothing..
        }
        elsif ($b eq "..") {
        	if(scalar(@fixedbits) != 0) {
		    	pop(@fixedbits);
		    }
		}
        else {
	    	# Add dir to list
	    	push(@fixedbits, $b);
		}
    }
    return join('/', @fixedbits);
}

# CheckIfForbidden
# checks if filename belongs to the document root directory
sub CheckIfForbidden($accessdir, $filename)
{
    my $strippedFileName = StripPath($_[1]);
    my $filepath = $_[0] . "/" . $strippedFileName;
	
    if((-e $filepath) && (-r $filepath)) {
	return 0; # not forbidden because file exists!
    }
    else {
	return 1; # forbidden
    }
}

1; #return true    

