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

local core = require('licenses')
local util = require('licenses/util')

return function(path, config)
    vim.validate({
        path = { path, 'string' },
        config = { config, 'table' },
        license = { config.license, { 'function', 'string' } },
    })

    local id = util.get_val(config.license)
    local license = util.get_file('text/' .. id .. '.txt')
    if not license
    then
        return 'License id `' .. id .. '` not found'
    end

    local ok, res = pcall(
        vim.fn.writefile,
        core.get_text(
            license,
            nil,
            config.vars,
            ---@diagnostic disable-next-line: param-type-mismatch
            util.get_val(config.wrap_width) or 0
        ),
        path
    )

    if not ok then return res --[[@as string]] end
end
