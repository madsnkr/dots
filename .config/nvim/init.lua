local ide_mode = os.getenv("NVIM_MODE") == "1"

if ide_mode then
	-- bootstrap lazy.nvim, LazyVim and your plugins
	require("config.lazy")
else
	vim.cmd("source ~/.config/nvim/minimal.vim")
end
