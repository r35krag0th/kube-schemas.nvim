local api = require("kube-schemas.catalog_api")
local config = require("kube-schemas.config")

local M = {}

--- Setup the plugin with user options
---@param opts? kube-schemas.Config
function M.setup(opts)
	config.setup(opts)
end

--- Activate the Picker UI to select and insert a schema modeline
---@param query? string Optional search query to pre-populate the picker
function M.perform_selection(query)
	local schema_list = api.get_schema_list(config.options.catalog_url)

	if #schema_list == 0 then
		vim.notify("No schemas available", vim.log.levels.WARN)
		return
	end

	-- Filter schemas if query provided
	local filtered_list = schema_list

	if query and query ~= "" then
		local filtered = {}
		local lower_query = query:lower()
		for _, schema in ipairs(schema_list) do
			if schema.name:lower():find(lower_query, 1, true) or
			   schema.description:lower():find(lower_query, 1, true) then
				table.insert(filtered, schema)
			end
		end

		if #filtered == 0 then
			vim.notify("No schemas found matching: " .. query, vim.log.levels.WARN)
			return
		end

		filtered_list = filtered
	end

	-- Use vim.ui.select (will use Snacks if configured as backend)
	vim.ui.select(filtered_list, {
		prompt = query and ("Select a YAML schema (filtered: " .. query .. ")") or "Select a YAML schema",
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
