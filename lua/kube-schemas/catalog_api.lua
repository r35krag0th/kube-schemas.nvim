local M = {}

function M.fetch_schemas(url)
	local response = vim.fn.systemlist("curl -s " .. url)
	local body = table.concat(response, "\n")
	local data = vim.fn.json_decode(body)
	return data.schemas or {}
end

-- Build a picker list from the fetched schemas
function M.get_schema_list()
	local storage = {}
	local schemas = M.fetch_schemas()
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
