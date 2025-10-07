return {
	{
		"mason-org/mason.nvim",
		opts = function(_, opts)
			vim.list_extend(opts.ensure_installed or {}, {
				"shfmt",
				"shellcheck",
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			inlay_hints = { enabled = true },
			diagnostics = { virtual_text = { prefix = "icons" } },
			servers = {
				bashls = {},
				dockerls = {},
				html = {},
				yamlls = {
					settings = {
						yaml = {
							schemas = {
								kubernetes = "*.{yaml,yml}",
							},
						},
					},
				},
				azure_pipelines_ls = {
					settings = {
						yaml = {
							schemas = {
								["https://raw.githubusercontent.com/microsoft/azure-pipelines-vscode/master/service-schema.json"] = {
									"/azure-pipeline*.y*l",
									"/*.azure*",
									"Azure-Pipelines/**/*.y*l",
									"Pipelines/*.y*l",
								},
							},
						},
					},
				},
			},
			setup = {},
		},
	},
}
