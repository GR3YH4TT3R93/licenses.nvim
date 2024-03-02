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

local util = require('licenses/util')

return function(id, callback)
    vim.validate({
        id = { id, 'string' },
        callback = { callback, 'function', true },
    })

    callback = callback or function() end

    if fn.executable('curl') == 0
    then
        callback(
            'could not find `curl`, please make sure it is installed and in path'
        )
        return
    end

    local url = 'https://spdx.org/licenses/' .. id .. '.json'
    require('licenses/job').run({
        cmd = { 'curl', '-isS', url },
        on_stdout = true,
        on_stderr = true,
        on_failure = vim.schedule_wrap(
            function(_, job) callback(vim.trim(job:stderr())) end
        ),
        on_success = vim.schedule_wrap(
            function(job)
                local lines = vim.split(job:stdout(), '\n')
                local status = tonumber(util.split_words(lines[1])[2])

                if status ~= 200
                then
                    callback(string.format('curl: %s returned %s', url, status))
                    return
                end

                local i = 1
                while lines[i] and lines[i] ~= '' do i = i + 1 end

                local ok, json = pcall(
                    vim.fn.json_decode, vim.list_slice(lines, i + 1)
                )
                if not ok
                then
                    callback(json)
                    return
                end
                ---@cast json table

                local cache = util.get_cache()
                fn.mkdir(cache .. 'text', 'p')
                local f, msg = io.open(cache .. 'text/' .. id .. '.txt', 'w')
                assert(f, msg)
                f:write(json.standardLicenseTemplate)

                local header = json.standardLicenseHeaderTemplate
                if header
                then
                    fn.mkdir(cache .. 'header', 'p')
                    f, msg = io.open(cache .. 'header/' .. id .. '.txt', 'w')
                    assert(f, msg)
                    f:write(header)
                end

                vim.notify('licenses.nvim: Succsesfully downloaded ' .. id)
            end
        ),
    })
end
