local M = {}

-- Check if a file exists
function M.file_exists(path)
	local stat = vim.loop.fs_stat(path)
	return stat and stat.type == "file"
end

-- Get the current working directory
function M.get_cwd()
	return vim.fn.getcwd()
end

-- Check if any of the tailwind config files exist
function M.has_tailwind_config()
	local cwd = M.get_cwd()
	local config_files = {
		"tailwind.config.js",
		"tailwind.config.ts",
		"tailwind.config.cjs",
		"tailwind.config.mjs",
	}

	for _, file in ipairs(config_files) do
		if M.file_exists(cwd .. "/" .. file) then
			return true
		end
	end
	return false
end

-- Debounce function to prevent excessive calls
function M.debounce(func, delay)
	local timer = nil
	return function(...)
		local args = { ... }
		if timer then
			vim.loop.timer_stop(timer)
			vim.loop.timer_close(timer)
		end
		timer = vim.loop.new_timer()
		vim.loop.timer_start(timer, delay, 0, function()
			vim.schedule(function()
				func(unpack(args))
			end)
		end)
	end
end

return M
