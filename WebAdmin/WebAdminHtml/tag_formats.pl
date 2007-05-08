%defaultFormats = (
	"qtssSvrStartupTime" => "localtime",
	"qtssSvrCurrentTimeMilliseconds" => "localtime",
	"qtssServerAPIVersion" => "version",
	"qtssElapsedTime" => "time",
	"qtssSvrCPULoadPercent" => "float",
	"qtssRTPSvrCurBandwidth" => "bps",
	"qtssRTPSvrTotalBytes" => "bytes",
	"pageRefreshInterval" => "option",
	"displayCount" => "option",
	"qtssMaxThroughput" => "kbpsinput"
);

@weekdayStr = ( "SunStr", "MonStr", "TueStr", "WedStr", "ThuStr", "FriStr", "SatStr" );
@monthStr = ( "JanStr", "FebStr", "MarStr", "AprStr", "MayStr", "JunStr", "JulStr", "AugStr", "SepStr", "OctStr", "NovStr", "DecStr" );

# GetMessageHash()
# Returns the messages hash given the language
sub GetMessageHash 
{
	return $ENV{"QTSSADMINSERVER_EN_MESSAGEHASH"};  
}

sub runFormatter {
	my $theString = $_[0];
	my $theFormatter = $_[1];
	my $theUserParam = $_[2];
	my $theName = $_[3];
	my $messHash = GetMessageHash();
	my %messages = %$messHash;
	
	if ($theFormatter eq "localtime") {
		my $timeval = $theString;
		if(!defined($timeval)) {
			$_[0] .= "";
		}
		else {
			$_[0] = "";
			my @tm = localtime($timeval/1000);
			my $lang = $ENV{"LANGUAGE"};
			if($lang eq "de") {
				$_[0] .= sprintf "%s %d %s %d %2.2d:%2.2d:%2.2d",
						$messages{$weekdayStr[$tm[6]]}, $tm[3], $messages{$monthStr[$tm[4]]}, $tm[5]+1900,
						$tm[2], $tm[1], $tm[0];		
			}
			elsif($lang eq "ja") {
				$_[0] .= sprintf "%d %s %s %d %s %s, %2.2d:%2.2d:%2.2d",
						$tm[5]+1900, $messages{'YearSuffix'}, $messages{$monthStr[$tm[4]]}, $tm[3], $messages{'DaySuffix'}, $messages{$weekdayStr[$tm[6]]}, 
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
		return $_[0];
	}
	elsif ($theFormatter eq "version") {
		return adminprotolib::ConvertToVersionString($theString);
	}
	elsif ($theFormatter eq "serverstatus") {
		return adminprotolib::GetServerStateString($theString, $messHash)
	}
	elsif ($theFormatter eq "startstopbutton") {
		if ($theString <= 1) {
			return $messages{'StopServerButton'};
		}
		else {
			return $messages{'StartServerButton'};
		}
	}
	elsif ($theFormatter eq "plaintext") {
		return $theString;
	}
	elsif ($theFormatter eq "time") {
		return adminprotolib::ConvertTimeToStr($theString, $messHash);
	}
	elsif ($theFormatter eq "float") {
		return sprintf "%3.2f", $theString;
	}
	elsif ($theFormatter eq "bps") {
		if ($theString < 1024) {
			$theString .= " " . $messages{'BitsPerSecStr'};
			return $theString;
		}
		else {
			return sprintf("%3.3f", $theString/1024) . $messages{'KilobitsPerSecStr'};
		}
	}
	elsif ($theFormatter eq "kbpsinput") {
		if ($theString < 1024) {
			$theString = '<input type=text name=bpsinput value="'.$theString.'" size=6 maxlength=4 onchange="validateFormData()"><input type=hidden name=bpsinput_shadow value="'.$theString.'">';
			$theString .= '<select name=kbpstype>';
			$theString .= '<option value=kbps selected>' . $messages{'KilobitsPerSecStr'} . '</option>';
			$theString .= '<option value=mbps>' . $messages{'MegabitsPerSecStr'} . '</option>';
			$theString .= '</select><input type=hidden name=kbpstype_shadow value=kbps>';
			return $theString;
		}
		else {
			$theString = '<input type=text name=bpsinput value="'.($theString/1024).'" size=6 maxlength=4 onchange="validateFormData()"><input type=hidden name=bpsinput_shadow value="'.sprintf("%3.1f", $theString/1024).'">';
			$theString .= '<select name=kbpstype>';
			$theString .= '<option value=kbps>' . $messages{'KilobitsPerSecStr'} . '</option>';
			$theString .= '<option value=mbps selected>' . $messages{'MegabitsPerSecStr'} . '</option>';
			$theString .= '</select><input type=hidden name=kbpstype_shadow value=kbps>';
			return $theString;
		}
	}
	elsif ($theFormatter eq "bytes") {
	    if(defined($theString)) {
			if($theString < 1024) {         
				return "$theString " . $messages{'BytesStr'};
			}
			elsif($theString < (1024 * 1024)) {
				$theString /= 1024;
				return sprintf("%3.3f", $theString) . " " . $messages{'KiloBytesStr'};
			}
			elsif($theString < (1024 * 1024 * 1024)) {
				$theString /= (1024 * 1024);
				return sprintf("%3.3f", $theString) . " " . $messages{'MegaBytesStr'};
			}
			else {
				$theString /= (1024 * 1024 * 1024);
				return sprintf("%3.3f", $theString) . " " . $messages{'GigaBytesStr'};
			}
	    }
	    else {
			return "";
	    }
	}
	elsif ($theFormatter eq 'div1024') {
		if ($theString > 0) {
			$theString /= 1024;
		}
		return $theString;
	}
	elsif ($theFormatter eq 'option') {
		if ($theString eq $theUserParam) {
			return ' selected';
		}
		else {
			return '';
		}
	}
	elsif ($theFormatter eq 'radio') {
		if ($theString eq $theUserParam) {
			$theString = '<input type=hidden name="'.$theName.'_shadow" value="'.$theString.'">';
			$theString .= "<input type=radio name=\"$theName\" value=\"$theUserParam\" checked>";
		}
		else {
			$theString = "<input type=radio name=\"$theName\" value=\"$theUserParam\">";
		}
		return $theString;
	}
	elsif ($theFormatter eq 'checkbox') {
		if ($theString eq $theUserParam) {
			$theString = '<input type=hidden name="'.$theName.'_shadow" value="'.$theString.'">';
			$theString .= "<input type=checkbox name=\"$theName\" value=\"$theUserParam\" checked>";
		}
		else {
			$theString = "<input type=checkbox name=\"$theName\" value=\"$theUserParam\">";
		}
		return $theString;
	}
	elsif ($theFormatter eq 'connusercolumnheader') {
		my $newString = '';
		if ($theString =~ /^$theUserParam/) {
			$newString = '<td nowrap bgcolor="#A0A0AF" align=center class=columnheader>';
			$newString .= $messages{$theUserParam};
			if ($theString =~ /_ascending/) {
				$theString =~ s/_ascending/_descending/;
				$newString .= '<a href="/parse_xml.cgi?action=setconnusersort&filename=connected.html&connUserSort='.$theString.'">';
				$newString .= '<img src="images/sort_arrow.gif" width=8 height=8 border=0 align=bottom>';
				$newString .= '</a>';
			}
			elsif ($theString =~ /_descending/) {
				$theString =~ s/_descending/_ascending/;
				$newString .= '<a href="/parse_xml.cgi?action=setconnusersort&filename=connected.html&connUserSort='.$theString.'">';
				$newString .= '<img src="images/sort_arrow_desc.gif" width=8 height=8 border=0 align=bottom>';
				$newString .= '</a>';
			}
			$newString .= '</td>';
		}
		else {
			$newString = '<td nowrap bgcolor="#C6C6D6" align=center class=columnheader>';
			$theString =~ s/$theString/$theUserParam/;
			$theString .= '_ascending';
			$newString .= '<a href="/parse_xml.cgi?action=setconnusersort&filename=connected.html&connUserSort='.$theString.'">';
			$newString .= $messages{$theUserParam};
			$newString .= '</a>';
			$newString .= '</td>';
		}
		return $newString;
	}
	elsif ($theFormatter eq 'relaystatcolumnheader') {
		my $newString = '';
		if ($theString =~ /^$theUserParam/) {
			$newString = '<td nowrap bgcolor="#A0A0AF" align=center class=columnheader>';
			$newString .= $messages{$theUserParam};
			if ($theString =~ /_ascending/) {
				$theString =~ s/_ascending/_descending/;
				$newString .= '<a href="/parse_xml.cgi?action=setrelaystatsort&filename=relay_status.html&relayStatSort='.$theString.'">';
				$newString .= '<img src="images/sort_arrow.gif" width=8 height=8 border=0 align=bottom>';
				$newString .= '</a>';
			}
			elsif ($theString =~ /_descending/) {
				$theString =~ s/_descending/_ascending/;
				$newString .= '<a href="/parse_xml.cgi?action=setrelaystatsort&filename=relay_status.html&relayStatSort='.$theString.'">';
				$newString .= '<img src="images/sort_arrow_desc.gif" width=8 height=8 border=0 align=bottom>';
				$newString .= '</a>';
			}
			$newString .= '</td>';
		}
		else {
			$newString = '<td nowrap bgcolor="#C6C6D6" align=center class=columnheader>';
			$theString =~ s/$theString/$theUserParam/;
			$theString .= '_ascending';
			$newString .= '<a href="/parse_xml.cgi?action=setrelaystatsort&filename=relay_status.html&relayStatSort='.$theString.'">';
			$newString .= $messages{$theUserParam};
			$newString .= '</a>';
			$newString .= '</td>';
		}
		return $newString;
	}
	elsif ($theFormatter eq 'sortedtablecell') {
		if ($theString =~ /^$theUserParam/) {
			return '<td nowrap bgcolor="#D6D6E5" align=center class=small>';
		}
		else {
			return '<td nowrap align=center class=small>';
		}
	}
	elsif ($theFormatter eq 'nosinglequotes') {
		$theString =~ s/'/' \+ "'" \+ '/go;
		$theString =~ s/\\/\\\\/go;
		return $theString;
	}
	elsif ($theFormatter eq 'unicode-convert') {
		if ($ENV{"LANGUAGE"} eq "ja") {
			require 'MapUTF.pl';
			return &ShiftJIS::CP932::MapUTF::utf8_to_cp932($theString);
		}
		else {
			return $theString;
		}
	}
	elsif ($theFormatter eq 'urlencode') {
		return urlEncode($theString);
	}
	
	# formatter not found; return string
	return $theString
}

sub urlEncode {
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

# solaris expects a return value
1;
