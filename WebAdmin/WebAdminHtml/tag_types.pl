# what type (defined below) should each object name be?
# this defaults to plaintext if not specified here or in the tag itself
%defaultTypes = (
	"pageRefreshInterval" => "option",
	"displayCount" => "option"
);

# definition of types and how they render HTML
# <value/> will be replaced with the value of the object
# <name/> will be replaced with the name of the object
# <param/> will be replaced with a user-specified parameter
%tagTypes = (
	"plaintext" => "<value/>",
	"string" => "<input type=text name=\"<name/>\" value=\"<value/>\"<param/>><input type=hidden name=\"<name/>_shadow\" value=\"<value/>\">",
	"text" => "<input type=text name=\"<name/>\" value=\"<value/>\"<param/>><input type=hidden name=\"<name/>_shadow\" value=\"<value/>\">",
	"password" => "<input type=password name=\"<name/>\" value=\"<value/>\"<param/>><input type=hidden name=\"<name/>_shadow\" value=\"<value/>\">",
	"hidden" => "<input type=hidden name=\"<name/>\" value=\"<value/>\">",
	"form" => "<form method=post name=\"mainform\" action=\"/parse_xml.cgi\" target=\"<param/>\">",
	"validatedform" => "<form method=post name=\"mainform\" action=\"/parse_xml.cgi\" target=\"<param/>\" onsubmit=\"return validateFormData()\">",
	"getform" => "<form method=get action=\"/parse_xml.cgi\" target=\"<param/>\">",
	"textarea" => "<textarea name=\"<name/>\"<param/>><value/></textarea>",
	"select" => "<input type=hidden name=\"<name/>_shadow\" value=\"<value/>\"><select name=\"<name/>\">",
	"submitselect" => "<input type=hidden name=\"<name/>_shadow\" value=\"<value/>\"><select name=\"<name/>\" onchange=\"document.forms[0].submit()\">",
	"option" => "<option value=\"<param/>\"<value/>>",
	"submit" => "<input type=submit value=\"<param/>\">",
	"customtablecell" => "<value/>"
);

# end tag definitions, if any
# defaults to a blank string
%endTagTypes = (
	"form" => "</form>",
	"getform" => "</form>",
	"select" => "</select>",
	"submitselect" => "</select>",
	"option" => "</option>",
	"customtablecell" => "</td>",
);

# solaris expects a return value
1;
