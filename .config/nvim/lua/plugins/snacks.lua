return {
	{
		"folke/snacks.nvim",
		opts = {
			picker = {
				sources = {
					files = {
						hidden = true,
					},
					grep = {
						hidden = true,
					},
					projects = {
						dev = (function()
							local xdg_projects = vim.fn.getenv("XDG_PROJECTS_DIR")
							-- Fallback to standard defaults if the environment variable isn't set
							if xdg_projects == vim.NIL or xdg_projects == "" then
								return { "~/dev", "~/projects" }
							end
							return { xdg_projects }
						end)(),
					},
					explorer = {
						hidden = true,
						layout = {
							preset = "sidebar",
							preview = { main = true, enabled = false },
						},
					},
				},
			},
		},
	},
}
