-- SPDX-FileCopyrightText: 2023 Ash <contact<at>ash<dot>fail>
-- SPDX-License-Identifier: MIT

-- MIT License

--  Copyright (c) 2023 Ash contact<at>ash<dot>fail

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

local api = vim.api
local fn = vim.fn

local M = {}

---@class synctex.nvim-FiletypeConfig
---@field build? string | string[]
---@field launch? string | string[]
---@field jump? string | string[]

-- TODO:
--      - docs
--      - option to not create user commands
--      - option to not create autocommands

---@private
---@class synctex.nvim-Config
---@field filetypes table<string, synctex.nvim-FiletypeConfig>
local Config = {
    tex = {
        build = { 'tectonic', '--synctex', '%{file_name}' },
        launch = {
            'zathura',
            '--synctex-editor-command',
            "nvim --server %{server} --remote-send '<Cmd>Synctex backward \\%{line} \\%{input}<CR>'",
            '%{file_basename}.pdf',
        },
        jump = {
            'zathura',
            '--synctex-forward=%{line}:%{column}:%{file_name}',
            '%{file_basename}.pdf',
        },
    },
}
-- TODO: make the above into an example and not the default

---@private
---@param bufnr integer
local get_config = function(bufnr)
    return vim.tbl_extend(
        'force',
        Config[vim.bo[bufnr].filetype] or {},
        vim.b[bufnr].synctex or {}
    )
end

---@private
---@param cmd string[]
---@return string[]
local parse_cmd = function(bufnr, cmd)
    local fname = api.nvim_buf_get_name(bufnr)
    local line, column
    api.nvim_buf_call(
        bufnr,
        function()
            line = fn.line('.')
            column = fn.col('.')
        end
    )

    local vars = {
        server = vim.v.servername,
        file_name = fname,
        file_basename = fn.fnamemodify(fname, ':r'),
        line = line,
        column = column,
    }

    return vim.tbl_map(
        function(v)
            return v:gsub(
                '(\\*)%%{(%S-)}',
                function(escapes, var)
                    if #escapes % 2 ~= 0
                    then
                        return escapes:sub(0, -2) .. '%{' .. var .. '}'
                    end

                    return escapes .. (vars[var] or '')
                end
            )
        end,
        cmd
    )
end

---@private
---@return string
local get_augroup = function()
    local name = 'synctex.nvim'

    if fn.exists('#' .. name) ~= 1 then api.nvim_create_augroup(name, {}) end

    return name
end

---@param bufnr integer
---@return nil | string
M.jump_forward = function(bufnr)
    if not vim.b[bufnr].synctex_attached
    then
        return 'not attached to bufnr: ' .. bufnr
    end

    local jump = get_config(bufnr).jump
    if not jump or vim.tbl_isempty(jump)
    then
        return 'no jump command configured for `'
            .. vim.bo[bufnr].filetype .. '`'
    end

    fn.jobstart(parse_cmd(bufnr, jump))
end

---@param line integer
---@param fname string
---@return nil | string
M.jump_backward = function(line, fname)
    local bufnr = fn.filter(
        api.nvim_list_bufs(),
        function(_, bufnr)
            return api.nvim_buf_get_name(bufnr) == fname
                and vim.b[bufnr].synctex_attached ~= nil
        end
    )[1]

    if not bufnr
    then
        return 'no attached buffer matching `' .. fname .. '` found'
    end

    local win = fn.win_findbuf(bufnr)[1]
    if win
    then
        api.nvim_set_current_win(win)
    else
        win = api.nvim_get_current_win()
        api.nvim_win_set_buf(win, bufnr)
    end

    local cursor = api.nvim_win_get_cursor(win)
    if cursor[1] ~= line
    then
        api.nvim_win_set_cursor(win, { line, cursor[2] })
        vim.cmd({ cmd = 'normal', bang = true, args = { 'zz' } })
    end
end

---@param bufnr integer
---@return nil | string
M.attach = function(bufnr)
    if vim.b[bufnr].synctex_attached
    then
        return 'already attached to bufnr: ' .. bufnr
    end

    local launch = get_config(bufnr).launch
    if not launch or vim.tbl_isempty(launch)
    then
        return 'no launch command configured for `'
            .. vim.bo[bufnr].filetype .. '`'
    end

    api.nvim_create_autocmd(
        'BufWritePost',
        {
            group = get_augroup(),
            buffer = bufnr,
            callback = function()
                local build = get_config(bufnr).build
                if build and not vim.tbl_isempty(build)
                then
                    fn.jobstart(parse_cmd(bufnr, build))
                end
            end,
        }
    )

    api.nvim_create_autocmd(
        { 'CursorHold', 'InsertLeave' },
        {
            group = get_augroup(),
            buffer = bufnr,
            callback = function() M.jump_forward(bufnr) end,
        }
    )

    vim.b[bufnr].synctex_attached = fn.jobstart(
        parse_cmd(bufnr, launch),
        { on_exit = function() vim.b[bufnr].synctex_attached = nil end }
    )
end

---@param bufnr integer
---@param no_kill boolean
M.detach = function(bufnr, no_kill)
    if no_kill
    then
        vim.b[bufnr].synctex_attached = nil
    else
        -- don't handle return value, we don't care if the job id is invalid
        fn.jobstop(vim.b[bufnr].synctex_attached or -1)
    end

    api.nvim_clear_autocmds({ buffer = bufnr, group = get_augroup() })
end

---@param conf? synctex.nvim-Config
M.setup = function(conf)
    Config = vim.tbl_deep_extend('force', Config, conf or {})

    api.nvim_create_user_command(
        'Synctex',
        function(opts)
            local bufnr = api.nvim_get_current_buf()
            local commands = {
                attach = function() return M.attach(bufnr) end,
                backward = function(line, fname)
                    line = tonumber(line)

                    if not line
                    then
                        return '`' .. line .. '` is not a number'
                    end

                    return M.jump_backward(line, fname)
                end,
                detach = function(no_kill) return M.detach(bufnr, no_kill) end,
                forward = function() return M.jump_forward(bufnr) end,
            }

            local cmd = table.remove(opts.fargs, 1) or 'attach'
            if not commands[cmd]
            then
                vim.notify(
                    'synctex.nvim: invalid subcommand `' .. cmd .. '`',
                    vim.log.levels.ERROR
                )
                return
            end

            local err = commands[cmd](unpack(opts.fargs))
            if err
            then
                vim.notify(
                    'synctex.nvim: ' .. cmd .. ': ' .. err,
                    vim.log.levels.ERROR
                )
            end
        end,
        {
            bar = true,
            complete = function()
                return { 'attach', 'backward', 'detach', 'forward' }
            end,
            desc = "TODO",
            nargs = '*',
        }
    )
end

return M
