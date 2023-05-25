-- SPDX-FileCopyrightText: 2023 reggie <contact<at>reggie<dot>re>
-- SPDX-License-Identifier: MIT

-- MIT License

--  Copyright (c) 2023 reggie contact<at>reggie<dot>re

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

local M = {}

local api = vim.api
local fn = vim.fn

---@param config Config
M.add_copyright_var = function(config)
    if config.vars.copyright then return end

    config.vars.copyright = function(_, original)
        if not (config.copyright_holder or config.email)
        then
            return original
        end

        local copyright = os.date('%Y')
            .. (config.copyright_holder and ' ' .. config.copyright_holder or '')
            .. (config.email and ' ' .. config.email or '')

        if original:match('^[Cc]opyright')
        then
            return 'Copyright (c) ' .. copyright
        end
        return copyright
    end
end

---@param bufnr? integer
---@param name string
---@return any?
M.b = function(bufnr, name)
    local ok, res = pcall(api.nvim_buf_get_var, bufnr, name)
    return ok and res or vim.g[name]
end

---@param bufnr integer
---@param name string
---@return any?
M.bo = function(bufnr, name)
    local ok, res = pcall(api.nvim_buf_get_option, bufnr, name)
    return ok and res or nil
end

---@param msg any
M.err = function(msg)
    vim.notify('licenses.nvim: ' .. msg, vim.log.levels.ERROR)
end

---@return string
M.get_cache = function()
    return fn.stdpath('cache') .. '/licenses.nvim/'
end

---@param path string
---@return string
M.get_file = function(path)
    local cache = M.get_cache()
    return api.nvim_get_runtime_file('*licenses/' .. path, false)[1]
        or fn.filereadable(cache .. path) == 1 and cache .. path
end

---@generic T,U
---@param v T | fun(...: U): T
---@param ... U
---@return T
M.get_val = function(v, ...)
    if type(v) == 'function' then return ... and v(...) or v() end
    return v
end

---@param arglead string
---@param cmdline string
---@return integer
M.nargs = function(arglead, cmdline)
    local nargs = #M.split_words(cmdline)
    if arglead:match('^%s*$') then nargs = nargs + 1 end
    return nargs
end

---@param text string
---@return string[]
M.split_words = function(text)
    return vim.split(text, '%s+', { trimempty = true })
end

---@param callback function
---@param ... any
---@return any?
M.try = function(callback, ...)
    local ok, res
    if ...
    then
        ok, res = pcall(callback, ...)
    else
        ok, res = pcall(callback)
    end

    if not ok
    then
        M.err(res)
    else
        return res
    end
end

return M
