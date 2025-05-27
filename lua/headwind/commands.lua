local M = {}

local function setup_commands()
	-- Create user commands
	vim.api.nvim_create_user_command("HeadwindSort", function()
		require("headwind").sort_tailwind_classes()
	end, {
		desc = "Sort Tailwind CSS classes in the current buffer",
	})

	vim.api.nvim_create_user_command("HeadwindSortSelection", function()
		require("headwind").sort_selection()
	end, {
		desc = "Sort Tailwind CSS classes in the current selection",
		range = true,
	})

	vim.api.nvim_create_user_command("HeadwindToggle", function()
		local config = require("headwind.config")
		config.options.run_on_save = not config.options.run_on_save
		local status = config.options.run_on_save and "enabled" or "disabled"
		vim.notify("Headwind auto-sort on save " .. status)
	end, {
		desc = "Toggle Headwind auto-sort on save",
	})
end

local function setup_keymaps()
	-- Optional default keymaps (users can override these)
	vim.keymap.set("n", "<leader>hw", "<cmd>HeadwindSort<cr>", {
		desc = "Sort Tailwind classes",
		silent = true,
	})

	vim.keymap.set("v", "<leader>hw", "<cmd>HeadwindSortSelection<cr>", {
		desc = "Sort Tailwind classes in selection",
		silent = true,
	})
end

function M.setup()
	setup_commands()
	setup_keymaps()
end

return M
