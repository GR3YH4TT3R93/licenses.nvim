local M = {}

local api = vim.api

local Callbacks = {}
local Modules = {}

M.load = function(package)
    local setup = Callbacks[package]
    if setup
    then
        vim.cmd.packadd(package)
        setup()
        Callbacks[package] = nil
    end
end

M.register = function(package, opts)
    vim.validate({ opts = { opts, 'table' } })
    assert(not vim.tbl_isempty(opts), 'opts: cannot be empty')
    vim.validate({
        package = { package, 'string' },
        setup = { opts.setup, 'function', true },
        commands = { opts.commands, 'table', true },
        filetypes = { opts.filetypes, 'table', true },
        modules = { opts.modules, 'table', true },
    })

    Callbacks[package] = opts.setup or function() end

    for _, cmd in ipairs(opts.commands or {})
    do
        api.nvim_create_autocmd(
            'CmdUndefined',
            { pattern = cmd, callback = function() M.load(package) end }
        )
    end

    for _, ft in ipairs(opts.filetypes or {})
    do
        api.nvim_create_autocmd(
            'FileType',
            { pattern = ft, callback = function() M.load(package) end }
        )
    end

    for _, mod in ipairs(opts.modules or {}) do Modules[mod] = package end
end

M.require = function(mod)
    M.load(Modules[mod])
    Modules[mod] = nil
    return require(mod)
end

return M
