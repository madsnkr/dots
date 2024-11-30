-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local opts = { noremap = true, silent = true }

-- Increment and Decrement
vim.keymap.set("n", "+", "<C-a>", vim.tbl_extend("force", opts, { desc = "Increment" }))
vim.keymap.set("n", "-", "<C-x>", vim.tbl_extend("force", opts, { desc = "Decrement" }))

vim.keymap.set("i", "jk", "<Esc>", vim.tbl_extend("force", opts, { desc = "Escape jk" }))

-- Check if cursor is over link
-- local function is_zettelkasten_link()
--   local link = vim.fn.expand("<cWORD>")
--   -- return link:match("^%[%[.-%]%]$") ~= nil
--   return link:match("%[%[.-%]%]$") ~= nil
-- end
-- -- Hit <CR> to open zettelkasten links
-- vim.keymap.set("n", "<CR>", function()
--   if is_zettelkasten_link() then
--     local link = vim.fn.expand("<cword>")
--     local zettelkasten_dir = vim.env.HOME .. "/" .. "Zettelkasten"
--     local note = zettelkasten_dir .. "/" .. link .. ".md"
--     vim.cmd("edit " .. note)
--   else
--     vim.cmd("normal! <CR>")
--   end
-- end, opts)

-- Select all
-- vim.keymap.set("n", "<C-a>", "gg<S-v>G", vim.tbl_extend("force", opts, { desc = "Select all" }))

-- Window
vim.keymap.set("n", "<C-q>", "<C-w>q", vim.tbl_extend("force", opts, { desc = "Close window" }))

-- Clear quickfix list
vim.keymap.set(
  "n",
  "<leader>xc",
  ":call setqflist([])<CR>",
  vim.tbl_extend("force", opts, { desc = "Clear quickfix list" })
)
