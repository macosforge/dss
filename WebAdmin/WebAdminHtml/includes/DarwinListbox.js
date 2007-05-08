var dragRegionBoxes = new Array();
var testCount = 0;

// Constructor for DarwinListbox class.
function DarwinListbox(window, id, locationX, locationY, width, height, background, bordercolor, highlightcolor, allowMultipleSelect, allowDrag, allowDrop, allowRearrange) {
	// Remember some arguments for later.
	this.window = window;
	this.id = id;
	this.body = '';
	this.contents = new Array();
	this.highlightcolor = highlightcolor;
	this.mousedown = false;
	this.allowMultipleSelect = allowMultipleSelect;
	this.allowDrag = allowDrag;
	this.allowDrop = allowDrop;
	this.locationX = locationX;
	this.locationY = locationY;
	this.sizeX = width;
	this.sizeY = height;
	this.width = width;
	this.height = height;
	this.bordercolor = bordercolor;
	// If this is droppable, add it to the list of droppable regions.
	if (allowDrop)
		dragRegionBoxes[dragRegionBoxes.length] = this;
	this.allowRearrange = allowRearrange;
	// Output a CSS-P style sheet for this document.
	var d = window.document;
	d.writeln('<style type="text/css">');
	d.write('#' + id + ' { ');
	width += 17;
	d.write('overflow: scroll; ');
	d.write('border-style: solid; ');
	d.write('border-width: 1px; ');
	d.write('border-color: ' + bordercolor + '; ');
	d.write('background: ' + background + '; ');
	if (width) d.write('width: ' + width + 'px; ');
	if (height) d.write('height: ' + width + 'px; ');
	d.writeln('}');
	d.writeln('<' + '/style>');
}

// This will output the initial HTML
DarwinListbox.prototype.output = function() {
	var d = this.window.document;
	
	d.writeln('<div id="' + this.id + '">');
	d.writeln(this.body);
	d.writeln('<' + '/div>');
	
	// save references to the element
	this.element = d.getElementById(this.id);
	this.style = this.element.style;
	
	// set the document's events
	if (document.captureEvents)
		document.captureEvents(Event.MOUSEUP|Event.MOUSEDOWN|Event.MOUSEMOVE);
}

DarwinListbox.prototype.draw = function() {
	var str = '';
	
	for (var i in this.contents) {
		str += '<div id="' + this.id + i + '" class="line-item" onmouseover="this.parent.handleMouseOver(this)" onmouseout="this.parent.handleMouseOut(this)" onselectstart="return false" onmousemove="this.parent.handleMouseOver(this)">';
		this.contents[i].parent = this;
		str += this.contents[i].draw();
		str += '<' + '/div>';
	}
	
	this.element.innerHTML = str;
	
	for (var i in this.contents) {
		this.window.document.getElementById(this.id + i).parent = this;
	}
}

DarwinListbox.prototype.selectOne = function(obj) {
	var itemClicked = obj.id.replace(this.id, '');
	
	// if the item is already selected, do nothing
	if (!this.contents[itemClicked].selected) {
		// deselect everything
		for (var i in this.contents) {
			this.window.document.getElementById(this.id + i).style.background = 'inherit';
			this.contents[i].selected = false;
		}
		// select the clicked item
		obj.style.background = this.highlightcolor;
		this.contents[itemClicked].selected = true;
		
		// send it a callback message so it can handle any UI changes
		this.contents[itemClicked].onupdate();
	}
	else {
	}
	// set the last item clicked in case they shift-click next time
	this.lastItemClicked = itemClicked;
}

DarwinListbox.prototype.handleMouseOver = function(obj) {
	var d = this.window.document;
	this.window.status = obj.id;
	this.window.currentDarwinObj = obj;
	if (d.onmousemove == darwinHandleMouseMove) {
		if (this.allowDrop)
			this.selectOne(obj);
	}
	else {
		d.onmousedown = darwinHandleMouseDown;
	}
}

// this gets called when the user mouses out of a list item
DarwinListbox.prototype.handleMouseOut = function(obj) {
	if (this.window.document.onmousemove == darwinHandleMouseMove) {
		this.window.currentDarwinObj = null;
		this.window.document.onmousedown = null;
	}
}

// this should get called when the user drops something onto the listbox
DarwinListbox.prototype.handleDrop = function(obj) {
	
}

function darwinHandleMouseDown(e) {
	if (e) {
		var currentX = e.pageX;
		var currentY = e.pageY;
	}
	else {
		var currentX = event.clientX + GetScrollPos(0);
		var currentY = event.clientY + GetScrollPos(1);
		e = window.event;
	}
	var itemClicked = window.currentDarwinObj.id.replace(window.currentDarwinObj.parent.id, '');
	window.currentDarwinObj.parent.selectOne(window.currentDarwinObj);
	
	// set up the drag widget, and send mouse move and up events to it
	if (darwinDragWidget) {
		var g = darwinDragWidget;
		var d = window.document;
		darwinOriginalDragX = currentX;
		darwinOriginalDrayY = currentY;
		g.contents = new Array(window.currentDarwinObj.parent.contents[itemClicked]);
		g.draw();
		d.onmousemove = darwinHandleMouseMove;
		d.onmouseup = darwinHandleMouseUp;
	}
	
	this.mousedown = true;
	return false;
}