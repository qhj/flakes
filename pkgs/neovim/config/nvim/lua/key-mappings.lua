local utils = require('utils')
local map = utils.map

function _G.beginning_of_line()
  local col, match, getline = vim.fn.col, vim.fn.match, vim.fn.getline
  return col('.') == match(getline('.'), [[\S]]) + 1 and '0' or '^'
end

-- leader key
vim.g.mapleader = ' '

-- window navigation
map('n', '<C-h>', '<C-w>h')
map('n', '<C-j>', '<C-w>j')
map('n', '<C-k>', '<C-w>k')
map('n', '<C-l>', '<C-w>l')

-- window resize
map('n', '<C-Up>', ':resize -2<CR>')
map('n', '<C-Down>', ':resize +2<CR>')
map('n', '<C-Left>', ':vertical resize -2<CR>')
map('n', '<C-Right>', ':vertical resize +2<CR>')
map('i', 'jk', '<Esc>')
map('i', 'kj', '<Esc>')

-- paste without yanking
map('x', 'p', 'P')

map('n', 'H', 'v:lua.beginning_of_line()', { expr = true })
map('x', 'H', 'v:lua.beginning_of_line()', { expr = true })
map('n', 'L', '$')
map('x', 'L', '$')

-- move line
map('n', 'J', ':m .+1<CR>==')
map('n', 'K', ':m .-2<CR>==')
map('x', 'J', ":m '>+1<CR>gv=gv")
map('x', 'K', ":m '<-2<CR>gv=gv")


-- local function t(str)
--     return vim.api.nvim_replace_termcodes(str, true, true, true)
-- end
--
-- function _G.cmp_down()
--     return vim.fn.pumvisible() ~= 0 and t'<Down>' or t'<C-n>'
-- end
--
-- function _G.cmp_up()
--     return vim.fn.pumvisible() ~= 0 and t'<Up>' or t'<C-p>'
-- end
-- map('i', '<C-p>', 'v:lua.cmp_up()', { expr = true })
-- map('i', '<C-n>', 'v:lua.cmp_down()', { expr = true })


-- map('n', 'K', 'yyP')
-- map('n', 'J', 'yyp')

map('x', '>', '>gv')
map('x', '<', '<gv')
-- better indentation

map('n', 'qq', ':q<CR>')
map('n', '<Leader>pe', ':NvimTreeToggle<CR>')

-- buffer navigation
map('n', '<M-h>', ':bprevious<CR>')
map('n', '<M-l>', ':bnext<CR>')

-- select "inner line" (without whitespace)
map('x', 'il', ':normal ^vg_<CR>')
map('o', 'il', ':normal vil<CR>', { noremap = false })
