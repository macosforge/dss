#!/usr/bin/perl

package broadcasterlib;
use Foundation;

# ServerExists()
# Returns 1 if the app is installed, 0 if it's not.
sub ServerExists
{
	my $loc = NSString->stringWithCString_("/Applications/QuickTime Broadcaster.app");
	if (NSFileManager->defaultManager->fileExistsAtPath_($loc)) {
		return 1;
	}
	return 0;
}


# GetServerUsername()
# Returns the username under which QTBroadcaster is running,
# or an empty string if QTBroadcaster isn't active.
sub GetServerUsername
{
	my $ps = `/bin/ps -auwx`;
	my @splitps = split(/\n/, $ps);
	my $username = '';
	
	for ($i = 0; $i < scalar(@splitps); $i++) {
		my $current = $splitps[$i];
		if ($current =~ /QuickTime Broadcaster/) {
			$current =~ /^([^\s]+)/;
			$username = $1;
		}
	}
	
	return $username;
}

# CountServers
# Returns a count of other broadcasters.
sub CountServers
{
	my $ps = `/bin/ps -auwx`;
	my @splitps = split(/\n/, $ps);
	my $pid = (-1);
	my $count = 0;
	
	for ($i = 0; $i < scalar(@splitps); $i++) {
		my $current = $splitps[$i];
		my @splitcurrent = split(/\s+/, $current);
		if ($current =~ /QuickTime Broadcaster/) {
			$count = $count + 1;
		}
	}
	return $count;
}

# KillServer(signal)
# Finds the pid for the broadcaster and kills it.
sub KillServer
{
	my $signal = $_[0];
	my $ps = `/bin/ps -auwx`;
	my @splitps = split(/\n/, $ps);
	my $pid = (-1);
	
	for ($i = 0; $i < scalar(@splitps); $i++) {
		my $current = $splitps[$i];
		my @splitcurrent = split(/\s+/, $current);
		if ($current =~ /QuickTime Broadcaster/) {
			$pid = $splitcurrent[1];
			kill $signal, $pid;
		}
	}
}

# GetPrefDictionaryLoc()
# Returns the location of the current pref dictionary.
sub GetPrefDictionaryLoc
{
	$username = GetServerUsername();
	$locstr = "~$username/Library/Preferences/com.apple.QuickTime Broadcaster.plist";
	$loc = NSString->stringWithCString_($locstr);
	$loc = $loc->stringByExpandingTildeInPath;
	return $loc->cString;
}

# GetPrefDictionary()
# Returns the pref dictionary for the currently running broadcaster user
# in NSDictionary format
sub GetPrefDictionary
{
	my $locstr = GetPrefDictionaryLoc();
	my $loc = NSString->stringWithCString_($locstr);
	return NSDictionary->dictionaryWithContentsOfFile_($loc);
}

# GetPresetDictionaryLoc(presetName, presetType)
# Returns the location of the selected preset name
sub GetPresetDictionaryLoc
{
	my $presetName = $_[0];
	my $presetType = $_[1];
	
	if ($presetType == 0) {
		$presetDir = "Audio";
	}
	elsif ($presetType == 1) {
		$presetDir = "Video";
	}
	else {
		$presetDir = "Network";
	}
	
	my $username = GetServerUsername();
	my $locstr = "~$username/Library/QuickTime Broadcaster Presets/$presetDir/$presetName.xml";
	my $loc = NSString->stringWithCString_($locstr);
	return $loc->stringByExpandingTildeInPath->cString;
}

# GetPresetDictionary(presetName, presetType)
# Returns the root dictionary for the given preset.
sub GetPresetDictionary
{
	my $presetName = $_[0];
	my $presetType = $_[1];
	
	my $loc = GetPresetDictionaryLoc($presetName, 2);
	return NSDictionary->dictionaryWithContentsOfFile_(NSString->stringWithCString_($loc));
}

# GetPresetSettingsDictionary(presetName, presetType)
# Returns an NSDictionary with the settings from the given preset name and type.
sub GetPresetSettingsDictionary
{
	my $presetName = $_[0];
	my $presetType = $_[1];
	
	my $dict = GetPresetDictionary($presetName, 2);
	$dict = $dict->objectForKey_(NSString->stringWithCString_("settings"));
	return $dict;
}

# GetSettingsFileNetworkDictionary
# Returns an NSDictionary with the network settings for the QTSS settings file.
sub GetSettingsFileNetworkDictionary
{
	my $fileLoc = NSString->stringWithCString_("/Library/QuickTimeStreaming/Config/BroadcasterSettings.qtbr");
	my $rootDict = NSDictionary->dictionaryWithContentsOfFile_($fileLoc);
	return $rootDict->objectForKey_(NSString->stringWithCString_("network"));
}

# GetDefaultDict()
# Returns the default dictionary for the settings file.
sub GetDefaultDict
{
	my $fileLoc = NSString->stringWithCString_("/Library/QuickTimeStreaming/Config/BroadcasterSettings.qtbr");
	my $rootDict = NSMutableDictionary->dictionary;
	my $settingsDict = NSMutableDictionary->dictionary;
	
	$rootDict->setObject_forKey_(NSNumber->numberWithInt_(1), NSString->stringWithCString_("version"));
	my $settingsDict = NSMutableDictionary->dictionary;
	$settingsDict->setObject_forKey_(NSString->stringWithCString_(""), NSString->stringWithCString_("author"));
	$settingsDict->setObject_forKey_(NSString->stringWithCString_("0"), NSString->stringWithCString_("bufferDelay"));
	$settingsDict->setObject_forKey_(NSString->stringWithCString_(""), NSString->stringWithCString_("copyright"));
	$settingsDict->setObject_forKey_(NSString->stringWithCString_("mystream"), NSString->stringWithCString_("fileName"));
	$settingsDict->setObject_forKey_(NSString->stringWithCString_("127.0.0.1"), NSString->stringWithCString_("hostName"));
	$settingsDict->setObject_forKey_(NSString->stringWithCString_(""), NSString->stringWithCString_("info"));
	$settingsDict->setObject_forKey_(NSNumber->numberWithBool_(0), NSString->stringWithCString_("overTCP"));
	$settingsDict->setObject_forKey_(NSString->stringWithCString_(""), NSString->stringWithCString_("password"));
	$settingsDict->setObject_forKey_(NSString->stringWithCString_(""), NSString->stringWithCString_("title"));
	$settingsDict->setObject_forKey_(NSString->stringWithCString_("unicastAnnounce"), NSString->stringWithCString_("transmissionType"));
	$settingsDict->setObject_forKey_(NSString->stringWithCString_(""), NSString->stringWithCString_("userName"));
	$settingsDict->setObject_forKey_(NSNumber->numberWithInt_(1), NSString->stringWithCString_("version"));
	$rootDict->setObject_forKey_($settingsDict, NSString->stringWithCString_("network"));
	
	return $rootDict;
}

# CheckForStreamingServerSettingsFile()
# Creates a streaming server settings file if necessary.
sub CheckForStreamingServerSettingsFile
{
	my $fileLoc = NSString->stringWithCString_("/Library/QuickTimeStreaming/Config/BroadcasterSettings.qtbr");
	
	if (!NSFileManager->defaultManager->fileExistsAtPath_($fileLoc)) {
		if (-e '/Library/QuickTimeStreaming/Config/Broadcaster Presets/current.plist') {
			unlink '/Library/QuickTimeStreaming/Config/Broadcaster Presets/current.plist';
		}
		my $rootDict = GetDefaultDict();
		$rootDict->writeToFile_atomically_($fileLoc, 1);
	}
	
	# check for the broadcaster settings dir
	if (!(-e '/Library/QuickTimeStreaming/Config/Broadcaster Presets')) {
		mkdir '/Library/QuickTimeStreaming/Config/Broadcaster Presets';
		chmod 0775, '/Library/QuickTimeStreaming/Config/Broadcaster Presets';
	}
}

# RereadSettingsFile(connection)
# Sent after we start the server.
sub RereadSettingsFile
{
	my $server = $_[0];
	my $fileLoc = NSString->stringWithCString_("/Library/QuickTimeStreaming/Config/BroadcasterSettings.qtbr");
	my $tmpFolder = "/tmp/qtss-qtbroadcaster-tmp";
	my $tmpFolderLoc = NSString->stringWithCString_($tmpFolder);
	my $otherFileLoc = NSString->stringWithCString_("/tmp/qtss-qtbroadcaster-tmp/qtss-qtbroadcaster-settings-tmp.qtbr");
	my $audioEnabled = GetStreamEnabledForType($server, 0);
	my $videoEnabled = GetStreamEnabledForType($server, 1);
	my $recordingEnabled = IsRecording($server);
	my $rootDict = GetDefaultDict();
	
	if (!(-e $tmpFolder)) {
		mkdir $tmpFolder, 0700;
	}
	
	$rootDict->writeToFile_atomically_($otherFileLoc, 1);
		
	$server->setBroadcastSettingsFile_($otherFileLoc);
	$server->setBroadcastSettingsFile_($fileLoc);
	SetStreamEnabledForType($server, 0, $audioEnabled);
	SetStreamEnabledForType($server, 1, $videoEnabled);
	SetRecording($server, $recordingEnabled);
	
	unlink "/tmp/qtss-qtbroadcaster-tmp/qtss-qtbroadcaster-settings-tmp.qtbr";
	rmdir $tmpFolder;
}

# GetServerConnection(autostart)
# Returns a connection to the server.
sub GetServerConnection
{
	my $autostart = $_[0];
	my $serverName = NSString->stringWithCString_("QuickTimeBroadcasterRemoteAdmin");
	my $server = NSConnection->rootProxyForConnectionWithRegisteredName_host_($serverName, 0);
	if ((!$server || !$$server) && (GetServerUsername() eq '') && ($autostart == 1)) {
		CheckForStreamingServerSettingsFile();
		exec "/Applications/QuickTime Broadcaster.app/Contents/MacOS/QuickTime Broadcaster", "-noui";
	}
	if (!(!$server || !$$server)) {
		$server->retain();
	}
	return $server;
}

# CurrentState(connection, messageHash)
# Returns a string with the current server state.
sub CurrentState
{
	my $server = $_[0];
	my $messageHashRef = $_[1];
	my %messageHash = %$messageHashRef;
	my $state = $server->state;
	if ($state == 0) {
		return $messageHash{'QTBStateSetup'};
	}
	elsif ($state == 1) {
		return $messageHash{'QTBStateStartingBroadcast'};
	}
	elsif ($state == 2) {
		return $messageHash{'QTBStatePrerolling'};
	}
	elsif ($state == 3) {
		return $messageHash{'QTBStateBroadcasting'};
	}
	elsif ($state == 4) {
		return $messageHash{'QTBStateStoppingBroadcast'};
	}
	# this should never happen
	return 'Unknown';
}

# StartStopButtonText(connection, messageHash)
# Returns a string for the start/stop button.
sub StartStopButtonText
{
	my $server = $_[0];
	my $messageHashRef = $_[1];
	my %messageHash = %$messageHashRef;
	
	if ($server->state == 0) {
		return $messageHash{'QTBStartButton'};
	}
	return $messageHash{'QTBStopButton'};
}

# GetBroadcasterStateID(connection)
# Returns the state integer.
sub GetBroadcasterStateID
{
	my $server = $_[0];
	return $server->state;
}

# IsRecording(connection)
# Returns 0 or 1 to denote whether the given server is set to record.
sub IsRecording
{
	my $server = $_[0];
	if ($server->recording()) {
		return 1;
	}
	else {
		return 0;
	}
}

# SetRecording(connection, record)
# Set to 1 to record, or 0 to not record.
sub SetRecording
{
	my $server = $_[0];
	my $record = $_[1];
	$server->setRecording_($record);
}

# GetRecordingPath(connection)
# Gets the recording path for the given server.
sub GetRecordingPath
{
	my $server = $_[0];
	return $server->recordingPath->cString;
}

# SetRecordingPath(connection, path)
# Sets the recording path.
sub SetRecordingPath
{
	my $server = $_[0];
	my $path = $_[1];
	$server->setRecordingPath_(NSString->stringWithCString_($path));
}

# GetStreamEnabledForType(connection, type)
# Returns 1 if enabled, 0 if not.
sub GetStreamEnabledForType
{
	my $server = $_[0];
	my $type = $_[1];
	
	if ($type == 0) {
		$typeStr = NSString->stringWithCString_("audio");
	}
	else {
		$typeStr = NSString->stringWithCString_("video");
	}
	
	my $enabled = $server->streamEnabled_($typeStr);
		
	return "$enabled";
}

# SetStreamEnabledForType(connection, type, enabled)
# Set to 0 to disable, 1 to enable
sub SetStreamEnabledForType
{
	my $server = $_[0];
	my $type = $_[1];
	my $enabled = $_[2];
	
	if ($type == 0) {
		$typeStr = NSString->stringWithCString_("audio");
	}
	else {
		$typeStr = NSString->stringWithCString_("video");
	}

	$server->setStreamEnabled_ofType_(($enabled == 1), $typeStr);
}

# GetPresetsForType(connection, type)
# Returns an array ref of preset names.
# Pass it 0 for audio, 1 for audio, and 2 for network.
sub GetPresetsForType
{
	my $server = $_[0];
	my $type = $_[1];
	@presets = ('');
	my $i;
	my $currentPreset;
	my $sharedPresetsFolder = '/Library/QuickTimeStreaming/Config/Broadcaster Presets';
	my $presetFolderLoc;
	
	if ($type == 0) {
		$presetFolderLoc = NSString->stringWithCString_("$sharedPresetsFolder/Audio");
	}
	elsif ($type == 1) {
		$presetFolderLoc = NSString->stringWithCString_("$sharedPresetsFolder/Video");
	}
	elsif ($type == 2) {
		$presetFolderLoc = NSString->stringWithCString_("$sharedPresetsFolder/Network");
	}
	
	if (-e $presetFolderLoc->cString) {
		my $folderContents = NSFileManager->defaultManager->directoryContentsAtPath_($presetFolderLoc);
		if (!(!$folderContents || !$$folderContents)) {
			for ($i = 0; $i < $folderContents->count; $i++) {
				$currentPreset = $folderContents->objectAtIndex_($i);
				push(@presets, $currentPreset->stringByDeletingPathExtension->cString);
			}
		}
	}
	
	my $presetsArrayObj = $server->presetNameList_($type);
		
	for ($i = 0; $i < $presetsArrayObj->count; $i++) {
		$currentPreset = $presetsArrayObj->objectAtIndex_($i);
		if ((!$folderContents || !$$folderContents) || (!$folderContents->containsObject_($currentPreset))) {
			push(@presets, $currentPreset->cString);
		}
	}
			
	return \@presets;
}

# GetStringForType(type)
# Gets the preference dictionary name for a preset type.
sub GetStringForType
{
	my $type = $_[0];
	
	if ($type == 0) {
		return "audio";
	}
	elsif ($type == 1) {
		return "video";
	}
	return "network";
}

# GetCurrentPresetForType(connection, type)
# Gets the current preset name.
sub GetCurrentPresetForType
{
	my $connection = $_[0];
	my $type = $_[1];
	my $locObj = NSString->stringWithCString_("/Library/QuickTimeStreaming/Config/Broadcaster Presets/current.plist");
	my $valueAsObj;

	if (NSFileManager->defaultManager->fileExistsAtPath_($locObj)) {
		my $dict = NSDictionary->dictionaryWithContentsOfFile_($locObj);
		if (!$dict or !$$dict) {
			return '';
		}
		$valueAsObj = $dict->objectForKey_(NSString->stringWithString_(GetStringForType($type)));
		if (!(!$valueAsObj or !$$valueAsObj)) {
			return $valueAsObj->cString;
		}
	}
	$valueAsObj = $connection->currentPresetName_($type);
	if (!$valueAsObj or !$$valueAsObj) {
		return '';
	}
	return $valueAsObj->cString;
}

# SetCurrentPresetForType(connection, type, value)
# Sets the preset to the selected one.
sub SetCurrentPresetForType
{
	my $connection = $_[0];
	my $type = $_[1];
	my $value = $_[2];
	my $valueStr = NSString->stringWithCString_($value);
	my $sharedPresetsFolder = '/Library/QuickTimeStreaming/Config/Broadcaster Presets';

	if ($type == 0) {
		$presetFolderLoc = NSString->stringWithCString_("$sharedPresetsFolder/Audio");
	}
	elsif ($type == 1) {
		$presetFolderLoc = NSString->stringWithCString_("$sharedPresetsFolder/Video");
	}
	elsif ($type == 2) {
		$presetFolderLoc = NSString->stringWithCString_("$sharedPresetsFolder/Network");
	}
	
	my $locObj = $presetFolderLoc->stringByAppendingPathComponent_($valueStr);
	my $locObj = $locObj->stringByAppendingPathExtension_(NSString->stringWithCString_("xml"));
	my $saveLocObj = NSString->stringWithCString_("/Library/QuickTimeStreaming/Config/BroadcasterSettings.qtbr");
	my $mutableDict = NSMutableDictionary->dictionaryWithContentsOfFile_($saveLocObj);
		
	if (NSFileManager->defaultManager->fileExistsAtPath_($locObj)) {
		my $dict = NSDictionary->dictionaryWithContentsOfFile_($locObj);
		$dict = $dict->objectForKey_(NSString->stringWithCString_("settings"));
		
		# turn audio preview off, if applicable
		if ($type == 0) {
			my $mutableAudioSettingsDict = NSMutableDictionary->dictionaryWithDictionary_($dict);
			my $sourceSettingsDict = $mutableAudioSettingsDict->objectForKey_(NSString->stringWithCString_("source"));
			if (!(!$sourceSettingsDict || !$$sourceSettingsDict)) {
				my $mutableSourceSettingsDict = NSMutableDictionary->dictionaryWithDictionary_($sourceSettingsDict);
				$mutableSourceSettingsDict->setObject_forKey_(NSNumber->numberWithBool_(0), NSString->stringWithCString_("preview"));
				$sourceSettingsDict = NSDictionary->dictionaryWithDictionary_($mutableSourceSettingsDict);
				$mutableAudioSettingsDict->setObject_forKey_($sourceSettingsDict, NSString->stringWithCString_("source"));
				$dict = NSDictionary->dictionaryWithDictionary_($mutableAudioSettingsDict);
			}
		}
		
		my $typestr = GetStringForType($type);
		my $typeobj = NSString->stringWithCString_($typestr);
		$mutableDict->setObject_forKey_($dict, $typeobj);
		$connection->setCurrentPresetName_ofType_($valueStr, $type);
	}
	else {
		$connection->setCurrentPresetName_ofType_($valueStr, $type);
		$mutableDict->removeObjectForKey_(NSString->stringWithCString_(GetStringForType($type)));
	}
	
	$mutableDict->writeToFile_atomically_($saveLocObj, 1);
	
	my $statusLocObj = NSString->stringWithCString_("/Library/QuickTimeStreaming/Config/Broadcaster Presets/current.plist");
	my $statusDict = NSMutableDictionary->dictionaryWithContentsOfFile_($statusLocObj);
	if (!$statusDict or !$$statusDict) {
		$statusDict = NSMutableDictionary->dictionary;
	}
	$statusDict->setObject_forKey_(NSString->stringWithCString_($value), NSString->stringWithCString_(GetStringForType($type)));
	$statusDict->writeToFile_atomically_($statusLocObj, 1);
}

# SetNetworkSetting(settingName, valueObj)
sub SetNetworkSetting
{
	my $settingName = $_[0];
	my $valueObj = $_[1];
	my $settingNameObj = NSString->stringWithCString_($settingName);
	my $locObj = NSString->stringWithCString_("/Library/QuickTimeStreaming/Config/BroadcasterSettings.qtbr");
	my $mutableDict = NSMutableDictionary->dictionaryWithContentsOfFile_($locObj);
	my $settingsDict = $mutableDict->objectForKey_(NSString->stringWithCString_("network"));
	my $mutableSettingsDict = NSMutableDictionary->dictionaryWithDictionary_($settingsDict);
	
	$mutableSettingsDict->setObject_forKey_($valueObj, $settingNameObj);
	$mutableDict->setObject_forKey_($mutableSettingsDict, NSString->stringWithCString_("network"));
	$mutableDict->writeToFile_atomically_($locObj, 1);
}

# IsExternalHost()
# Returns 0 if localhost, 1 if not.
sub IsExternalHost
{
	my $hostName = GetNetworkHostname();
	if ($hostName eq '') {
		return 0;
	}
	return 1;
}

# GetNetworkHostname()
# Returns the hostname from the "QuickTime Streaming Server" network preset.
sub GetNetworkHostname
{
	my $dict = GetSettingsFileNetworkDictionary();
	my $hostName = $dict->objectForKey_(NSString->stringWithCString_("hostName"));
	if ($hostName->isEqualToString_(NSString->stringWithCString_("127.0.0.1"))) {
		return '';
	}
	return $hostName->cString;
}

# SetNetworkHostname(hostName)
# Sets the hostname for the "QuickTime Streaming Server" network preset to the given hostname.
sub SetNetworkHostname
{
	my $hostName = $_[0];
	SetNetworkSetting("hostName", NSString->stringWithCString_($hostName));
}

# GetNetworkFilepath()
# Returns the SDP filepath. This differs from the other method in that it
# only searches the "QuickTime Streaming Server" preset.
sub GetNetworkFilepath
{
	my $dict = GetSettingsFileNetworkDictionary();
	my $fileName = $dict->objectForKey_(NSString->stringWithCString_("fileName"));
	return $fileName->cString . ".sdp";
}

# SetNetworkFilepath(fileName)
# Sets the filepath for the "QuickTime Streaming Server" network preset to the given filepath.
sub SetNetworkFilepath
{
	my $fileName = $_[0];
	$fileName =~ s/.sdp$//;
	SetNetworkSetting("fileName", NSString->stringWithCString_($fileName));
}

# GetBufferDelay()
# Returns the buffer delay.
sub GetBufferDelay
{
	my $dict = GetSettingsFileNetworkDictionary();
	my $bufferDelay = $dict->objectForKey_(NSString->stringWithCString_("bufferDelay"));
	return $bufferDelay->cString;
}

# SetBufferDelay(delay)
# Sets the buffer delay.
sub SetBufferDelay
{
	my $delay = $_[0];
	SetNetworkSetting("bufferDelay", NSString->stringWithCString_($delay));
}

# GetNetworkUsername()
# Returns the username for the current broadcast.
sub GetNetworkUsername
{
	my $dict = GetSettingsFileNetworkDictionary();
	my $username = $dict->objectForKey_(NSString->stringWithCString_("userName"));
	return $username->cString;
}

# SetNetworkUsername(username)
# Sets the username for the current broadcast.
sub SetNetworkUsername
{
	$username = $_[0];
	SetNetworkSetting("userName", NSString->stringWithCString_($username));
}

# GetNetworkPassword()
# Returns the Password for the current broadcast.
sub GetNetworkPassword
{
	my $dict = GetSettingsFileNetworkDictionary();
	my $password = $dict->objectForKey_(NSString->stringWithCString_("password"));
	return $password->cString;
}

# SetNetworkPassword(password)
# Sets the password for the current broadcast.
sub SetNetworkPassword
{
	$password = $_[0];
	SetNetworkSetting("password", NSString->stringWithCString_($password));
}

# GetBroadcastNetworkType()
# Returns 0 for UDP and 1 for TCP.
sub GetBroadcastNetworkType
{
	my $dict = GetSettingsFileNetworkDictionary();
	if ($dict->objectForKey_(NSString->stringWithCString_("overTCP"))->boolValue == 0) {
		return 0;
	}
	if (GetNetworkHostname() eq '') {
		return 0;
	}
	return 1;
}

# SetBroadcastNetworkType(type)
# Use 0 for UDP and 1 for TCP.
sub SetBroadcastNetworkType
{
	my $type = $_[0];
	SetNetworkSetting("overTCP", NSNumber->numberWithBool_($type));
}

# WriteRefMovie(defaultDNSName)
# Writes out the ref movie for the broadcast.
sub WriteRefMovie
{
	my $defaultDNSName = $_[0];
	my $serverRoot = NSString->stringWithUTF8String_($ENV{"SERVER_ROOT"});
	my $refMovieFilename = NSString->stringWithUTF8String_("view_broadcast.mov");
	
	$refMovieFilename = $serverRoot->stringByAppendingPathComponent_($refMovieFilename);
	
	my $networkFilepath = GetNetworkFilepath();
	my $refMovieText = NSString->stringWithUTF8String_("rtsptext\rrtsp://$defaultDNSName/$networkFilepath");
	
	$refMovieText->writeToFile_atomically_($refMovieFilename, 1);
}

# StartStopBroadcast(connection)
# Toggles the broadcast state, and returns a message.
sub StartStopBroadcast
{
	my $server = $_[0];
	
	if ($server->state != 3) {
		# check to see if either audio or video stream is enabled
		if ((GetStreamEnabledForType($server, 0) != 1) && (GetStreamEnabledForType($server, 1) != 1)) {
			return '';
		}
		$server->startBroadcast;
		return 'QTBConfStarted';
	}
	else {
		$server->stopBroadcast;
		return 'QTBConfStopped';
	}
}

# StopBroadcast(connection)
# Stops the broadcast.
sub StopBroadcast
{
	my $server = $_[0];
	$server->stopBroadcast;
}

# QuitBroadcaster(connection)
# Tells the broadcaster to quit. Necessary to re-read prefs files.
sub QuitBroadcaster
{
	my $server = $_[0];
	
	$server->quit;
}

1;