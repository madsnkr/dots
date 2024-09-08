-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local opts = { noremap = true, silent = true }

-- Increment and Decrement
vim.keymap.set("n", "+", "<C-a>")
vim.keymap.set("n", "-", "<C-x>")

-- Select all
vim.keymap.set("n", "<C-a>", "gg<S-v>G", opts)

-- Tabs
vim.keymap.set("n", "te", ":tabedit")
vim.keymap.set("n", "tq", ":tabclose<CR>", opts)

-- Window
vim.keymap.set("n", "<C-q>", "<C-w>q", opts)

-- Clear quickfix list
vim.keymap.set("n", "<leader>xc", ":call setqflist([])<CR>", opts)
