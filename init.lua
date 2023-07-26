-- TODO: lightbulb, code-action-menu, sandboxing lsp, dot_repeat, status column
-- tasks.nvim, licenses.nvim, autosession.nvim sub commands
-- licenses.nvim include directive
-- remove stabilize.nvim if 'splitkeep' gets better
-- feline diagnostic hints and info look the same
-- look into vim.dianogstic, vim.lsp

vim.cmd.colorscheme('catppuccin')
vim.cmd.runtime('minimal/init.vim')

for _, mod in ipairs({
    'plugins',
    'completion',
    'keymap',
    'autocmd',
}) do
    require(mod)
end
