vim.cmd.colorscheme('catppuccin')
vim.cmd.runtime('minimal/init.vim')

for _, mod in ipairs({
    'plugins',
    'keymap',
    'autocmd',
}) do
    require(mod)
end
