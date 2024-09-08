return {
  -- note taking and documentation, etc
  {
    "lervag/wiki.vim",
    ft = { "markdown", "vimwiki" },
    init = function()
      vim.g.wiki_mappings_use_defaults = "none" -- Dont use default mappings as they mess up existsing bindings
      vim.g.wiki_root = "~/Documents/wiki"
    end,
  },
}
