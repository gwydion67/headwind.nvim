local config = require("headwind.config")

local M = {}

-- Create a lookup table for sort order
local function create_sort_order_map(sort_order)
	local map = {}
	for i, class in ipairs(sort_order) do
		map[class] = i
	end
	return map
end

-- Sort classes according to the predefined order
function M.sort_classes(classes)
	local sort_order_map = create_sort_order_map(config.options.sort_order)

	-- Remove duplicates if enabled
	if config.options.remove_duplicates then
		local seen = {}
		local unique_classes = {}
		for _, class in ipairs(classes) do
			if not seen[class] then
				seen[class] = true
				table.insert(unique_classes, class)
			end
		end
		classes = unique_classes
	end

	-- Sort classes
	table.sort(classes, function(a, b)
		local order_a = sort_order_map[a] or math.huge
		local order_b = sort_order_map[b] or math.huge

		if order_a == order_b then
			return a < b -- Alphabetical fallback
		end

		return order_a < order_b
	end)

	return classes
end

-- Extract classes from a line using regex
function M.extract_classes_from_line(line, filetype)
	local regex = config.options.class_regex[filetype] or config.options.class_regex.html
	local matches = {}

	for match in string.gmatch(line, regex) do
		table.insert(matches, match)
	end

	return matches
end

-- Split class string into individual classes
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

-- Main function to sort classes in a line
function M.sort_classes_in_line(line, filetype)
	local regex = config.options.class_regex[filetype] or config.options.class_regex.html

	-- Replace all class attributes in the line
	local result = string.gsub(line, regex, function(class_string)
		local classes = M.split_classes(class_string)
		local sorted_classes = M.sort_classes(classes)
		return M.join_classes(sorted_classes)
	end)

	return result
end

return M
