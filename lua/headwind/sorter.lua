local config = require("headwind.config")

local M = {}

-- Remove duplicates from array (equivalent to [...new Set(classArray)])
local function remove_duplicates(class_array)
	local seen = {}
	local result = {}
	for _, class in ipairs(class_array) do
		if not seen[class] then
			seen[class] = true
			table.insert(result, class)
		end
	end
	return result
end

-- Find index of element in array (equivalent to sortOrder.indexOf(el))
local function index_of(array, element)
	for i, v in ipairs(array) do
		if v == element then
			return i
		end
	end
	return -1
end

-- Sort class array using the exact Headwind algorithm
local function sort_class_array(class_array, sort_order, should_prepend_custom_classes)
	local result = {}

	-- Filter classes not in sort order (custom classes)
	local custom_classes = {}
	for _, class in ipairs(class_array) do
		if index_of(sort_order, class) == -1 then
			table.insert(custom_classes, class)
		end
	end

	-- Filter classes that ARE in sort order
	local known_classes = {}
	for _, class in ipairs(class_array) do
		if index_of(sort_order, class) ~= -1 then
			table.insert(known_classes, class)
		end
	end

	-- Sort known classes by their position in sort_order
	table.sort(known_classes, function(a, b)
		local index_a = index_of(sort_order, a)
		local index_b = index_of(sort_order, b)
		return index_a < index_b
	end)

	-- Combine arrays based on shouldPrependCustomClasses
	if should_prepend_custom_classes then
		-- Custom classes first, then sorted known classes
		for _, class in ipairs(custom_classes) do
			table.insert(result, class)
		end
		for _, class in ipairs(known_classes) do
			table.insert(result, class)
		end
	else
		-- Sorted known classes first, then custom classes
		for _, class in ipairs(known_classes) do
			table.insert(result, class)
		end
		for _, class in ipairs(custom_classes) do
			table.insert(result, class)
		end
	end

	return result
end

-- Main sorting function (equivalent to sortClassString)
function M.sort_class_string(class_string, sort_order, options)
	options = options or {}
	local should_remove_duplicates = options.should_remove_duplicates ~= false
	local should_prepend_custom_classes = options.should_prepend_custom_classes or false
	local custom_tailwind_prefix = options.custom_tailwind_prefix or ""

	-- Determine separator (space or other)
	local default_separator = "%S+" -- Lua pattern for non-whitespace
	local default_replacement = " "

	if not string.find(class_string, " ") then
		default_separator = "[^.]+" -- Split by dots if no spaces
		default_replacement = "."
	end

	-- Split class string into array
	local class_array = {}
	for class in string.gmatch(class_string, default_separator) do
		if class ~= "" then
			table.insert(class_array, class)
		end
	end

	-- Remove duplicates if configured
	if should_remove_duplicates then
		class_array = remove_duplicates(class_array)
	end

	-- Clone sort order and add custom prefix if needed
	local sort_order_clone = {}
	for _, class in ipairs(sort_order) do
		if custom_tailwind_prefix ~= "" then
			table.insert(sort_order_clone, custom_tailwind_prefix .. class)
		else
			table.insert(sort_order_clone, class)
		end
	end

	-- Sort the class array
	class_array = sort_class_array(class_array, sort_order_clone, should_prepend_custom_classes)

	-- Join back to string
	local result = table.concat(class_array, default_replacement)

	-- Handle dot prefix if original string started with dot
	if default_replacement == "." and string.sub(class_string, 1, 1) == "." then
		return "." .. result
	else
		return result
	end
end

-- Sort classes according to the predefined order
function M.sort_classes(classes)
	local options = {
		should_remove_duplicates = config.options.remove_duplicates,
		should_prepend_custom_classes = false, -- Headwind default
		custom_tailwind_prefix = "",
	}

	local class_string = table.concat(classes, " ")
	local sorted_string = M.sort_class_string(class_string, config.options.sort_order, options)

	-- Split back into array
	local result = {}
	for class in string.gmatch(sorted_string, "%S+") do
		table.insert(result, class)
	end

	return result
end

-- Split class string into individual classes (preserves modifiers like hover:)
function M.split_classes(class_string)
	local classes = {}
	for class in string.gmatch(class_string, "%S+") do
		table.insert(classes, class)
	end
	return classes
end

-- Join classes back into a string
function M.join_classes(classes)
	return table.concat(classes, " ")
end

-- Main function to sort classes in a line using exact Headwind logic
function M.sort_classes_in_line(line, filetype)
	local patterns = {
		html = '(class=")([^"]*)(")',
		javascript = '(className=")([^"]*)(")',
		javascriptreact = '(className=")([^"]*)(")',
		typescript = '(className=")([^"]*)(")',
		typescriptreact = '(className=")([^"]*)(")',
		vue = '(class=")([^"]*)(")',
		svelte = '(class=")([^"]*)(")',
		php = '(class=")([^"]*)(")',
		erb = '(class=")([^"]*)(")',
		handlebars = '(class=")([^"]*)(")',
		twig = '(class=")([^"]*)(")',
	}

	local pattern = patterns[filetype] or patterns.html

	-- Replace class attribute preserving quotes and surrounding text
	local result = string.gsub(line, pattern, function(prefix, class_string, suffix)
		if class_string and class_string ~= "" then
			local options = {
				should_remove_duplicates = config.options.remove_duplicates,
				should_prepend_custom_classes = false, -- Headwind default
				custom_tailwind_prefix = "",
			}

			local sorted_string = M.sort_class_string(class_string, config.options.sort_order, options)
			return prefix .. sorted_string .. suffix
		else
			return prefix .. class_string .. suffix
		end
	end)

	return result
end

return M
