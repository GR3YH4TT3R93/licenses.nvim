local wo = vim.wo
local lsp = vim.lsp.buf

local dot_repeat = require('dot_repeat')

local telescope = function(action, opts)
    return function()
        require('lazyload').require('telescope.builtin')[action](opts)
    end
end

for _, keymap in ipairs({
    -- each of <C-/> and <C-_> work in some terminals but not some others
    { '', '<C-/>g', telescope('live_grep') },
    { '', '<C-/>m', telescope('help_tags') },
    { '', '<C-/>p', telescope('lsp_references') },
    { '', '<C-/>r', telescope('lsp_document_symbols') },
    { '', '<C-/>s', lsp.definition },
    { '', '<C-/>t', telescope('find_files') },
    { '', '<C-/>v', telescope('git_files') },
    {
        '',
        '<C-/>z',
        telescope('buffers', { ignore_current_buffer = true, sort_mru = true }),
    },
    { '', '<C-_>g', telescope('live_grep') },
    { '', '<C-_>m', telescope('help_tags') },
    { '', '<C-_>p', telescope('lsp_references') },
    { '', '<C-_>r', telescope('lsp_document_symbols') },
    { '', '<C-_>s', lsp.definition },
    { '', '<C-_>t', telescope('find_files') },
    { '', '<C-_>v', telescope('git_files') },
    {
        '',
        '<C-_>z',
        telescope('buffers', { ignore_current_buffer = true, sort_mru = true }),
    },
    { '', '<Tab>a', lsp.code_action },
    { '', '<Tab>m', lsp.hover },
    { '', '<Tab>p', lsp.rename },
    { '', '<Tab>t', lsp.format },
    { '', '<Leader>b', ':TroubleToggle<CR>' },
    { '', '<Leader>d', dot_repeat.mk_cmd('Commentary', { type = 'range' }) },
    { '', '<Leader>t', lsp.format },
    {
        '',
        '<C-X>',
        function()
            local fm = wo.foldmethod
            wo.foldmethod = 'expr'
            vim.cmd.normal({ args = { 'zx' }, bang = true })
            wo.foldmethod = fm
        end,
    },
    { '', '<A-e>', dot_repeat.mk_cmd('move .-2') },
    { '', '<A-n>', dot_repeat.mk_cmd('move .+1') },
    { 'i', '<C-n>', require('cmp').complete },
    { 'n', '<Space>', lsp.hover },
    { 'v', '<A-e>', dot_repeat.mk_cmd('move \'<-2', { type = 'range' }) .. 'gv' },
    { 'v', '<A-n>', dot_repeat.mk_cmd('move \'>+1', { type = 'range' }) .. 'gv' },
}) do
    local modes, lhs, rhs, opts = unpack(keymap)
    ---@diagnostic disable-next-line: cast-local-type
    modes = vim.fn.split(modes, '\\zs') --[[@as table]]
    modes[1] = modes[1] or ''
    for _, mode in ipairs(modes)
    do
        vim.keymap.set(mode, lhs, rhs, opts)
    end
end
