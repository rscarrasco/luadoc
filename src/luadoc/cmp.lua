
module "luadoc.cmp"

require "luadoc.compose"
local CMP = luadoc.compose.CMP

-----------------------------------------------------------------
-- Composition rules for generating the output files.

-----------------------------------------------------------------
-- Table of expected Lua types to be bolded on the output.
-- @see first_rest.

local types = {
	string = 1,
	number = 1,
	table = 1,
	["function"] = 1,
	["nil"] = 1,
}

-----------------------------------------------------------------
-- Split the string in two parts: the first word and the rest of
-- the string.
-- @param str String to be processed.
-- @return Two strings: the first word and the rest of the original
--	string.

function first_rest (str)
	local t = types
	t.first = nil
	t.rest = nil
	local _ = string.gsub (str, "^(%S+)(.*)$", function (f,r)
		if t[string.lower (f)] then
			t.first = f
			t.rest = r
		end
	end)
	if _ then
		return t.first, t.rest
	else
		return nil, nil
	end
end

-----------------------------------------------------------------
-- Print the file header.

function file_header (field_value)
	field_value = string.gsub (field_value, "^.*/([^/]+)$", "%1")
	return field_value.."<hr>"
end

-----------------------------------------------------------------
-- Print the file footer.

function file_footer (field_value)
	if not field_value then
		field_value = ""
	else
		field_value = field_value.."<br>"
	end
	return field_value..
		"<hr><small>This file was automatically generated by LuaDoc in "..
		os.date ("%d of %B of %Y")..".</small>"
end

-----------------------------------------------------------------
-- Build a function that will create an anchor with a filter.
-- @param f Function that will filter the name of the anchor.
-- @return Function that will be used to create an anchor.

function anchor (f)
	return function (field_value)
		return '<a name="'..field_value..'">'..f (field_value)..'</a>'
	end
end

function link_rel (f)
   return function (field_value)
	return '<a href="#'..field_value..'">'..f (field_value)..'</a>'
   end
end

function link_abs (f)
	return function (field_value)
		field_value = string.gsub (field_value, "^.*/([^/]+)$", "%1")
		return '<a href="'..field_value..'">'..f (field_value)..'</a>'
	end
end

function link_abs_1 (field_value)
	field_value = string.gsub (field_value, "^.*/([^/]+)$", "%1")
	return '<a href="'..field_value..'">'
end

function link_abs_2 (f)
	return function (field_value)
		field_value = string.gsub (field_value, "^.*/([^/]+)$", "%1")
		return f (field_value)..'</a>'
	end
end

-----------------------------------------------------------------
-- Names of document sections.

local section_names = {
	["function"] = "Functions",
	local_function = "Local functions",
        string = "Definitions",
	constant = "Definitions",
	table = "Definitions",
}

-----------------------------------------------------------------
-- @param source Table with source data.

function MakeTitle (source)
   if source.class and CMP.section_name ~= section_names[source.class] then
      CMP.section_name = section_names[source.class]
      CMP.write ("<h3>\n"..CMP.section_name.."\n</h3>")
   end
end

-----------------------------------------------------------------
-- @param source Table with source data (not used).

function MakeIndex (source)
   if not CMP._index_ then
      CMP._index_ = 1
      CMP.write ("<h1>Index</h1>\n<h3>Files</h3>\n")
   end
end

-----------------------------------------------------------------
-- @param field_value Object to be printed.

function Write (field_value)
   return field_value
end

-----------------------------------------------------------------
-- Build a [[Write]] function that generate the output for a table.
-- @param label String label used by the function.
-- @return Function that "prints" all table's fields and values.

function Write_each (label)
   return function (field_value)
	local s = ""
	for i, v in pairs(field_value) do
	   if i ~= "n" then
	      local first, rest = first_rest (v)
	      if first then
	         s = s.."<dd><code>"..i.."</code>: <b>"..first.."</b>"..
			rest.."\n"
	      else
	         s = s.."<dd><code>"..i.."</code>: "..v.."\n"
	      end
	   end
	end
	return "<dt><i>"..label.."</i>\n"..s
   end
end

function List_table (label)
   return function (field_value)
	local s = ""
	for j = 1, table.getn(field_value) do
	   local i = field_value[j]
	   local v = field_value[i]
	   if i ~= "n" and v then
	      local first, rest = first_rest (v)
	      if first then
	         s = s..'<tr><td valign="top"><code>'..i..
			'</code></td><td><b>'..first..'</b>'..
			rest..'</td></tr>\n'
	      else
	         s = s..'<tr><td valign="top"><code>'..i..
			'</code></td><td>'..v..'</td></tr>\n'
	      end
	   end
	end
	return "<dt><i>"..label.."</i><table>\n"..s.."</table>\n"
   end
end

function List_each_link (label)
   return function (field_value)
	local s = ""
	for i, v in field_value do
	   if i ~= "n" then
	      local t = { f = "", n = v, }
	      if string.find (v, "#", 1, 1) then
	         string.gsub (v, "^([^#]+)#([^#]+)$", function (file, name)
	         	t.f = file..".html"
	         	t.n = name
	         end)
	      end
	      s = s..'<dd><a href="'..t.f..'#'..t.n..'">'..t.n..'</a>\n'
	   end
	end
	return "<dt><i>"..label.."</i>\n"..s
   end
end

function Ctags (...)
   local b = ""
   local e = ""
   for i = 1, table.getn(arg) do
      local tag = arg[i]
      b = b.."<"..tag..">"
      e = e.."</"..tag..">"
   end
   return function (field_value)
	return b..field_value..e.."\n"
   end
end

function Citemize (label, linebreak)
   return function (field_value)
	return "<i>"..label.."</i>: "..field_value..linebreak.."\n"
   end
end

function Citemize_first (label, linebreak)
   return function (field_value)
	local first, rest = first_rest (field_value)
	if first then
	   return "<i>"..label.."</i> <b>"..first.."</b>"..rest..
		linebreak.."\n"
	else
	   return "<i>"..label.."</i> "..field_value..linebreak.."\n"
	end
   end
end

html = {
	{ "in_file", file_header },
	{ "title", Ctags ("p", "h1") },
	--"<p>\n",
	{ "resume", Ctags ("h3") },
	{ "description", Citemize ("Description", "<br>") },
	{ "author", Citemize ("Author", "<br>") },
	{ "copyright", Citemize ("Copyright", "<br>") },
	{ "date", Citemize ("Date", "<br>") },
	;
	internal = {
		MakeTitle,
		{ "name", anchor (Ctags ("code", "b")) },
		{ "param_list", Ctags ("code") },
		{ "value", Citemize_first ("=", "<br>") },
		"<ul>\n",
		{ "resume", Ctags ("b") },
		{ "description", Write },
		{ "param", List_table ("Parameters") },
		"<br>\n",
		{ "ret", Citemize_first ("Return Value:", "<br>") },
		{ "see", List_each_link ("See also") },
		"</ul>\n",
		"<p>\n",
		;
		order_field = { "section", "name" },
		anchor_field = { "name" },
	},
	internal_index = {
		MakeTitle,
		{ "name", link_rel (Ctags ("code", "b")) },
		{ "param_list", Ctags ("code") },
		{ "value", Citemize_first ("=", "") },
		"<dd>\n",
		{ "resume", Write },
		"</dd>\n",
		;
		order_field = { "section", "name" },
		link_field = { "name" },
	},
	file_index = {
		MakeIndex,
		;
		internal = {},
		internal_index = {
			{ "out_file", link_abs_1 },
			{ "in_file", link_abs_2 (Ctags ("code", "b")) },
			--{ "in_file", link_abs (Ctags ("code", "b")) },
			--{ "out_file", link_abs (Ctags ("code", "b")) },
			"<br>\n",
		},
		order_field = { "out_file" },
	},
	footer = file_footer,
}

return html
