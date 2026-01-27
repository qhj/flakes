vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt
opt.autowrite = true
opt.clipboard = 'unnamedplus'
-- opt.completeopt = { 'menuone', 'noselect' }
opt.ignorecase = true
opt.mouse = 'a'
opt.pumheight = 10
opt.showmode = false
opt.smartcase = true
-- opt.smartindent = true
opt.splitbelow = true
opt.splitright = true
opt.termguicolors = true
opt.undofile = true
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.cursorline = true
opt.number = true
opt.signcolumn = 'yes'
opt.wrap = false
opt.scrolloff = 3
opt.sidescrolloff = 7
opt.shiftround = true
opt.laststatus = 3 
opt.fillchars = { eob = ' ' }

