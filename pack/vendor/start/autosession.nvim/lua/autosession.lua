-- SPDX-FileCopyrightText: 2024 Ash <contact@ash.fail>
-- SPDX-License-Identifier: MIT

-- MIT License

--  Copyright (c) 2024 Ash contact@ash.fail

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to
-- deal in the Software without restriction, including without limitation the
-- rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
-- sell copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice (including the next
-- paragraph) shall be included in all copies or substantial portions of the
-- Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
-- IN THE SOFTWARE.

-- TODO: docs

local M = {}

local api = vim.api
local cmd = vim.cmd
local fn = vim.fn
local v = vim.v

local AUGROUP = nil
local SESSION_DIR = nil

---@param msg string
---@param level? integer
---@private
local notify = function(msg, level)
    vim.notify('autosession.nvim: ' .. msg, level)
end

---@return string
---@private
local get_session_file = function()
    assert(SESSION_DIR)
    return string.format(
        '%s/%s.vim', SESSION_DIR, fn.getcwd():gsub('/', '%%')
    )
end

---@param file string
---@return string
---@private
local get_view_file = function(file)
    assert(SESSION_DIR)
    return string.format('%s/view/%s.vim', SESSION_DIR, file:gsub('/', '%%'))
end

---@param session_file string
---@private
local mksession = function(session_file)
    cmd.mksession({ args = { fn.fnameescape(session_file) }, bang = true })
end

---@param session_file string
---@private
local setup_autocmds = function(session_file)
    api.nvim_create_autocmd(
        { 'BufEnter', 'VimLeavePre' },
        { callback = function() mksession(session_file) end, group = AUGROUP }
    )
end

---@param session_file? string
M.session_load = function(session_file, force)
    session_file = session_file or get_session_file()
    if fn.filereadable(session_file) == 0
    then
        notify(
            'Cannot load session, file not readable `' .. session_file .. '`',
            vim.log.levels.ERROR
        )
        return
    elseif not force and v.this_session == session_file
    then
        notify(
            'Session already loaded `' .. session_file .. '`',
            vim.log.levels.ERROR
        )
        return
    end
    cmd.source(fn.fnameescape(session_file))
    setup_autocmds(session_file)
end

---@param session_file? string
---@param force? boolean
M.session_start = function(session_file, force)
    session_file = session_file or get_session_file()

    if v.this_session == session_file and not force
    then
        notify(
            'Already tracking session in `' .. session_file .. '`',
            vim.log.levels.ERROR
        )
        return
    end

    mksession(session_file)
    setup_autocmds(session_file)
    v.this_session = session_file
    notify('Tracking session in `' .. session_file .. '`')
end

M.session_stop = function()
    api.nvim_clear_autocmds({ group = AUGROUP })
    local session_file = v.this_session
    os.remove(session_file)
    v.this_session = ''
    notify('Deleted session `' .. session_file .. '`')
end

---@class Config
---@field auto_load boolean
---@field create_user_commands boolean
---@field mkview boolean | fun(bufnr: integer): boolean
---@field session_dir string
local default_config = {
    auto_load = true,
    create_user_commands = true,
    mkview = function(bufnr)
        return not vim.tbl_contains({ 'help', 'man' }, vim.bo[bufnr].filetype)
    end,
    session_dir = fn.stdpath('state') .. '/sessions',
}

---@param config? Config
M.setup = function(config)
    ---@type Config
    config = vim.tbl_extend('force', default_config, config or {})

    vim.validate({
        auto_load = { config.auto_load, 'boolean' },
        create_user_commands = { config.create_user_commands, 'boolean' },
        mkview = { config.mkview, { 'boolean', 'function' } },
        session_dir = { config.session_dir, 'string' }
    })

    AUGROUP = api.nvim_create_augroup('autosession.nvim', { clear = true })
    SESSION_DIR = config.session_dir

    fn.mkdir(config.session_dir, 'p')

    if config.create_user_commands
    then
        api.nvim_create_user_command(
            'SessionLoad',
            function(opts) M.session_load(opts.fargs[1], opts.bang) end,
            {
                bang = true,
                bar = true,
                complete = 'file',
                desc = 'Load session from a file',
                nargs = '?',
            }
        )
        api.nvim_create_user_command(
            'SessionStart',
            function(opts) M.session_start(opts.fargs[1], opts.bang) end,
            {
                bang = true,
                bar = true,
                complete = 'file',
                desc = 'Start tracking session',
                nargs = '?',
            }
        )
        api.nvim_create_user_command(
            'SessionStop',
            M.session_stop,
            { bar = true, desc = 'Stop tracking session', nargs = 0 }
        )
    end

    if config.auto_load and fn.argc() == 0
    then
        api.nvim_create_autocmd(
            'VimEnter',
            {
                callback = function()
                    local session_file = get_session_file()
                    if fn.filereadable(session_file) ~= 0
                    then
                        M.session_load(session_file)
                    else
                        M.session_start()
                    end
                end,
                group = AUGROUP,
                nested = true,
            }
        )
    end

    if config.mkview
    then
        fn.mkdir(config.session_dir .. '/view', 'p')
        api.nvim_create_autocmd(
            'BufWinEnter',
            {
                callback = function(opts)
                    if type(config.mkview) == 'function'
                        and not config.mkview(opts.buf)
                    then
                        return
                    end
                    pcall(cmd.source, fn.fnameescape(get_view_file(opts.file)))
                end,
                group = AUGROUP,
                pattern = '?*',
            }
        )

        api.nvim_create_autocmd(
            { 'BufWinLeave', 'VimLeavePre' },
            {
                callback = function(opts)
                    local viewopts = vim.go.viewoptions
                    cmd.set('viewoptions=cursor,folds')
                    cmd.mkview({
                        args = { fn.fnameescape(get_view_file(opts.file)) },
                        bang = true,
                    })
                    vim.go.viewoptions = viewopts
                end,
                group = AUGROUP,
                pattern = '?*',
            }
        )
    end
end

return M
