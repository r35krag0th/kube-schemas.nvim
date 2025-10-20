local curl = require("plenary.curl")

local M = {}

--- Fetch schemas from the catalog URL using plenary
---@param url string The catalog URL to fetch from
---@return table|nil schemas The schemas array, or nil on error
---@return string|nil error Error message if fetch failed
function M.fetch_schemas(url)
	local ok, response = pcall(curl.get, url, {
		accept = "application/json",
	})

	if not ok then
		return nil, "Failed to fetch schemas: " .. tostring(response)
	end

	if response.status ~= 200 then
		return nil, string.format("HTTP %d error fetching schemas from %s", response.status, url)
	end

	-- Try to decode JSON
	local decode_ok, data = pcall(vim.json.decode, response.body)
	if not decode_ok then
		return nil, "Failed to parse JSON response from " .. url
	end

	return data.schemas or {}, nil
end

--- Build a picker list from the fetched schemas
---@param url string The catalog URL to fetch from
---@return table schema_list List of schemas ready for picker
function M.get_schema_list(url)
	local schemas, err = M.fetch_schemas(url)

	if err then
		vim.notify(err, vim.log.levels.ERROR)
		return {}
	end

	local storage = {}
	for _, schema in ipairs(schemas) do
		table.insert(storage, {
			name = schema.name,
			description = schema.description or "No description available",
			url = schema.url,
		})
	end

	return storage
end

return M
