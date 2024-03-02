-- SPDX-FileCopyrightText: 2023 Ash <contact@ash.fail>
-- SPDX-License-Identifier: MIT

-- MIT License

--  Copyright (c) 2023 Ash contact@ash.fail

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

--- Dot repeat vim commands and lua functions.
---
---@tag dot_repeat.nvim

---@toc

---@mod usage
---@text Pressing a |.| repeats the last action performed, this works great for default
--- vim motions, but more effort needs to be put in to make it work with custom
--- commands or functions. This module provides a few helper functions for this.
---
--- It works by setting |'operatorfunc'| to our desired function and then executing
--- it with the |g@| operator.
---
--- For more information on how this works see:
--- https://gist.github.com/kylechui/a5c1258cd2d86755f97b10fc921315c3.

local M = {}

local api = vim.api
local fn = vim.fn

---@param callback function
---@param args? any[]
---@private
local set_callback = function(callback, args)
    if not args or vim.tbl_isempty(args)
    then
        _G.dot_repeat_callback = callback
    else
        _G.dot_repeat_callback = function()
            callback(unpack(args))
        end
    end

    vim.go.operatorfunc = 'v:lua.dot_repeat_callback'
end

--- Options passed to |dot_repeat-nvim.run| and |dot_repeat-nvim.set_dot|.
---@class dot_repeat-nvim.RunOpts
---@field count? number Count passed to |g@| (default: 0)
---@field motion? string Motion used with |g@| (default: `'l'`)
---@field reset_cursor? boolean
--- Reset cursor after calling `callback` (default: false)

--- Set the dot to `callback` and execute it immediately.
---
--- Example:~
---
--- The example bellow will run `my_fn('hello')` and set |.| to it. The next time we
--- press |.| the function will run with the same arguments and print `hello` again.
--- ```lua
---     local my_fn = function(msg)
---         print(msg)
---     end
---
---     require('dot_repeat').run(my_fn, { 'hello' })
--- ```
---@param callback function The function to use
---@param args? any[] Arguments to pass to `callback`
---@param opts? dot_repeat-nvim.RunOpts Additional options
---@see M.RunOpts
M.run = function(callback, args, opts)
    vim.validate({
        callback = { callback, 'function' },
        args = { args, 'table', true },
        opts = { opts, 'table', true },
    })

    opts = vim.tbl_deep_extend(
        'force',
        { count = 0, motion = 'l', reset_cursor = false },
        opts or {}
    )

    vim.validate({
        ['opts.count'] = { opts.count, 'number' },
        ['opts.motion'] = { opts.motion, 'string' },
        ['opts.reset_cursor'] = { opts.reset_cursor, 'boolean' },
    })

    set_callback(callback, args)

    local cursor = opts.reset_cursor and api.nvim_win_get_cursor(0)

    vim.cmd.normal({ args = { opts.count .. 'g@' .. opts.motion }, bang = true })

    -- going into normal mode changes cursor position in some cases
    if cursor then api.nvim_win_set_cursor(0, cursor) end
end

--- Takes the same arguments as |dot_repeat-nvim.run|, but doesn't execute
--- immediately and just sets the dot.
---@param callback function The function to use
---@param args? any[] Arguments to pass to `callback`
---@param opts? dot_repeat-nvim.RunOpts Additional options
---@see M.RunOpts
---@see M.run
M.set_dot = function(callback, args, opts)
    vim.validate({
        callback = { callback, 'function' },
        args = { args, 'table', true },
    })

    M.run(set_callback, { callback, args }, opts)
end

local repeat_cmd = function(opts)
    local cmd = table.remove(opts.fargs, 1)
    M.run(api.nvim_cmd, { { cmd = cmd, args = opts.fargs }, {} })
end

local repeat_cmd_count = function(opts)
    local cmd = table.remove(opts.fargs, 1)
    M.run(
        function()
            vim.cmd({ cmd = cmd, args = opts.fargs, count = vim.v.count })
        end,
        nil,
        -- opts.count seems to not work here so we use v:count
        { count = math.max(vim.v.count, 1) }
    )
end

local repeat_cmd_range = function(opts)
    local cmd = table.remove(opts.fargs, 1)

    if vim.regex(
            '^[vV'
            .. api.nvim_replace_termcodes('<C-V>', true, false, true)
            .. '].*'
        ):match_str(fn.mode())
    then
        opts.line1 = math.min(fn.line('.') --[[@as number]], fn.line('v'))
        opts.line2 = math.max(fn.line('.') --[[@as number]], fn.line('v'))
    end

    -- XXX: we could check for direction by comparing line1 to line('.')
    local amount = opts.line2 - opts.line1

    M.run(
        api.nvim_cmd,
        {
            { cmd = cmd, args = opts.fargs, range = { opts.line1, opts.line2 } },
            {},
        }
    )

    set_callback(
        function()
            local line1 = fn.line('.') --[[@as number]]
            local line2 = line1 + amount

            -- XXX: consider option to not change these
            api.nvim_buf_set_mark(0, '<', line1, 0, {})
            api.nvim_buf_set_mark(
                0, '>', line2, api.nvim_buf_get_mark(0, '>')[2], {}
            )

            vim.cmd({ cmd = cmd, args = opts.fargs, range = { line1, line2 } })
        end
    )
end

local commands = {
    normal = { 'DotRepeatCmd', repeat_cmd, { nargs = '+' } },
    count = { 'DotRepeatCmdCount', repeat_cmd_count, { nargs = '+', count = true } },
    range = { 'DotRepeatCmdRange', repeat_cmd_range, { nargs = '+', range = true } },
}

--- Options passed to |dot_repeat-nvim.mk_cmd|.
---
--- If the command needs to handle range or count, set `type` to `'range'` or `'count'`
--- respectively.
---
--- By default the mapping starts with `<CR>`, you can use `prefix` to change it to `:`
--- for example.
---@class dot_repeat-nvim.MkCmdOpts
---@field type? ('normal' | 'count' | 'range')
--- Command type (default: `'normal'`)
---@field prefix? string
--- Prefix to prepend the command with (default: `'<CR>'`)

--- Make a command, that can be used as right side of a mapping.
---
--- Take a user command and wrap it with a command that sets |.| to repeat it upon
--- execution. The output should be used as a right side of a mapping.
---
--- Example:~
--- ```lua
---     local dot_repeat = require('dot_repeat')
---
---     dot_repeat.mk_cmd('move .+1')
---     dot_repeat.mk_cmd('Commentary', { prefix = ':', type = 'range' })
--- ```
--- In the above example the first call returns `'<Cmd>DotRepeatCmd move .+1<CR>'`
--- and the second one `':DotRepeatCmdRange Commentary<CR>'`.
---
--- The commands will call the command passed to them and then set the |.| to it.
---
---@param cmd string User command
---@param opts? dot_repeat-nvim.MkCmdOpts Additional options
---@return string Generated mapping
---@see M.MkCmdOpts
M.mk_cmd = function(cmd, opts)
    vim.validate({ cmd = { cmd, 'string' }, opts = { opts, 'table', true } })

    opts = vim.tbl_extend(
        'force', { prefix = '<Cmd>', type = 'normal' }, opts or {}
    )

    vim.validate({
        ['opts.prefix'] = { opts.prefix, 'string' },
        ['opts.type'] = { opts.type, 'string' },
    })

    local dot_cmd = commands[opts.type]
    if not dot_cmd
    then
        error('invalid opts.type: `' .. opts.type .. '`')
    end

    if fn.exists(dot_cmd[1]) == 0
    then
        api.nvim_create_user_command(unpack(dot_cmd))
    end

    return string.format('%s%s %s<CR>', opts.prefix, dot_cmd[1], cmd)
end

return M
