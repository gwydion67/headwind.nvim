local M = {}

local config = require("headwind.config")
local sorter = require("headwind.sorter")
local commands = require("headwind.commands")

-- Setup function to initialize the plugin
function M.setup(opts)
	config.setup(opts or {})
	commands.setup()

	-- Auto-sort on save if enabled and tailwind config exists
	if config.options.run_on_save then
		vim.api.nvim_create_autocmd("BufWritePre", {
			group = vim.api.nvim_create_augroup("HeadwindAutoSort", { clear = true }),
			callback = function()
				if M.should_run_on_save() then
					M.sort_tailwind_classes()
				end
			end,
		})
	end
end

-- Check if we should run on save
function M.should_run_on_save()
	local cwd = vim.fn.getcwd()
	local tailwind_config_files = {
		"tailwind.config.js",
		"tailwind.config.ts",
		"tailwind.config.cjs",
		"tailwind.config.mjs",
	}

	for _, file in ipairs(tailwind_config_files) do
		if vim.fn.filereadable(cwd .. "/" .. file) == 1 then
			return true
		end
	end
	return false
end

-- Main sorting function
function M.sort_tailwind_classes()
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local filetype = vim.bo.filetype

	local modified = false
	local new_lines = {}

	for i, line in ipairs(lines) do
		local new_line = sorter.sort_classes_in_line(line, filetype)
		table.insert(new_lines, new_line)
		if new_line ~= line then
			modified = true
		end
	end

	if modified then
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
	end
end

-- Sort classes in selection
function M.sort_selection()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local start_line = start_pos[2] - 1
	local end_line = end_pos[2]

	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)
	local filetype = vim.bo.filetype

	local modified = false
	local new_lines = {}

	for i, line in ipairs(lines) do
		local new_line = sorter.sort_classes_in_line(line, filetype)
		table.insert(new_lines, new_line)
		if new_line ~= line then
			modified = true
		end
	end

	if modified then
		vim.api.nvim_buf_set_lines(bufnr, start_line, end_line, false, new_lines)
	end
end

return M
