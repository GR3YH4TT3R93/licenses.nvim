-- TODO: lightbulb, code-action-menu, sandboxing lsp, dot_repeat, status column
-- tasks.nvim, licenses.nvim, autosession.nvim sub commands
-- licenses.nvim include directive, ability to make templates so I can include:
--
-- Unless otherwise stated, all files in this directory and its subdirectories are
-- licensed as described below.
--
-- ===============================================================================
--
-- on top of LICENSE.txt
-- autoupdate licenses


-- remove stabilize.nvim if 'splitkeep' gets better
-- feline diagnostic hints and info look the same
-- look into vim.dianogstic, vim.lsp
-- iskeywoard, WORD
-- look more into gitsigns and gitui
-- add license to cursorword.vim, autosession and maybe other if missing

vim.cmd.colorscheme('catppuccin')
vim.cmd.runtime('minimal/init.vim')

for _, mod in ipairs({
    'plugins',
    'keymap',
    'autocmd',
}) do
    require(mod)
end
