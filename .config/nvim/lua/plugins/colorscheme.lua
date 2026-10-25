return {
	{
		"rebelot/kanagawa.nvim",
	},
	{
		"nyoom-engineering/oxocarbon.nvim",
		build = false, -- ships a rockspec; skip the luarocks build (nothing to compile)
	},
	{ "EdenEast/nightfox.nvim" },
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "oxocarbon",
		},
	},
}
