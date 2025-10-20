vim.create_user_command("KubeSchemas", function()
	require("kube-schemas").perform_selection()
end, {
	desc = "Select and insert a Kubernetes YAML schema modeline",
})

vim.keymap.set("n", "<leader>ks", function()
	require("kube-schemas").perform_selection()
end, {
	desc = "Select and insert a Kubernetes YAML schema modeline",
})
