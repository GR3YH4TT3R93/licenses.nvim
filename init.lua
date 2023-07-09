-- TODO: lightbulb, code-action-menu, sandboxing lsp, dot_repeat, status column
-- tasks.nvim, licenses.nvim, autosession.nvim sub commands
-- licenses.nvim include directive
-- remove stabilize.nvim if 'splitkeep' gets better
-- feline diagnostic hints and info look the same

vim.cmd.runtime('minimal/init.vim')
vim.cmd.colorscheme('catppuccin')

for _, mod in ipairs({
    'plugins',
    'completion',
    'keymap',
    'autocmd',
}) do
    require(mod)
end
