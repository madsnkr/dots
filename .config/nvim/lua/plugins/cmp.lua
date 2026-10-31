return {
	"saghen/blink.cmp",
	dependencies = {
		-- blink.compat provides the `cmp` module cmp-calc requires, so it must load first
		{ "hrsh7th/cmp-calc", dependencies = { "saghen/blink.compat" } },
	},
	opts = {
		sources = {
			-- Math expression completion via blink.compat (wired up by LazyVim)
			compat = { "calc" },
		},
	},
}