local M = {}

---@class kube-schemas.Config
---@field catalog_url string URL to fetch the schema catalog from
M.defaults = {
	catalog_url = "https://schemas.r35.io/api/json/catalog.json",
}

---@type kube-schemas.Config
M.options = nil

---@param options? kube-schemas.Config
function M.setup(options)
	M.options = vim.tbl_deep_extend("force", {}, M.defaults, options or {})
end

---@param opts? kube-schemas.Config
function M.extend(opts)
	return opts and vim.tbl_deep_extend("force", {}, M.options, opts) or M.options
end

setmetatable(M, {
	__index = function(_, k)
		if k == "options" then
			return M.defaults
		end
	end,
})

return M
