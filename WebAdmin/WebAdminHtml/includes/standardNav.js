isMoving = false
// browserName = "OmniWeb/4";
// try {
//	tempVal = window.location.href.indexOf('lucy');
browserName = window.navigator.userAgent
// }
// catch(theErr) {
//	browserName = "OmniWeb/4";
// }
browserVersion = parseInt(browserName.charAt(browserName.indexOf("/")+1),10)
gMakeVisibleAfter = ""
gIsVisible = false
prevVisible = ""
openDrawer = ""
mainNav = new Array("hrweblogo","benefits","money","staffing","training","records","policies","manager","appledir","searchbox"); // jaa
defaultPos = new Array(0,93,114,135,156,185,206,228,306,344); // jaa
baseLoc = "/areas/hrweb/employee/"
maxY = 490
menuBGColor = "#336633"
menuLineColor = "#669966"

// standard subroutines

function popUp(URL,w,h,s) {
	eval("window.open(URL, 'AppleHelp', 'width="+w+",height="+h+",scrollbars="+s+"');");
}


function browserAlert() {
	if (browserVersion < 4) alert("This web site only works with Netscape and Internet Explorer version 4.0 or higher.")
}


function FindStyleInArray(theStyle) {
	for (var i = 0; i < (mainNav.length); i++) if (mainNav[i] == theStyle) return i
	
	return (-1)
}


function closeAllDrawers() {
	ridLayers(1)
	for (var i = 0; i < (mainNav.length); i++) SetStylePos(mainNav[i], 1, defaultPos[i])
}


function IsIE() {
	return browserName.indexOf("MSIE") > 0
}


function IsNS6() {
	return ((browserName.indexOf("Netscape6") > 0) || 
		(browserName.indexOf("Gecko") > 0));
}


function IsWin32() {
	return browserName.indexOf("Win") > 0
}


function GetIEStyle(s) {
//	return document.all.tags("div") [s].style
	return document.all[s].style
}


function GetNSStyle(s) {
	if (IsNS6()) return document.getElementById(s).style
	else return document.layers[s]
}


function GetIEScrollPos(d) {

	if ((document.documentElement) && (document.documentElement.scrollTop)) {
		if (d == 0) 
			return document.body.scrollLeft + document.documentElement.scrollLeft;
		else
			return document.body.scrollTop + document.documentElement.scrollTop;
	}

	else {
		if (d == 0)
			return document.body.scrollLeft;
		else
			return document.body.scrollTop;

	}
}


function GetStyle(s) {
	if (IsIE()) return GetIEStyle(s)
	else return GetNSStyle(s)
}

		
function GetMin(x, y) {
	return Math.min(x, y)
}


function GetMax(x, y) {
	return Math.max(x, y)
}


function SetStylePos(s, d, p) {
	if (IsIE()) {
		if (d == 0) GetIEStyle(s).posLeft = p
		else GetIEStyle(s).posTop = p
	}
	else {
		if (d == 0) return GetNSStyle(s).left = p
		else GetNSStyle(s).top = p
	}
	return true
}


function GetStyleVisible(s) {
	if (IsIE()) return (GetIEStyle(s).visibility == "visible")
	else {
		if (IsNS6()) return (document.getElementById(s).style.visibility == "visible")
		else return (GetNSStyle(s).visibility == "show")
	}
}


function SetStyleVisible(s, whichOne) {
	if (IsIE()) {
		GetIEStyle(s).visibility = whichOne ? "visible" : "hidden"
	}
	else {
		if (IsNS6()) {
			document.getElementById(s).style.visibility = whichOne ? "visible" : "hidden"
		}
		else GetNSStyle(s).visibility = whichOne ? "show" : "hide"
	}
}

		
function findObj(n, d) { //v3.0 (thanks Austin!)
  var p,i,x;  if(!d) d=document; if((p=n.indexOf("?"))>0&&parent.frames.length) {
    d=parent.frames[n.substring(p+1)].document; n=n.substring(0,p);}
  if(!(x=d[n])&&d.all) x=d.all[n]; for (i=0;!x&&i<d.forms.length;i++) x=d.forms[i][n];
  for(i=0;!x&&d.layers&&i<d.layers.length;i++) x=findObj(n,d.layers[i].document); return x;
}


function SetStyleText(s, theText) { // sets to contents of divText var
	if (IsIE() || IsNS6()) {
		document.getElementById(s).innerHTML = theText;
	}
	else {
		GetStyle(s).document.write(theText);
		GetStyle(s).document.close();
	}
	SetStyleVisible(s, true)
}


function clearSearchbox() {
	document.searchbox.document.Search.elements['queryText'].value=''
	document.searchbox.document.Search.elements['queryText'].blur()
	SetStyleVisible('searchbox', false)
}


function SetMenu(menuLevel, whichMenu, top) {
	var s = "menu"+menuLevel+"text"
	if (!(GetStyleVisible(s) && (GetStylePos(s, 1) == top))) {
		var s2 = "menu"+menuLevel+"bg"
		var myHeight = (eval('navarray'+menuLevel)[whichMenu].length/2)*15
		var theLink = ""
		if ((top+myHeight>maxY) && ((top-myHeight+15)>0)) {
			top = top-myHeight+15
		}
		var posSoFar = top
		SetStylePos(s,1,top)
		SetStylePos(s2,1,top)
		var theText="<table width=140 height="+String(myHeight)+" cellpadding=0 cellspacing=0 border=0 bgcolor=\"" + menuBGColor + "\">\r"
		theText+="	<tr><td><spacer type=\"block\" width=138 height="+String(myHeight-2)+">&nbsp;</td></tr>\r"
		theText+="</table></div>\r"
		SetStyleText(s2, theText)
		theText = "<table width=140 border=0 cellspacing=0 cellpadding=0>\r"
		theText+="	<tr>\r"
		theText+="		<td width=122 height=1><spacer type=\"block\" width=122 height=1></td>\r"
		theText+="		<td width=12 height=1><spacer type=\"block\" width=12 height=1></td>\r"
		theText+="	</tr>\r"
		var isMenuItem = false
		var theURL = ""
		for (var i = 0; i<eval('navarray'+menuLevel)[whichMenu].length; i=i+2) {
			isMenuItem = (typeof(eval('navarray'+menuLevel)[whichMenu][i+1]) == 'string')
			theText+="	<tr>\r"
			theText+="		<td class=\"leftnav\" width=122 height=14"
			if (isMenuItem) theText+=" colspan=2"
			theText+="><a class=\"leftnav\" href=\""
			theURL = String(eval('navarray'+menuLevel)[whichMenu][i+1])
			if ((theURL.indexOf("http") != 0) && isMenuItem) theText+=baseLoc
			if (isMenuItem) theText+=theURL+"\" onmouseover=\"moveBar("+menuLevel+", "+posSoFar+", "+(menuLevel+1)+")\""
			else theText+="#\" onmouseover=\"moveBar("+menuLevel+", "+posSoFar+", "+(menuLevel+1)+"); SetMenu("+String(menuLevel+1)+", "+eval('navarray'+menuLevel)[whichMenu][i+1]+", "+posSoFar+")\""
			theText+=" onmouseout=\"ridLater("+String(ridOnTimeout)+")"
			var newItemText = eval('navarray'+menuLevel)[whichMenu][i]
			if (IsIE()) var numChars = (24-newItemText.length)*0.7
			else var numChars = (24-newItemText.length)*1.69
			if (numChars >= 1) for (var j = 1; j<=numChars; j++) newItemText += "&nbsp;"
			theText+="\">&nbsp;" + newItemText + "</a></td>\r"
			if (!isMenuItem) theText+="<td align=right><b><a class=\"leftnav\" href=\"#\" onmouseover=\"moveBar("+menuLevel+", "+posSoFar+", "+(menuLevel+1)+"); SetMenu("+String(menuLevel+1)+", "+eval('navarray'+menuLevel)[whichMenu][i+1]+", "+posSoFar+")\" onmouseout=\"ridLater("+String(ridOnTimeout)+")\">&gt;</a></td>"
			theText+="	</tr>\r"
			if (i+2<eval('navarray'+menuLevel)[whichMenu].length) theText+="<tr>\r		<td colspan=2 height=1 bgcolor=\"" + menuLineColor + "\"><spacer type=\"block\" width=140 height=1></td>\r	</tr>\r"
			posSoFar+=15
		}
		theText+="</table>\r"
		SetStyleText(s, theText)
	}
}


function GetStylePos(s, d) {
	if (IsIE()) {
		if (d == 0) return GetIEStyle(s).posLeft
		else return GetIEStyle(s).posTop
	}
	else {
		if (d == 0) return GetNSStyle(s).left
		else return GetNSStyle(s).top
	}
}


function slideLayer(s, d, p, makeVisibleAfter) {
	var theDifference = 0
	var isInArray = FindStyleInArray(s) + 1
	SetStyleVisible(s, true)
	if (isInArray > 0) {
		closeAllDrawers()
	}
	var currentPos = GetStylePos(s, d)

	var theDifference = p - currentPos
	if (!((isInArray > 0) & (makeVisibleAfter == openDrawer))) {
		SetStylePos(s, d, currentPos + theDifference)
		if (isInArray > 0) for (var i = isInArray; i<mainNav.length; i++) {
			SetStylePos(mainNav[i], d, GetStylePos(mainNav[i],d) + theDifference)
		}
		if ((makeVisibleAfter != "") & (isInArray > 0)) {
			if (currentPos == defaultPos[isInArray-1]) {
				// activateMenu(makeVisibleAfter, 1)
				
				var menuTop = defaultPos[isInArray-1]
				if (makeVisibleAfter=='manager') menuTop -= 49
				
				SetMenu(1,isInArray-2,menuTop)
				
				if (openDrawer != "") restoreImage(openDrawer)
				openDrawer = mainNav[isInArray-2]
				exciteImage(makeVisibleAfter)
			}
		}
	}
	else {
		openDrawer = ""
		ridLayers(0)
	}
}