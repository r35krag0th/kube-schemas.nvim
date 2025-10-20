local api = require("kube-schemas.catalog_api")
local config = require("kube-schemas.config")

local M = {}

--- Setup the plugin with user options
---@param opts? kube-schemas.Config
function M.setup(opts)
	config.setup(opts)
end

--- Activate the Picker UI to select and insert a schema modeline
function M.perform_selection()
	local schema_list = api.get_schema_list(config.options.catalog_url)

	if #schema_list == 0 then
		vim.notify("No schemas available", vim.log.levels.WARN)
		return
	end

	vim.ui.select(schema_list, {
		prompt = "Select a YAML schema",
		format_item = function(item)
			return item.name
		end,
	}, function(selection)
		if not selection then
			return -- User cancelled
		end

		local modeline = "# yaml-language-server: $schema=" .. selection.url
		vim.api.nvim_buf_set_lines(0, 0, 0, false, { modeline })
		vim.notify("Inserted schema modeline for: " .. selection.name, vim.log.levels.INFO)
	end)
end

return M
