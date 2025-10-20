-- Initialize plugin with defaults if setup() wasn't called
local kube_schemas = require("kube-schemas")
local config = require("kube-schemas.config")

-- Ensure defaults are loaded
if not config.options then
	kube_schemas.setup()
end

-- Create the main command
vim.api.nvim_create_user_command("KubeSchemas", function()
	kube_schemas.perform_selection()
end, {
	desc = "Select and insert a Kubernetes YAML schema modeline",
})
