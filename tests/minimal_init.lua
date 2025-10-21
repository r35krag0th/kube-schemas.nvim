-- Minimal init for running tests
local plenary_dir = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"

-- Add plenary to runtimepath
vim.opt.rtp:append(".")
vim.opt.rtp:append(plenary_dir)

-- Ensure plenary is installed
if vim.fn.isdirectory(plenary_dir) == 0 then
	vim.fn.system({
		"git",
		"clone",
		"--depth=1",
		"https://github.com/nvim-lua/plenary.nvim",
		plenary_dir,
	})
end

-- Load plenary
vim.cmd("runtime! plugin/plenary.vim")
