local wo = vim.wo
local lsp = vim.lsp.buf

local dot_repeat = require('dot_repeat').mk_cmd

local keymaps = {
    { '', '<Tab>a', lsp.code_action },
    { '', '<Tab>m', lsp.hover },
    { '', '<Tab>p', lsp.rename },
    { '', '<Tab>t', lsp.format },
    { '', '<Leader>b', ':TroubleToggle<CR>' },
    { '', '<Leader>d', dot_repeat('Commentary', { type = 'range' }) },
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
    { '', '<A-e>', dot_repeat('move .-2') },
    { '', '<A-n>', dot_repeat('move .+1') },
    { '', ']i', vim.diagnostic.goto_next },
    { '', '[i', vim.diagnostic.goto_prev },
    { 'ic', '<C-n>', require('cmp').complete },
    { 'c', '<Tab>', require('cmp').complete },
    { 'n', '<Space>', lsp.hover },
    { 'v', '<A-e>', dot_repeat('move \'<-2', { type = 'range' }) .. 'gv' },
    { 'v', '<A-n>', dot_repeat('move \'>+1', { type = 'range' }) .. 'gv' },
}

local telescope = function(action, opts)
    return function()
        require('lazyload').require('telescope.builtin')[action](opts)
    end
end

-- each of <C-/> and <C-_> work in some terminals but not some others
for _, finder in ipairs({
    { 'g', telescope('live_grep') },
    { 'm', telescope('help_tags') },
    { 'p', lsp.references },
    { 'r', lsp.document_symbol },
    { 's', lsp.definition },
    { 't', telescope('find_files') },
    { 'v', telescope('git_files') },
    {
        'z',
        telescope('buffers', { ignore_current_buffer = true, sort_mru = true }),
    },
}) do
    table.insert(keymaps, { '', '<C-/>' .. finder[1], finder[2] })
    table.insert(keymaps, { '', '<C-_>' .. finder[1], finder[2] })
end

for _, keymap in ipairs(keymaps) do
    local modes, lhs, rhs, opts = unpack(keymap)
    ---@diagnostic disable-next-line: cast-local-type
    modes = vim.fn.split(modes, '\\zs') --[[@as table]]
    modes[1] = modes[1] or ''
    for _, mode in ipairs(modes)
    do
        vim.keymap.set(mode, lhs, rhs, opts)
    end
end
