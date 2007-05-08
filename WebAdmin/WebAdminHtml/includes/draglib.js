var browserYOffset = 0;
var browserButtonYOffset = 0;

// calculate offsets

if (browserName.indexOf('MSIE 5.0; Mac') > 0) {
	browserYOffset = 18;
	browserButtonYOffset = 20;
}

function clearPreinsert() {
	var newArray = new Array();
	for (var i = 0; i < playlistFiles.length; i++) {
		if (playlistFiles[i] != "") {
			newArray[newArray.length] = playlistFiles[i];
		}
	}
	delete playlistFiles;
	playlistFiles = newArray;
}

function preInsert(thePos) {
	var newArray = new Array();
	for (var i = 0; i < playlistFiles.length; i++) {
		if (i == thePos) newArray[newArray.length] = "";
		if (playlistFiles[i] != "") {
			newArray[newArray.length] = playlistFiles[i];
		}
	}
	delete playlistFiles;
	playlistFiles = newArray;
}

function doInsert(theItem) {
	for (var i = 0; i < playlistFiles.length; i++) {
		if (playlistFiles[i] == "") {
			playlistFiles[i] = theItem;
		}
	}
}

function buildLibrary() {
	for (var i = scrollPos1; i <= GetMin(directoryListing.length - 1, scrollPos1+gNumLayersVisible-1); i++) {
		generateLayerText('library'+i, directoryListing[i]);
	}
}

function buildPlaylist() {
	for (var i = scrollPos2; i <= GetMin(playlistFiles.length - 1, scrollPos2+gNumLayersVisible-1); i++) {
		generateLayerText('playlist'+i, playlistFiles[i]);
	}
}

function buildLists() {
	buildLibrary();
	buildPlaylist();
}

function stageCall(s) {
	currentStepNumber++;
	if ((currentStepNumber == gNumberOfSteps) || ((GetStylePos(s, 0) == xFinalValue) && (GetStylePos(s, 1) == yFinalValue))) {
		SetStylePos(s, 0, xFinalValue);
		SetStylePos(s, 1, yFinalValue);
		SetStyleVisible("draglayer", false);
	}
	else {
		SetStylePos(s, 0, (GetStylePos(s, 0) - xStepValue));
		SetStylePos(s, 1, (GetStylePos(s, 1) - yStepValue));
		var currentTimer = setTimeout('stageCall("' + s + '")', gStepTiming);
	}
}

function moveInStages(s, xVal, yVal) {
	currentStepNumber = 0;
	xStepValue = ((GetStylePos(s, 0) - xVal) / gNumberOfSteps);
	yStepValue = ((GetStylePos(s, 1) - yVal) / gNumberOfSteps);
	xFinalValue = xVal;
	yFinalValue = yVal;
	var currentTimer = setTimeout('stageCall("' + s + '")', gStepTiming);
}

function handleMouseDown(e) {
	if (IsIE()) var theTarget = window.event.srcElement;    
	else var theTarget = e.target;
	if (IsIE()) var theButton = event.button;
	else var theButton = e.which;
	
	layerClicked = "";
	movingStatus = "";
		
	if (IsIE()) {
		oldX = window.event.clientX + document.body.scrollLeft + document.documentElement.scrollLeft;
		oldY = window.event.clientY + document.body.scrollTop + document.documentElement.scrollTop;
		offsetX = window.event.offsetX;
		offsetY = window.event.offsetY;
	}
	else {
		oldX = e.pageX
		oldY = e.pageY
	}
	
	for (var i=0; i<=(Math.min(gNumLayersVisible-1,directoryListing.length-1)); i++) {
		if ((oldX >= GetStylePos('library'+i, 0)) && (oldX <= (GetStylePos('library'+i, 0) + gLayerWidth)) && (oldY >= GetStylePos('library'+i, 1) + browserYOffset) && (oldY <= (GetStylePos('library'+i, 1) + gLayerHeight) + browserYOffset)) {
			SetStylePos("highlight", 0, GetStylePos('library'+i, 0));
			SetStylePos("highlight", 1, GetStylePos('library'+i, 1) + browserYOffset);
			SetStyleVisible("highlight", true);
			SetButtonsEnabled(true);
			SetStylePos('draglayer', 0, GetStylePos('library'+i, 0));
			SetStylePos('draglayer', 1, GetStylePos('library'+i, 1) + browserYOffset);
			itemDragged = i;
			generateLayerText('draglayer',directoryListing[i]);
			layerClicked = 'draglayer';
		}
	}
	
	if (layerClicked == "") {
		if (allowDeselect) {
			SetStyleVisible("highlight", false);
			SetButtonsEnabled(false);
		}
		return true;
	}
				
	if ((layerClicked != "") && (allowDrag)) {
		if (theButton == 1) {
			movingStatus = "drag";
			origX = GetStylePos(layerClicked, 0);
			origY = GetStylePos(layerClicked, 1);
		}

		if (!IsIE()) {
			document.captureEvents(Event.MOUSEMOVE);
		}
		document.onmousemove = handleDrag;
	}
	
	return false;
}

function handleMouseUp(e) {
	if (movingStatus == "drag") {
			movingStatus = "false";
			if (!IsIE()) document.releaseEvents(Event.MOUSEMOVE);
			
			if (GetStyleVisible("inserthere")) {
				SetStyleVisible(layerClicked, false);
				SetStyleVisible("inserthere", false);
				playlistFiles[playlistFiles.length] = directoryListing[itemDragged];
				// doInsert();
				buildLists();
			}
			else moveInStages(layerClicked, origX, origY);
	}
}

function handleDrag(e) {
	if (movingStatus == "drag") {
		SetStylePos(layerClicked, 0, window.event.clientX - offsetX);
		SetStylePos(layerClicked, 1, window.event.clientY - offsetY);
		var didHighlight = false;
		for (var i = 0; i <= (gNumLayersVisible-1); i++) {
			if ((window.event.clientX + document.body.scrollLeft + document.documentElement.scrollLeft >= GetStylePos('playlist'+i, 0)) && (window.event.clientX + document.body.scrollLeft + document.documentElement.scrollLeft <= (GetStylePos('playlist'+i, 0) + gLayerWidth)) && (window.event.clientY + document.body.scrollTop + document.documentElement.scrollTop >= GetStylePos('playlist'+i, 1)) && (window.event.clientY + document.body.scrollTop + document.documentElement.scrollTop <= (GetStylePos('playlist'+i, 1) + gLayerHeight))) {
				SetStylePos("inserthere", 0, GetStylePos('playlist'+i, 0));
				SetStylePos("inserthere", 1, GetStylePos('playlist'+GetMin(i,playlistFiles.length), 1));
				SetStyleVisible("inserthere", true);
				//preInsert(0);
				//buildPlaylist();
				didHighlight = true;					
			}
		}
		if ((!didHighlight) && (GetStyleVisible("inserthere"))) {
			SetStyleVisible("inserthere", false);
			//clearPreinsert();
			buildPlaylist();
		}
	}
	return false;
}

// re-route events to handlers

if (!IsIE()) document.captureEvents(Event.MOUSEUP|Event.MOUSEDOWN);

document.onmousedown = handleMouseDown;
document.onmouseup = handleMouseUp;
