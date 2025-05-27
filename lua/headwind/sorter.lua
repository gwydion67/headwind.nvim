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
		for orig_idx, el in ipairs(class_array) do
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
	-- CRITICAL: We need to preserve original order for classes with same sort priority
	local classes_in_order = {}
	for orig_idx, el in ipairs(class_array) do
		for sort_idx, sort_el in ipairs(sort_order) do
			if el == sort_el then
				table.insert(classes_in_order, {
					class = el,
					sort_index = sort_idx,
					original_index = orig_idx, -- Keep original position for stable sort
				})
				break
			end
		end
	end

	-- Sort by sort_index first, then by original_index for stability
	-- This matches JavaScript's stable sort behavior
	table.sort(classes_in_order, function(a, b)
		if a.sort_index == b.sort_index then
			return a.original_index < b.original_index -- Preserve original order for same priority
		end
		return a.sort_index < b.sort_index
	end)

	for _, item in ipairs(classes_in_order) do
		table.insert(result, item.class)
	end

	-- Third part: classes not in sort order if shouldPrependCustomClasses is false
	if not should_prepend_custom_classes then
		for orig_idx, el in ipairs(class_array) do
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

	-- Exact logic from TypeScript: const default_separator = classString.includes(' ') ? /\s+/g : '.';
	local has_spaces = string.find(class_string, " ") ~= nil
	local default_separator_is_dot = not has_spaces
	local default_replacement = has_spaces and " " or "."

	-- Split classString exactly like TypeScript version
	local class_array = {}

	-- Use custom separator if provided, otherwise use default logic
	if options.separator then
		-- For custom separator, split by the provided pattern
		if type(options.separator) == "string" then
			for class in string.gmatch(class_string, "[^" .. options.separator .. "]+") do
				if class ~= "" then
					table.insert(class_array, class)
				end
			end
		else
			-- If separator is a pattern, use it directly
			for class in string.gmatch(class_string, options.separator) do
				if class ~= "" then
					table.insert(class_array, class)
				end
			end
		end
	else
		-- Default separator logic - exact match to TypeScript
		if has_spaces then
			-- Split by whitespace (/\s+/g equivalent)
			for class in string.gmatch(class_string, "%S+") do
				table.insert(class_array, class)
			end
		else
			-- Split by dots (equivalent to splitting by '.')
			-- Handle case where string starts with dot
			local working_string = class_string
			if string.sub(working_string, 1, 1) == "." then
				working_string = string.sub(working_string, 2)
			end

			for class in string.gmatch(working_string, "[^.]+") do
				if class ~= "" then
					table.insert(class_array, class)
				end
			end
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

	-- Exact logic from TypeScript: if( (default_separator == ".") && (classString.startsWith(".")))
	if default_separator_is_dot and string.sub(class_string, 1, 1) == "." then
		return "." .. result
	else
		return result
	end
end

-- Updated sort_classes_in_line to handle custom separators and replacements
function M.sort_classes_in_line(line, filetype, custom_options)
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
			local options = custom_options
				or {
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

-- New function to handle dot-separated class strings specifically
function M.sort_dot_separated_classes(class_string, custom_options)
	local options = custom_options
		or {
			should_remove_duplicates = config.options.remove_duplicates,
			should_prepend_custom_classes = false,
			custom_tailwind_prefix = "",
			separator = nil, -- Let it auto-detect dots
			replacement = nil, -- Let it auto-detect dots
		}

	return M.sort_class_string(class_string, config.options.sort_order, options)
end

-- New function to handle space-separated class strings specifically
function M.sort_space_separated_classes(class_string, custom_options)
	local options = custom_options
		or {
			should_remove_duplicates = config.options.remove_duplicates,
			should_prepend_custom_classes = false,
			custom_tailwind_prefix = "",
			separator = nil, -- Let it auto-detect spaces
			replacement = nil, -- Let it auto-detect spaces
		}

	return M.sort_class_string(class_string, config.options.sort_order, options)
end

-- Enhanced function with full options support
function M.sort_classes_with_options(class_string, options)
	options = options or {}

	-- Merge with defaults
	local merged_options = {
		should_remove_duplicates = options.should_remove_duplicates or config.options.remove_duplicates,
		should_prepend_custom_classes = options.should_prepend_custom_classes or false,
		custom_tailwind_prefix = options.custom_tailwind_prefix or "",
		separator = options.separator,
		replacement = options.replacement,
	}

	return M.sort_class_string(class_string, config.options.sort_order, merged_options)
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
