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

-- TODO: replace mailing list with todo
-- TODO: telescope

--- Insert and write license headers and/or files.
---
---@tag licenses.nvim LicensesNvim

---@toc

---@mod intro getting started
---@text Licenses.nvim provides user commands to fetch, insert and write SPDX licenses.
---
--- To get started add the code below to your init.lua file:
--- ```lua
---     require('licenses').setup({
---         copyright_holder = 'your name',
---         email = 'example@email.com',
---         license = 'MIT'
---     })
--- ```
--- Setup takes a single table as an argument, which is used to override the
--- default configuration. The most important keys are the ones shown above, for
--- all possible options see |licenses-nvim.Config|.
---
--- Running setup is not necessary to set the configuration and can be set directly.
--- The following is the default configuration and could be set like this:
--- ```lua
---     require('licenses').config = {
---         fallback_to_full_text = function(id)
---             return vim.tbl_contains({ 'BSD-2-Clause', 'MIT', 'Unlicense' }, id)
---         end,
---         use_license_header = true,
---         wrap_width = function() return vim.bo.textwidth end,
---         vars = {},
---         write_license_to_file = false,
---     }
--- ```
--- This can be useful if you want to overwrite all the defaults or you don't want
--- setup to create user commands and only wish to use the underlying lua api.
---
--- The last option for configuring licenses.nvim is via global or buffer variables,
--- g:licenses_nvim_config and b:licenses_nvim_config respectively.
---
--- Additionally, for convenience, the following keys have their own variables:
--- {copyright_holder}, {email} and {license}. The names of these variables are
--- 'licenses_nvim_{var}'. For example to set different license and holder for just
--- one buffer you can do:
--- ```vim
---     let b:licenses_nvim_license = "BSD-2-Clause"
---     let b:licenses_nvim_copyright_holder = "Joe"
--- ```
--- After we are done with our setup we can use |:LicenseInsert| to add our chosen
--- license to the currently open buffer. There are a few common licenses included,
--- but you can use |:LicenseFetch| to download additional ones.
---
---@see M-license-files for instructions on adding your own licenses
--- M-user-commands for all available commands and their usage
--- M-lua for lua api

---@mod license-files
---@text This plugin looks for license files in 'runtimepath' under directory named
--- licenses. This directory contains two subdirectories: text and header. Both
--- use the same syntax, but text contains full license text and header contains
--- license's standard file header (if any).
---
--- To add your own license file you will have to create the licenses directory
--- anywhere in 'runtimepath', e.g. ~/.config/nvim/licenses.
---
--- Let's say we want to add a license called MYLICENSE. It will be located at
--- ~/.config/nvim/licenses/text/MYLICENSE.txt. This file should contain the entire
--- text of the license so we would just go ahead and paste it.
---
--- This license might contain a copyright notice, if we take a look at MIT license
--- it contains "Copyright (c) <year> <copyright holders>". We would want to
--- replace this part with the following:
--- ```
---     <<var;name="copyright";original="Copyright (c) <year> <copyright holders>";>>
--- ```
--- For every variable like this we check {vars} in |licenses-nvim.Config| for one
--- with the same name and substitute it with either the found value or original.
---
--- You may add any additional variables of your choosing and as long they match
--- this lua pattern `<<var;name="(.-)";original="(.-)";.->>` (see |luaref-patterns|)
--- they should be interpreted and replaced.
---
--- This is the same syntax that SPDX uses in its json license files, which is
--- where we fetch license texts from. For an example see licenses/text/MIT.txt
--- in this plugin's directory or the standardLicenseTemplate field in
--- https://spdx.org/licenses/MIT.json.

---@mod user-commands

--- Running |licenses-nvim.setup| will create the following user commands. Their
--- behavior can be modified with |licenses-nvim.Config|.

---@signature :LicenseInsert :LicenseInsert [{id}]
---@text Insert license matching the {id} on top of the active buffer. If no {id} was
--- supplied, use the default license from |licenses-nvim.Config|.
---
--- A simple check will be performed before inserting to see if the file already
--- contains a copyright notice, if it does then nothing is inserted and error is
--- shown. This behavior can be overriden with !, i.e. `:LicenseInsert!`.
---@see M.insert_header for the underlying lua function

---@signature :LicenseFetch :LicenseFetch {id}
---@text Fetch license text and header from https://spdx.org/licenses/{id}.json and save
--- them to `stdpath("cache")`.
---
--- NOTE: Depends on the `curl` command.
---@see M.fetch_license for the underlying lua function

---@signature :LicenseUpdate
---@text TODO: add description

---@signature :LicenseWrite :LicenseWrite {path} [{id}]
---@text Write text of a license with {id} to {path}. If no {id} was specified, then
--- uses the default one from |licenses-nvim.Config|.
---@see M.write_license for the underlying lua function

---@mod lua lua api
--- Aside from above mentioned user commads, licenses.nvim exposes several Lua
--- functions.
---
--- All examples in this section assume, that `local licenses = require('licenses')`
--- is true.
---
--- NOTE: This might slightly change in the future.

local M = {}

local api = vim.api
local fn = vim.fn
local util = require('licenses/util')

---@alias LicenseVars (table<string, string | fun(id: string, original: string): string>)
---@alias FnBool (boolean | fun(id: string): boolean)
---@alias FnInt (integer | fun(id: string): integer)
---@alias FnString (string | fun(id: string): string)
---@private

--- Configuration, that can be passed to |licenses-nvim.setup|, accessed directly,
--- or set with g:licenses_nvim_config or b:licenses_nvim_config. Global and
--- buffer variables always take precedence over config set in lua.
---
--- Additionally {copyright_holder}, {email} and {license} can also
--- be set via variables, the names of these variables are 'licenses_nvim_{var}',
--- e.g. 'licenses_nvim_copyright_holder'.
---
--- NOTE: These take precedence over the config. Even if b:licenses_nvim_config
--- is set, g:licenses_nvim_license would be used instead of
--- b:licenses_nvim_config.license.
---
--- `FnBool` is a value, that can be either a boolean or a function, that takes id
--- of a license and returns a boolean. `FnString` is the same, but returns a string.
--- For example, the default `fallback_to_full_text` is:
--- ```lua
---     function(id)
---         return vim.tbl_contains({ 'BSD-2-Clause', 'MIT', 'Unlicense' }, id)
---     end
--- ```
--- `LicenseVars` is a dictionary of license variables. To see how these variables
--- are used check out |licenses-nvim-license-files|.
---
--- The dictionary's keys are variable names and their values can either be a string
--- or a function that takes two parameters: id of the license and original text of
--- the variable so you can format the variable differently based on some custom
--- logic.
---
--- The values of this table should match the following signature:
--- ```
---     string | fun(id: string, original: string): string
--- ```
--- Although there are no variables defined by default, |licenses-nvim.insert_header|
--- will add the copyright variable if there already isn't one. A simplified
--- example of this variable would be:
--- ```lua
---     function()
---         return os.date('%Y') .. ' my name email@example.com'
---     end
--- ```
--- Sometimes it is desirable to skip certain lines like shebangs on top of files
--- and insert the license below them. The field {skip_lines} can be supplied with
--- patterns (see |luaref-patterns|) to match against lines and |:LicenseInsert| will
--- place license above the first one that does NOT match. For example, to skip
--- shebangs you would:
--- ```lua
---     licenses.setup({
---         -- rest of the config
---         skip_lines = { '^#!' }
---     })
--- ```
---@class Config
---@field copyright_holder FnString Name of copyright holder (nil)
---@field email FnString Copyright holder's email (nil)
---@field fallback_to_full_text FnBool
--- Insert full text when there is no header
--- (evaluates to true if id == 'BSD-2-Clause', 'MIT' or 'Unlicense')
---@field license (string | fun(): string) Default license id (nil)
---@field remember_previous_id FnBool
--- If true |licenses-nvim.insert_header| will set b:licenses_nvim_license to
--- {config.license} making it the default for specified buffer (nil)
---@field skip_lines string[]
--- List of patterns to skip if at the top of buffer (nil)
---@field use_license_header FnBool
--- Insert license header, only inserts SPDX tags if false (true)
---@field vars LicenseVars Replacements for license variables ({})
---@field wrap_width FnInt Wrap longer lines, 0 to disable ('textwidth')
---@field write_license_to_file FnBool
--- After inserting a header write specified license to
--- ./LICENSES, see: https://reuse.software/spec/#license-files (false)
M.config = {
    fallback_to_full_text = function(id)
        return vim.tbl_contains({ 'BSD-2-Clause', 'MIT', 'Unlicense' }, id)
    end,
    use_license_header = true,
    wrap_width = function() return vim.bo.textwidth end,
    vars = {},
    write_license_to_file = false,
}

--- Get configuration for specified {bufnr}. Looks through default config,
--- global and buffer variables, and {overrides} to get the final config. If
--- {bufnr} is nil, then buffer variables are ignored.
---
--- To get a configuration, that has all the default values but a different
--- license id we could do:
--- ```lua
---     licenses.get_config(vim.api.nvim_get_current_buf(), { license = 'MIT' })
--- ```
---@param bufnr? integer Buffer handle
---@param overrides? Config Optional overrides
---@return Config
M.get_config = function(bufnr, overrides)
    local c = vim.tbl_deep_extend(
        'keep',
        overrides or {},
        util.b(bufnr, 'licenses_nvim_config') or {},
        M.config or {}
    )

    for _, key in ipairs({ 'license', 'copyright_holder', 'email' })
    do
        c[key] = util.b(bufnr, 'licenses_nvim_' .. key) or c[key]
    end

    if bufnr and c.remember_previous_id and c.license
    then
        api.nvim_buf_set_var(bufnr, 'licenses_nvim_license', c.license)
    end

    return c
end

--- Table structure returned by |licenses-nvim.get_copyright_info|.
---@class CpyInfo
---@field name string Name of copyright holder
---@field email string Holder's email
---@field years string[]
--- Array with one or two years in case copyright has years separated with
--- dash, e.g. 2020-2023 turns into `{ '2020', '2023' }`
---@field lnum integer Line number where notice is located

---@param text string
---@return CpyInfo
---@private
local parse_copyright_text = function(text)
    text = vim.trim(text):gsub('^[Cc]opyright%s+', '')
    local year1, year2, name, email
    for _, part in ipairs(util.split_words(text))
    do
        if not email and (part:match('^%S+@%S+$') or part:match('^%S+<at>%S+$'))
        then
            email = part:gsub('^<', ''):gsub('>$', '')
        elseif not year1 and part:match('^%d%d+%-?%d%d*$')
        then
            -- %d%d+ matches >=2 digits, 2 is not a year, but 02 might be 2002
            year1 = part:match('^%d%d+')
            year2 = part:match('%-(%d%d+)$')
        else
            name = (name and name .. ' ' or '') .. part
        end
    end

    return { name = name, email = email, years = { year1, year2 } }
end

-- XXX: https://wiki.debian.org/CopyrightReviewTools#Command-line_tools_in_Debian
-- TODO: multiple licenses
-- TODO: https://reuse.software/faq/#custom-license

--- Primitive function to get copyright information.
---
--- NOTE: this is mostly used to check if file already contains a copyright notice
--- to avoid inserting a second one, for more reliable license/copyright detection
--- see: https://wiki.debian.org/CopyrightReviewTools.
---
--- Looks for SPDX tags (see: https://spdx.github.io/spdx-spec/v2.3/file-tags)
--- and also commented lines starting with "Copyright". Only looks at lines between
--- {l_start} and {l_end}, by default 0 - 100, to avoid checking the entire buffer.
---
--- Returns nil if no info found, otherwise returns a table containing two arrays
--- with copyright information. Array named {spdx} contains copyrights defined with
--- SPDX tags and {other} contains all other copyrights.
---@param bufnr integer Buffer handle (0)
---@param l_start? integer First line where to look (0)
---@param l_end? integer Last line ({l_start} + 100)
---@return ({ other: CpyInfo[], spdx: CpyInfo[] } | nil)
---@see M.CpyInfo for the copyright's structure
M.get_copyright_info = function(bufnr, l_start, l_end)
    vim.validate({
        bufnr = { bufnr, 'number' },
        l_start = { l_start, 'number', true },
        l_end = { l_end, 'number', true },
    })

    l_start = l_start or 0
    l_end = l_end or l_start + 100

    local lines = api.nvim_buf_get_lines(bufnr, l_start, l_end, false)
    local cs_pat = '^%s*' .. vim.pesc(
        util.get_commentstring(bufnr):match('^(.*)%%s') or ''
    ):gsub('%s+$', '%%s*')
    local spdx, other = {}, {}
    for i, line in ipairs(lines)
    do
        -- stop checking if line not commented or not empty
        if not line:match('^%s*$') and not line:match(cs_pat) then break end

        local copyright = line:match(cs_pat .. 'SPDX%-FileCopyrightText:%s*(.+)')
        if copyright
        then
            local info = parse_copyright_text(
                copyright:gsub('^%s*[Cc]opyright%s+', '')
            )
            info.lnum = l_start + i - 1
            table.insert(spdx, info)
        else
            local n
            line, n = line:gsub(cs_pat .. '[Cc]opyright%s+', '')
            if n == 1
            then
                line = line:gsub('^%(?[Cc©]%)?%s+', '')
                local info = parse_copyright_text(line)
                info.lnum = l_start + i - 1
                table.insert(other, info)
            end
        end
    end

    if #spdx == 0 and #other == 0 then return nil end
    return { spdx = spdx, other = other }
end

--- Get text from license file at {path} and replace variables with {vars}.
--- Optionally pass {cs} to format every line with, see 'commentstring'.
---
--- Example:~
--- ```lua
---     licenses.get_text('MIT.txt', '# %s', { software = 'example' })
--- ```
---@param path string Path to license file
---@param cs? string Commentstring, if any
---@param vars? LicenseVars Replacements for license variables
---@param wrap_width? integer Wrap lines longer than this
---@return table License text as array of lines
M.get_text = function(path, cs, vars, wrap_width)
    vim.validate({
        path = { path, 'string' },
        cs = { cs, 'string', true },
        vars = { vars, 'table', true },
        wrap_width = { wrap_width, 'number', true },
    })

    vars = vars or {}
    -- adjust wrap width
    wrap_width = (wrap_width or 0) - (cs and #cs:format('') or 0)

    local id = fn.fnamemodify(path, ':t:r')
    -- store empty lines in a separate list to avoid trailing newlines
    local empty_lines, lines = {}, {}
    local insert = function(s)
        if s:match('^%s*$')
        then
            table.insert(empty_lines, '')
        else
            vim.list_extend(lines, empty_lines)
            empty_lines = {}
            table.insert(lines, ((cs and cs:format(s) or s):gsub(' *$', '')))
        end
    end

    for line in io.lines(path)
    do
        line = line:gsub(
            '<<var;name="(.-)";original="(.-)";.->>',
            function(name, original)
                local v = vars[name]
                return v and util.get_val(v, id, original) or original
            end
        ):gsub('<<beginOptional>>', ''):gsub('<<endOptional>>', '')

        if wrap_width ~= 0 and #line > wrap_width
        then
            local words = util.split_words(line)
            line = table.remove(words, 1)
            for _, word in ipairs(words)
            do
                local lwidth = #line
                if lwidth == 0 or lwidth + #word < wrap_width
                then
                    line = line .. ' ' .. word
                else
                    insert(line)
                    line = word
                end
            end
        end

        insert(line)
    end

    return lines
end

-- XXX: wget support
-- TODO: update index.txt for completion
--- Fetch license text and header from https://spdx.org/licenses/{id}.json and save
--- them to `stdpath("cache")`.
---
--- NOTE: Depends on the `curl` command.
---@param id string SPDX License Identifier
M.fetch_license = function(id)
    vim.validate({ id = { id, 'string' } })
    if fn.executable('curl') == 0
    then
        util.err(
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
            function(_, job) util.err(vim.trim(job:stderr())) end
        ),
        on_success = vim.schedule_wrap(
            function(job)
                local lines = vim.split(job:stdout(), '\n')
                local status = tonumber(util.split_words(lines[1])[2])

                if status ~= 200
                then
                    util.err(string.format('curl: %s returned %s', url, status))
                    return
                end

                local i = 1
                while lines[i] and lines[i] ~= '' do i = i + 1 end

                local json = util.try(
                    vim.fn.json_decode, vim.list_slice(lines, i + 1)
                )
                if not json then return end

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

--- Write text of license with {id} to a file at {path}. If the file already exists
--- it will get overwritten. Can be optionally supplied with config. If omitted
--- then resulting text should equal the original.
---
--- Example:
--- ```lua
---     licenses.write_license(
---         './LICENSE.txt',
---         licenses.get_config(vim.api.nvim_get_current_buf())
---     )
--- ```
---@param path string Relative path to output file
---@param config Config Configuration, NOTE: license key is required
---@see M.get_config
M.write_license = function(path, config)
    vim.validate({
        path = { path, 'string' },
        config = { config, 'table' },
        license = { config.license, { 'function', 'string' } },
    })

    local id = util.get_val(config.license)
    local license = util.get_file('text/' .. id .. '.txt')
    if not license
    then
        util.err('License id `' .. id .. '` not found')
        return
    end

    util.try(
        fn.writefile,
        M.get_text(
            license,
            nil,
            config.vars,
            ---@diagnostic disable-next-line: param-type-mismatch
            util.get_val(config.wrap_width) or 0
        ),
        path
    )
end

--- TODO: desc
---@param bufnr integer Buffer handle
---@param config Config Configuration, NOTE: copyright_holder key is required
M.update_copyright = function(bufnr, config)
    vim.validate({
        bufnr = { bufnr, 'number' },
        config = { config, 'table' },
        copyright_holder = { config.copyright_holder, 'string' },
    })


    local copyrights = M.get_copyright_info(bufnr)
    if not copyrights then return end

    local cs = util.get_commentstring(bufnr)
    local year = os.date('%Y')
    local matched_spdx = false
    for _, cpy in ipairs(copyrights.spdx)
    do
        if cpy.name == config.copyright_holder
            and (not cpy.email or cpy.email == config.email)
        then
            matched_spdx = true
            if year ~= cpy.years[#cpy.years]
            then
                api.nvim_buf_set_lines(
                    bufnr, cpy.lnum, cpy.lnum + 1, false,
                    {
                        cs:format(
                            util.format_spdx_copyright(
                                cpy.years[1] .. '-' .. year,
                                cpy.name,
                                cpy.email
                            )
                        ),
                    }
                )
            end
        end
    end

    if not matched_spdx and #copyrights.spdx ~= 0
    then
        fn.appendbufline(
            bufnr,
            copyrights.spdx[1].lnum,
            cs:format(
                util.format_spdx_copyright(
                ---@diagnostic disable-next-line: param-type-mismatch
                    os.date('%Y'), config.copyright_holder, config.email
                )
            )
        )
    end

    for _, cpy in ipairs(copyrights.other)
    do
        if cpy.name == config.copyright_holder
            and (not cpy.email or cpy.email == config.email)
            and year ~= cpy.years[#cpy.years]
        then
            local line = api.nvim_buf_get_lines(
                bufnr, cpy.lnum, cpy.lnum + 1, false
            )[1]
            if #cpy.years == 1
            then
                line = line:gsub(cpy.years[1], cpy.years[1] .. '-' .. year, 1)
            else
                line = line:gsub('%-' .. cpy.years[2], '-' .. year, 1)
            end
            api.nvim_buf_set_lines(
                bufnr, cpy.lnum, cpy.lnum + 1, false, { line }
            )
        end
    end
end

-- XXX: more complex licenses, see: https://reuse.software/faq/#multi-licensing

--- Insert a license header on {lnum} of {bufnr}.
---
--- Example:
--- ```lua
---     local bufnr = vim.api.nvim_get_current_buf()
---     licenses.insert_header(bufnr, 0, licenses.get_config(bufnr))
--- ```
---@param bufnr integer Buffer handle
---@param lnum integer Line number, zero-indexed
---@param config Config Configuration, NOTE: license key is required
---@see M.get_config
M.insert_header = function(bufnr, lnum, config)
    vim.validate({
        bufnr = { bufnr, 'number' },
        lnum = { lnum, 'number' },
        config = { config, 'table' },
        license = { config.license, { 'function', 'string' } },
    })

    local id = util.get_val(config.license)
    config = vim.tbl_map(function(v) return util.get_val(v, id) end, config)
    util.add_copyright_var(config)

    local cs = util.get_commentstring(bufnr)
    local lines = {}

    local header = util.get_file('header/' .. id .. '.txt')
    local full_text = util.get_file('text/' .. id .. '.txt')

    if not (header or full_text)
    then
        util.err('License id `' .. id .. '` not found')
        return
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
        lines, { cs:format('SPDX-License-Identifier: ' .. id), '' }
    )

    local path = header or config.fallback_to_full_text and full_text
    if config.use_license_header and path
    then
        vim.list_extend(
            lines, M.get_text(path, cs, config.vars, config.wrap_width)
        )

        if not fn.getbufoneline(bufnr, lnum + 1):match('^%s*$')
        then
            table.insert(lines, '')
        end
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    fn.appendbufline(bufnr, lnum, lines)

    if config.write_license_to_file
    then
        fn.mkdir('LICENSES', 'p')
        -- don't use the config, files in LICENSES should be unmodified
        M.write_license('LICENSES/' .. id .. '.txt', { license = id })
    end
end

---@param list string[]
---@return string[]
---@private
local filter_license_files = function(list)
    list = fn.map(
        list,
        function(_, v) return fn.fnamemodify(v, ':t:r') end
    )
    table.sort(list)
    return fn.uniq(list)
end

--- Setup user commands and apply {overrides} to the configuration.
---@param overrides? Config Configuration to override the defaults
---@see M-user-commands for commands that get created
--- M.Config for {overrides} syntax
--- M-intro for example usage and how to get started
M.setup = function(overrides)
    M.config = vim.tbl_deep_extend('force', M.config, overrides or {})

    api.nvim_create_user_command(
        'LicenseInsert',
        function(opts)
            local bufnr = api.nvim_get_current_buf()

            if not opts.bang and M.get_copyright_info(bufnr)
            then
                util.err(
                    'It looks like this buffer already contains licensing information, use ! to insert anyway'
                )
                return
            end

            local config = M.get_config(bufnr, { license = opts.fargs[1] })
            local lnum = 0
            local last_lnum = fn.line('$')
            while fn.indexof(
                    config.skip_lines or {},
                    function(_, v)
                        return fn.getline(lnum + 1):match(v) and true
                    end
                ) ~= -1 and lnum < last_lnum
            do
                lnum = lnum + 1
                assert(
                    lnum < 50,
                    'config.skip_lines resulted in >=50 lines being skipped, assuming infinite loop'
                )
            end

            if lnum ~= 0
            then
                fn.appendbufline(api.nvim_get_current_buf(), lnum, '')
                lnum = lnum + 1
            end
            M.insert_header(bufnr, lnum, config)
        end,
        {
            bang = true,
            bar = true,
            complete = function(_, cmdline)
                if util.nargs(cmdline) ~= 2 then return end

                local cache = util.get_cache()
                return filter_license_files(
                    vim.list_extend(
                        vim.list_extend(
                            api.nvim_get_runtime_file('*licenses/header/*', true),
                            api.nvim_get_runtime_file('*licenses/text/*', true)
                        ),
                        ---@diagnostic disable-next-line: param-type-mismatch
                        fn.globpath(
                        ---@diagnostic disable-next-line: param-type-mismatch
                            cache .. 'header,' .. cache .. 'text', '*', 0, 1
                        )
                    )
                )
            end,
            desc = 'Insert license header on top of current buffer.',
            nargs = '?',
        }
    )

    api.nvim_create_user_command(
        'LicenseFetch',
        function(opts) M.fetch_license(opts.fargs[1]) end,
        {
            bar = true,
            complete = function(_, cmdline)
                if util.nargs(cmdline) ~= 2 then return end
                return fn.readfile(util.get_file('index.txt'))
            end,
            desc = 'Fetch license from https://spdx.org/licenses.',
            nargs = 1,
        }
    )

    api.nvim_create_user_command(
        'LicenseUpdate',
        function()
            local bufnr = api.nvim_get_current_buf()
            M.update_copyright(bufnr, M.get_config(bufnr))
        end,
        { bar = true, desc = 'Update copyright notice years.', nargs = 0 }
    )

    api.nvim_create_user_command(
        'LicenseWrite',
        function(opts)
            local path = opts.fargs[1]
            if not opts.bang and fn.filereadable(path) == 1
            then
                util.err(
                    'file `' .. path .. '` already exists, use ! to overwrite'
                )
                return
            end

            local bufnr = api.nvim_get_current_buf()
            local config = M.get_config(bufnr, { license = opts.fargs[2] })
            util.add_copyright_var(config)

            M.write_license(path, config)
        end,
        {
            bang = true,
            bar = true,
            complete = function(arglead, cmdline)
                local nargs = util.nargs(cmdline)
                if nargs == 2
                then
                    ---@diagnostic disable-next-line: param-type-mismatch
                    return fn.glob(fn.fnameescape(arglead) .. '*', 0, 1) --[=[@as string[]]=]
                elseif nargs == 3
                then
                    return filter_license_files(vim.list_extend(
                        api.nvim_get_runtime_file('*licenses/text/*', true),
                        ---@diagnostic disable-next-line: param-type-mismatch
                        fn.globpath(util.get_cache() .. 'text', '*', 0, 1)
                    ))
                end
            end
            ,
            desc = 'Write license text to a file.',
            nargs = '+',
        }
    )
end

return M
