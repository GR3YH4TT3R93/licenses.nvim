local fn = vim.fn

require('copilot_cmp').setup()

local cmp = require('cmp')
local luasnip = require('luasnip')

-- cmp fucks up mapping of i and u
local fix_mapping = function() vim.keymap.set('n', 'u', 'i') end

local cmp_next = function(fb)
    if cmp.visible()
    then
        cmp.select_next_item()
    elseif luasnip.expand_or_jumpable()
    then
        luasnip.expand_or_jump()
    else
        fb()
    end
    fix_mapping()
end

local cmp_prev = function(fb)
    if cmp.visible()
    then
        cmp.select_prev_item()
    elseif luasnip.jumpable(-1)
    then
        luasnip.jump(-1)
    else
        fb()
    end
    fix_mapping()
end

---@param ... string|table
---@return table
local get_sources = function(...)
    return cmp.config.sources(
        vim.tbl_map(
            function(v)
                if type(v) == 'string'
                then
                    return { name = v, dup = 0 }
                else
                    v.dup = 0
                    return v
                end
            end,
            { ... }
        )
    )
end

local mapping_modes = { 'i', 'c', 's' }

cmp.setup({
    enabled = true,
    preselect = cmp.PreselectMode.None,
    mapping = {
        ['<C-l>'] = cmp.mapping.scroll_docs(-4),
        ['<C-s>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping(
            function(fb)
                if cmp.visible()
                then
                    cmp.confirm({ select = true })
                else
                    fb()
                end
            end,
            mapping_modes
        ),
        ['<CR>'] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = false,
        }),
        ['<C-d>'] = cmp.mapping(
            function(fb) if cmp.visible() then cmp.close() else fb() end end,
            mapping_modes
        ),
        ['<C-n>'] = cmp.mapping(cmp_next, mapping_modes),
        ['<C-e>'] = cmp.mapping(cmp_prev, mapping_modes),
        -- check https://github.com/hrsh7th/cmp-path/issues/61
        ['<C-c><C-t>'] = cmp.mapping.complete({
            config = { sources = get_sources('path') },
        }),
    },
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
            fix_mapping()
        end,
    },
    completion = { keyword_length = 1, autocomplete = { 'TextChanged' } },
    formatting = {
        format = function(_, item)
            if fn.mode() == 'c' then item.kind = nil end
            -- item.menu = '[' .. entry.source.name .. ']'
            return item
        end,
    },
    matching = { disallow_partial_matching = false },
    sorting = {
        -- https://github.com/hrsh7th/nvim-cmp/blob/main/lua/cmp/config/compare.lua
        comparators = {
            cmp.config.compare.offset,
            cmp.config.compare.exact,
            cmp.config.compare.score,
            cmp.config.compare.scope,
            -- https://github.com/lukas-reineke/cmp-under-comparator
            function(entry1, entry2)
                local _, entry1_under = entry1.completion_item.label:find '^_+'
                local _, entry2_under = entry2.completion_item.label:find '^_+'
                entry1_under = entry1_under or 0
                entry2_under = entry2_under or 0
                if entry1_under > entry2_under then
                    return false
                elseif entry1_under < entry2_under then
                    return true
                end
            end,
            cmp.config.compare.kind,
            cmp.config.compare.sort_text,
            cmp.config.compare.locality,
            cmp.config.compare.order,
        },
    },
    sources = get_sources(
        'copilot',
        'nvim_lsp',
        'nvim_lsp_signature_help',
        'luasnip',
        'treesitter',
        'path',
        'buffer'
    ),
    view = { entries = 'custom' },
    window = {
        completion = { border = 'single' },
        documentation = { border = 'single' },
    },
})

cmp.setup.cmdline(
    ':', {
        sources = get_sources(
            'path', { name = 'cmdline', option = { ignore_cmds = {} } }
        ),
    }
)

cmp.setup.cmdline({ '/', '?' }, { sources = get_sources('buffer') })
