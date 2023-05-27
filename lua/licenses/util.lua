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

---@param msg any
M.err = function(msg)
    vim.notify('licenses.nvim: ' .. msg, vim.log.levels.ERROR)
end

---@param year string
---@param name string
---@param email? string
---@return string
M.format_spdx_copyright = function(year, name, email)
    return string.format(
        'SPDX-FileCopyrightText: %s %s%s',
        year,
        name,
        email and ' <' .. email .. '>' or ''
    )
end

---@return string
M.get_cache = function()
    return fn.stdpath('cache') .. '/licenses.nvim/'
end

---@param bufnr integer
---@return string
M.get_commentstring = function(bufnr)
    local cs = api.nvim_buf_get_option(bufnr, 'commentstring')
    if not cs:match('%%s') then cs = cs .. '%s' end
    return cs
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

---@param text string
---@return string[]
M.split_words = function(text)
    return vim.split(text, '%s+', { trimempty = true })
end

return M
