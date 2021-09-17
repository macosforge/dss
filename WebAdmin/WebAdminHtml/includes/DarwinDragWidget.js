// Constants
var offsetX = 12;
var offsetY = 0;
var tolerance = 6;

// Globals
var darwinOriginalDragX = 0;
var darwinOriginalDrayY = 0;
var currentDragBox = null;

// Constructor for the DarwinDragWidget class.
function DarwinDragWidget(window, multipleSelectedString) {
	// Remember some arguments for later.
	this.window = window;
	this.id = 'darwinDragWidget';
	this.body = '';
	this.multipleSelectedString = multipleSelectedString;
	// Output a CSS-P style sheet for this document.
	var d = window.document;
	d.writeln('<style type="text/css">');
	d.write('#darwinDragWidget { position: absolute; ');
	d.write('left: 0px; top: 0px; ');
	d.write('visibility: hidden; ');
	d.writeln('}');
	d.write('#darwinInvisibleCover { position: absolute; ');
	d.write('left: 0px; top: 0px; ');
	d.write('width: 4px; height: 4px; ');
	d.write('visibility: hidden; ');
	d.writeln('}');
	d.writeln('<' + '/style>');
}

// This will output the initial HTML
DarwinDragWidget.prototype.output = function() {
	var d = this.window.document;
	
	d.writeln('<div id="' + this.id + '" class=line-item>');
	d.writeln(this.body);
	d.writeln('<' + '/div>');
	
	d.writeln('<div id="darwinInvisibleCover" onmouseout="SetStyleVisible(\'darwinInvisibleCover\', false)">');
	d.writeln('<img src="images/invis_dragcover.gif" width=4 height=4>');
	d.writeln('<' + '/div>');
	
	// save references to the element
	this.element = d.getElementById(this.id);
	this.style = this.element.style;
	this.window.darwinDragWidget = this;
	this.element.object = this;
}

DarwinDragWidget.prototype.draw = function() {
	if (this.contents) {
		if (this.contents.length == 1)
			this.element.innerHTML = this.contents[0].draw();
		else
			this.element.innerHTML = this.multipleSelectedString;
		
		this.style.visibility = 'hidden';
		this.offsetX = this.style.pixelWidth / 2;
		this.offsetY = this.style.pixelHeight / 2;
	}
}

function GetScrollPos(d) {

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

function darwinHandleMouseMove(e) {
	if (e) {
		var currentX = e.pageX;
		var currentY = e.pageY;
	}
	else {
		var currentX = event.clientX + GetScrollPos(0);
		var currentY = event.clientY + GetScrollPos(1);
	}
	if ((Math.abs(currentX - darwinOriginalDragX) > tolerance) || (Math.abs(currentY - darwinOriginalDrayY) > tolerance)) {
		SetStylePos('darwinDragWidget', 0, currentX + offsetX);
		SetStylePos('darwinDragWidget', 1, currentY + offsetY);
		darwinDragWidget.style.visibility = 'visible';
		if (IsNS6()) {
			currentDragBox = null;
			for (i = 0; i < dragRegionBoxes.length; i++) {
				var g = dragRegionBoxes[i];
				var regionEndX = g.locationX + g.sizeX;
				var regionEndY = g.locationY + g.sizeY;
				if ((currentX > g.locationX) && (currentX < regionEndX) && (currentY > g.locationY) && (currentY < regionEndY)) {
					g.element.style.backgroundColor = g.highlightcolor;
					currentDragBox = g;
				}
				else {
					if (currentDragBox == g)
						currentDragBox = null;
					g.element.style.backgroundColor = '#FFFFFF';
				}
			}
		}
	}
	return false;
}

function darwinHandleMouseUp(e) {
	var d = darwinDragWidget.window.document;
	var str = '';
	darwinDragWidget.style.visibility = 'hidden';
	// stop tracking events
	d.onmousemove = null;
	d.onmouseup = null;
	if (currentDragBox) {
		for (i = 0; i < dragRegionBoxes.length; i++) {
			var g = dragRegionBoxes[i];
			g.element.style.backgroundColor = '#FFFFFF';
		}
		var allElements = currentDragBox.element.getElementsByTagName('div');
		if (allElements.length > 0) {
			var lastElement = allElements[allElements.length-1];
			lastElement.scrollIntoView();
		}
	}
	return true;
}