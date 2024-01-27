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
