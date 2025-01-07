return {
  {
    "lervag/wiki.vim",
    ft = { "markdown", "vimwiki" },
    init = function()
      -- vim.g.wiki_mappings_use_defaults = "none"
      vim.g.wiki_root = "~/Zettelkasten"
      vim.g.wiki_link_creation = {
        md = {
          link_type = "wiki",
          url_extension = "",
        },
      }
    end,
  },
}
