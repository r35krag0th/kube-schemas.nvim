local api = require("kube-schemas.catalog_api")
local config = require("kube-schemas.config")

local M = {}

--- Setup the plugin with user options
---@param opts? kube-schemas.Config
function M.setup(opts)
	config.setup(opts)
end

--- Find the YAML document boundaries that contain the cursor
---@return number|nil start_line The starting line of the document (0-indexed)
---@return number|nil end_line The ending line of the document (0-indexed)
local function find_document_bounds()
	local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1 -- Convert to 0-indexed
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	local start_line = 0
	local end_line = #lines - 1

	-- Find the start of the current document (look backward for ---)
	for i = cursor_line, 0, -1 do
		if lines[i + 1] and lines[i + 1]:match("^%-%-%-") then
			start_line = i + 1 -- Start after the separator
			break
		end
	end

	-- Find the end of the current document (look forward for ---)
	for i = cursor_line + 1, #lines - 1 do
		if lines[i + 1] and lines[i + 1]:match("^%-%-%-") then
			end_line = i - 1 -- End before the separator
			break
		end
	end

	return start_line, end_line
end

--- Parse the current YAML document to extract apiVersion and kind
---@param start_line? number Starting line (0-indexed), defaults to document containing cursor
---@param end_line? number Ending line (0-indexed), defaults to document containing cursor
---@return string|nil apiVersion
---@return string|nil kind
---@return number|nil insert_line The line where modeline should be inserted (0-indexed)
local function parse_yaml_resource(start_line, end_line)
	-- If no bounds provided, find the document containing the cursor
	if not start_line or not end_line then
		start_line, end_line = find_document_bounds()
	end

	local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line + 1, false)
	local api_version, kind
	local insert_line = start_line

	for i, line in ipairs(lines) do
		-- Skip comments and empty lines
		if not line:match("^%s*#") and not line:match("^%s*$") then
			-- Match apiVersion
			local av = line:match("^%s*apiVersion:%s*(.+)%s*$")
			if av then
				api_version = av
			end

			-- Match kind
			local k = line:match("^%s*kind:%s*(.+)%s*$")
			if k then
				kind = k
			end

			-- Stop if we found both
			if api_version and kind then
				break
			end
		end
	end

	return api_version, kind, insert_line
end

--- Find schema matching the given apiVersion and kind
---@param schema_list table List of schemas
---@param api_version string The apiVersion from YAML
---@param kind string The kind from YAML
---@return table|nil schema The matching schema, or nil if not found
local function find_matching_schema(schema_list, api_version, kind)
	local kind_lower = kind:lower()
	local group = ""
	local version = api_version

	-- Split apiVersion into group and version (e.g., "apps/v1" -> "apps", "v1")
	if api_version:match("/") then
		group, version = api_version:match("^(.+)/(.+)$")
	end

	local url_patterns = {}

	-- Escape special pattern characters (dots, hyphens) for Lua pattern matching
	local function escape_pattern(str)
		return str:gsub("[%.%-]", "%%%1")
	end

	-- Build URL patterns to try
	if group ~= "" then
		local group_escaped = escape_pattern(group:lower())
		local kind_escaped = escape_pattern(kind_lower)
		local version_escaped = escape_pattern(version)

		-- For CRDs with full group domain (e.g., "cert-manager.io/v1")
		-- Pattern 1: /crds/{group}/{kind}_{version}.json
		table.insert(
			url_patterns,
			"/crds/" .. group_escaped .. "/" .. kind_escaped .. "_" .. version_escaped .. "%.json$"
		)

		-- Pattern 2: /crds/master-standalone/{group}-stable-{kind}_{version}.json
		table.insert(
			url_patterns,
			"/crds/master%-standalone/"
				.. group_escaped
				.. "%-stable%-"
				.. kind_escaped
				.. "_"
				.. version_escaped
				.. "%.json$"
		)

		-- For core Kubernetes grouped resources (e.g., "apps/v1")
		-- Pattern 3: {kind}-{group}-{version}.json
		local group_short = group:gsub("%..*", "")
		local group_short_escaped = escape_pattern(group_short:lower())
		table.insert(url_patterns, kind_escaped .. "%-" .. group_short_escaped .. "%-" .. version_escaped .. "%.json$")
	else
		-- Core resources (v1, v1beta1, etc.)
		-- Pattern: {kind}-{version}.json
		local kind_escaped = escape_pattern(kind_lower)
		local version_escaped = escape_pattern(version)
		table.insert(url_patterns, kind_escaped .. "%-" .. version_escaped .. "%.json$")
	end

	-- Try each pattern
	for _, pattern in ipairs(url_patterns) do
		for _, schema in ipairs(schema_list) do
			if schema.url:lower():match(pattern) then
				return schema
			end
		end
	end

	return nil
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
			if
				schema.name:lower():find(lower_query, 1, true)
				or schema.description:lower():find(lower_query, 1, true)
			then
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

--- Auto-detect schema based on apiVersion and kind in current YAML document
function M.auto_detect()
	local api_version, kind, insert_line = parse_yaml_resource()

	if not api_version or not kind then
		vim.notify("Could not detect apiVersion and kind in current document", vim.log.levels.WARN)
		return
	end

	local schema_list = api.get_schema_list(config.options.catalog_url)

	if #schema_list == 0 then
		vim.notify("No schemas available", vim.log.levels.WARN)
		return
	end

	local schema = find_matching_schema(schema_list, api_version, kind)

	if not schema then
		vim.notify(string.format("No schema found for %s (kind: %s)", api_version, kind), vim.log.levels.WARN)
		return
	end

	-- Insert the modeline at the start of the current document
	local modeline = "# yaml-language-server: $schema=" .. schema.url
	vim.api.nvim_buf_set_lines(0, insert_line, insert_line, false, { modeline })
	vim.notify(string.format("Auto-inserted schema for %s/%s: %s", api_version, kind, schema.name), vim.log.levels.INFO)
end

return M
