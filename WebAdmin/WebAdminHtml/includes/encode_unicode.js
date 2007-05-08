entities = new Array();
chars = new Array();

entities[entities.length] = '&ocirc;';
chars[chars.length] = "ô";
entities[entities.length] = '&eacute;';
chars[chars.length] = "é";
entities[entities.length] = '&ecirc;';
chars[chars.length] = "ê";
entities[entities.length] = '&agrave;';
chars[chars.length] = "à";
entities[entities.length] = '&ocirc;';
chars[chars.length] = "ô";
entities[entities.length] = '&Ecirc;';
chars[chars.length] = "Ê";
entities[entities.length] = '&ucirc;';
chars[chars.length] = "û";
entities[entities.length] = '&uuml;';
chars[chars.length] = "ü";
entities[entities.length] = '&Auml;';
chars[chars.length] = "Ä";
entities[entities.length] = '&auml;';
chars[chars.length] = "ä";
entities[entities.length] = '&ouml;';
chars[chars.length] = "ö";
entities[entities.length] = '&szlig;';
chars[chars.length] = "ß";


function replaceEntities(theString) {
	for (var i = 0; i < chars.length; i++) {
		theString = eval('theString.replace(/' + entities[i] + '/g, chars[i])');
	}
	return theString
}

function entityAlert(theString) {
	theString = replaceEntities(theString);
	alert(theString);
}

function entityConfirm(theString) {
	theString = replaceEntities(theString);
	return confirm(theString)
}