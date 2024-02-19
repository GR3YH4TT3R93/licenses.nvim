for _, autocmd in ipairs({
    {
        'FileType',
        {
            pattern = 'TelescopePrompt',
            callback = function()
                require('cmp').setup.buffer(
                    { completion = { autocomplete = false } }
                )
            end,
        },
    },
    {
        'FileType',
        { pattern = 'Trouble', command = 'setlocal cc=0 signcolumn=no' },
    },
    {
        'User',
        {
            pattern = 'TelescopePreviewerLoaded',
            command = 'setlocal number wrap',
        },
    },
}) do
    local event, opts = unpack(autocmd)
    opts.group = 'vimrc'
    vim.api.nvim_create_autocmd(event, opts)
end
