local config = require("headwind.config")

local M = {}

-- Exact implementation of removeDuplicates from Headwind
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

-- Exact implementation of sortClassArray from Headwind using spread operator logic
local function sort_class_array(class_array, sort_order, should_prepend_custom_classes)
	local result = {}

	-- First part: classes not in sort order if shouldPrependCustomClasses is true
	if should_prepend_custom_classes then
		for _, el in ipairs(class_array) do
			local found_in_sort_order = false
			for _, sort_el in ipairs(sort_order) do
				if el == sort_el then
					found_in_sort_order = true
					break
				end
			end
			if not found_in_sort_order then
				table.insert(result, el)
			end
		end
	end

	-- Second part: classes that ARE in sort order, sorted by their position
	local classes_in_order = {}
	for _, el in ipairs(class_array) do
		for sort_idx, sort_el in ipairs(sort_order) do
			if el == sort_el then
				table.insert(classes_in_order, { class = el, index = sort_idx })
				break
			end
		end
	end

	-- Sort by index in sort_order (equivalent to .sort((a, b) => sortOrder.indexOf(a) - sortOrder.indexOf(b)))
	table.sort(classes_in_order, function(a, b)
		return a.index < b.index
	end)

	for _, item in ipairs(classes_in_order) do
		table.insert(result, item.class)
	end

	-- Third part: classes not in sort order if shouldPrependCustomClasses is false
	if not should_prepend_custom_classes then
		for _, el in ipairs(class_array) do
			local found_in_sort_order = false
			for _, sort_el in ipairs(sort_order) do
				if el == sort_el then
					found_in_sort_order = true
					break
				end
			end
			if not found_in_sort_order then
				table.insert(result, el)
			end
		end
	end

	return result
end

-- Exact implementation of sortClassString from Headwind
function M.sort_class_string(class_string, sort_order, options)
	options = options or {}

	-- Exact logic from Headwind: const default_separator = classString.includes(' ') ? /\s+/g : '.';
	local has_spaces = string.find(class_string, " ") ~= nil
	local default_separator = has_spaces and "%S+" or "[^.]+"
	local default_replacement = has_spaces and " " or "."

	-- Split classString: let classArray = classString.split(options.separator || default_separator);
	local class_array = {}
	local separator_pattern = options.separator or default_separator

	if has_spaces then
		-- Split by whitespace
		for class in string.gmatch(class_string, "%S+") do
			table.insert(class_array, class)
		end
	else
		-- Split by dots
		for class in string.gmatch(class_string, "[^.]+") do
			table.insert(class_array, class)
		end
	end

	-- Filter empty elements: classArray = classArray.filter((el) => el !== '');
	local filtered_array = {}
	for _, el in ipairs(class_array) do
		if el ~= "" then
			table.insert(filtered_array, el)
		end
	end
	class_array = filtered_array

	-- Remove duplicates if configured
	if options.should_remove_duplicates then
		class_array = remove_duplicates(class_array)
	end

	-- Clone sort order and add custom prefix: const sortOrderClone = [...sortOrder];
	local sort_order_clone = {}
	for _, class in ipairs(sort_order) do
		table.insert(sort_order_clone, class)
	end

	-- Add custom prefix if configured
	if options.custom_tailwind_prefix and options.custom_tailwind_prefix ~= "" then
		for i = 1, #sort_order_clone do
			sort_order_clone[i] = options.custom_tailwind_prefix .. sort_order_clone[i]
		end
	end

	-- Sort the array using exact Headwind logic
	class_array = sort_class_array(class_array, sort_order_clone, options.should_prepend_custom_classes or false)

	-- Join back to string: const result = classArray.join(options.replacement || default_replacement).trim()
	local replacement = options.replacement or default_replacement
	local result = table.concat(class_array, replacement)

	-- Handle dot prefix: if( (default_separator == ".") && (classString.startsWith(".")))
	if not has_spaces and string.sub(class_string, 1, 1) == "." then
		return "." .. result
	else
		return result
	end
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

-- Legacy functions for compatibility
function M.sort_classes(classes)
	local class_string = table.concat(classes, " ")
	local options = {
		should_remove_duplicates = config.options.remove_duplicates,
		should_prepend_custom_classes = false,
		custom_tailwind_prefix = "",
	}

	local sorted_string = M.sort_class_string(class_string, config.options.sort_order, options)

	local result = {}
	for class in string.gmatch(sorted_string, "%S+") do
		table.insert(result, class)
	end

	return result
end

function M.split_classes(class_string)
	local classes = {}
	for class in string.gmatch(class_string, "%S+") do
		table.insert(classes, class)
	end
	return classes
end

function M.join_classes(classes)
	return table.concat(classes, " ")
end

return M
