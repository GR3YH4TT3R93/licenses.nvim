local M = {}

local api = vim.api
local util = require('licenses/util')

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

M.get = function(bufnr, l_start, l_end)
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

M.update = function(bufnr, config)
    vim.validate({
        bufnr = { bufnr, 'number' },
        config = { config, 'table' },
        copyright_holder = { config.copyright_holder, { 'function', 'string' } },
    })


    local copyrights = M.get(bufnr)
    if not copyrights then return end

    local name = util.get_val(config.copyright_holder)
    local email = util.get_val(config.email)

    local cs = util.get_commentstring(bufnr)
    local year = os.date('%Y')
    local matched_spdx = false
    for _, cpy in ipairs(copyrights.spdx)
    do
        if cpy.name == name and (not cpy.email or cpy.email == email)
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
        vim.fn.appendbufline(
            bufnr,
            copyrights.spdx[1].lnum,
            cs:format(
            ---@diagnostic disable-next-line: param-type-mismatch
                util.format_spdx_copyright(os.date('%Y'), name, email)
            )
        )
    end

    for _, cpy in ipairs(copyrights.other)
    do
        if cpy.name == name
            and (not cpy.email or cpy.email == email)
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

return M
