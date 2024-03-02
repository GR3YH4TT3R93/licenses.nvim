---@mod luasnip luasnip snippets
---@text licenses.nvim provides a couple of snippets for
--- https://github.com/L3MON4D3/LuaSnip.
---
--- These snippets are triggered with:
---     • {license} Inserts license header on current line
---     • {SPDX} inserts SPDX copyright and license tags
---
--- If you have LuaSnip installed you can enable them with:
--- ```lua
---     luasnip.loaders.from_lua').load()
--- ```
---@see luasnip-loaders-lua for more options

local api = vim.api

local licenses = require('licenses')
local util = require('licenses/util')

local get_file = function(id, fallback_to_full_text)
    local file = util.get_file('header/' .. id .. '.txt')
    if not file and util.get_val(fallback_to_full_text, id)
    then
        file = util.get_file('text/' .. id .. '.txt')
    end
    return file
end

local condition = function()
    local config = licenses.get_config(api.nvim_get_current_buf())
    return get_file(config.license, config.fallback_to_full_text)
end

return {
    s(
        {
            trig = 'license',
            name = 'licenses.nvim - Insert Header',
            dscr = 'Insert license header on current line.',
            condition = condition,
            show_condition = condition,
        },
        f(function()
            local bufnr = api.nvim_get_current_buf()
            local config = licenses.get_config(bufnr)
            local file = get_file(
                config.license,
                config.fallback_to_full_text
            )
            if not file then return {} end

            return licenses.get_text(
                file,
                util.get_commentstring(bufnr),
                config.vars,
                ---@diagnostic disable-next-line: param-type-mismatch
                util.get_val(config.wrap_width, config.license)
            )
        end)
    ),
    s(
        {
            trig = 'SPDX',
            name = 'licenses.nvim - SPDX Tags',
            dscr = 'Insert SPDX tags on current line.',
        },
        f(function()
            local bufnr = api.nvim_get_current_buf()
            local config = licenses.get_config(bufnr)
            local cs = util.get_commentstring(bufnr)
            local id = config.license
            local lines = {}
            if config.license ~= 'Unlicense'
            then
                lines = {
                    cs:format(
                        util.format_spdx_copyright(
                            os.date('%Y') --[[@as string]],
                            util.get_val(config.copyright_holder, id) --[[@as string]],
                            util.get_val(config.email, id) --[[@as string]]
                        )
                    ),
                }
            end

            table.insert(lines, cs:format('SPDX-License-Identifier: ' .. id))

            return lines
        end)
    ),
}
