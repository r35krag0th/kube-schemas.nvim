-- Initialize plugin with defaults if setup() wasn't called
local kube_schemas = require("kube-schemas")
local config = require("kube-schemas.config")

-- Ensure defaults are loaded
if not config.options then
	kube_schemas.setup()
end

-- Subcommand handlers
local subcommands = {
	search = function(args)
		-- Join remaining args as search query, or nil if empty
		local query = #args > 0 and table.concat(args, " ") or nil
		kube_schemas.perform_selection(query)
	end,
	auto = function(args)
		kube_schemas.auto_detect()
	end,
}

-- Create the main command with subcommand support
vim.api.nvim_create_user_command("KubeSchemas", function(opts)
	local subcommand = opts.fargs[1]

	if not subcommand then
		vim.notify(
			"KubeSchemas requires a subcommand. Available: " .. table.concat(vim.tbl_keys(subcommands), ", "),
			vim.log.levels.ERROR
		)
		return
	end

	local handler = subcommands[subcommand]
	if handler then
		-- Pass remaining args to handler
		local args = vim.list_slice(opts.fargs, 2)
		handler(args)
	else
		vim.notify("Unknown subcommand: " .. subcommand, vim.log.levels.ERROR)
		vim.notify("Available subcommands: " .. table.concat(vim.tbl_keys(subcommands), ", "), vim.log.levels.INFO)
	end
end, {
	nargs = "*",
	complete = function(arg_lead, cmdline, _)
		local parts = vim.split(cmdline, "%s+")

		-- Complete subcommand names
		if #parts <= 2 then
			return vim.tbl_filter(function(cmd)
				return cmd:find(arg_lead, 1, true) == 1
			end, vim.tbl_keys(subcommands))
		end

		return {}
	end,
	desc = "Kubernetes schema utilities",
})
