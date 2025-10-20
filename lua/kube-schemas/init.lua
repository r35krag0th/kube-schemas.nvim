-- We want to parse this "API" for schemas:
--
-- https://schemas.r35.io/api/json/catalog.json
local api = require("kube-schemas.catalog_api")

local M = {}

M.options = {}
M.defaults = {
	catalog_url = "https://schemas.r35.io/api/json/catalog.json",
}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

-- Activate the Picker UI using Snacks picker
function M.perform_selection()
	local schema_list = api.get_schema_list(M.options.catalog_url)

	vim.ui.select(schema_list, {
		prompt = "Select a YAML schema",
		format_item = function(item)
			return item.name
		end,
	}, function(selection)
		local modeline = "# yaml-language-server: $schema=" .. selection.url
		vim.api.nvim_buf_set_lines(0, 0, 0, false, { modeline })
		print("Inserted schema modeline for: " .. selection.name)
	end)
end

return M
