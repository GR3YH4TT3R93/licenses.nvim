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

local fn = vim.fn

local core = require('licenses')
local util = require('licenses/util')

return function(bufnr, lnum, config)
    vim.validate({
        bufnr = { bufnr, 'number' },
        lnum = { lnum, 'number' },
        config = { config, 'table' },
        license = { config.license, { 'function', 'string' } },
    })

    local id = util.get_val(config.license)
    config = vim.tbl_map(function(v) return util.get_val(v, id) end, config)

    local cs = util.get_commentstring(bufnr)
    local lines = {}

    local header = util.get_file('header/' .. id .. '.txt')
    local full_text = util.get_file('text/' .. id .. '.txt')

    if not (header or full_text)
    then
        return 'License id `' .. id .. '` not found'
    end

    local email = config.email
    local holder = config.copyright_holder
    if id ~= 'Unlicense' and holder
    then
        lines = {
            cs:format(
            ---@diagnostic disable-next-line: param-type-mismatch
                util.format_spdx_copyright(os.date('%Y'), holder, email)
            ),
        }
    end

    vim.list_extend(
        lines, { cs:format('SPDX-License-Identifier: ' .. id) }
    )

    local path = header or config.fallback_to_full_text and full_text
    if config.use_license_header and path
    then
        table.insert(lines, '')
        vim.list_extend(
            lines, core.get_text(path, cs, config.vars, config.wrap_width)
        )
    end

    if not fn.getbufoneline(bufnr, lnum + 1):match('^%s*$')
    then
        table.insert(lines, '')
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    fn.appendbufline(bufnr, lnum, lines)

    if config.write_license_to_file
    then
        fn.mkdir('LICENSES', 'p')
        -- don't use the config, files in LICENSES should be unmodified
        core.write_license('LICENSES/' .. id .. '.txt', { license = id })
    end
end
