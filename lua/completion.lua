local api = vim.api
local cmd = vim.cmd
local fn = vim.fn
local lsp = vim.lsp

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
            'path', { name = 'cmdline', option = { ignore_cmds = { "!" } } }
        ),
    }
)

cmp.setup.cmdline({ '/', '?' }, { sources = get_sources('buffer') })

local cc = (tonumber(vim.o.cc) or 80) - 1
local enable, disable = { enable = true }, { enable = false }
local servers = {
    'clangd',
    'denols',
    'ltex',
    {
        'lua_ls',
        {
            settings = {
                Lua = {
                    diagnostics = { globals = { 'vim' } },
                    format = {
                        quote_style = 'single',
                        enable = true,
                        defaultConfig = {
                            max_line_length = tostring(cc),
                            trailing_table_separator = 'smart',
                            align_function_params = 'false',
                            align_continuous_assign_statement = 'false',
                            align_continuous_rect_table_field = 'false',
                            align_array_table = 'false',
                            break_all_list_when_line_exceed = 'true',
                            auto_collapse_lines = 'true',
                        },
                    },
                    hint = disable,
                    -- hint = enable,
                    runtime = { version = 'LuaJIT', path = vim.o.path },
                    telemetry = disable,
                    workspace = { library = api.nvim_get_runtime_file('', true) },
                },
            },
        },
    },
    {
        'pylsp',
        {
            settings = {
                pylsp = {
                    plugins = {
                        black = { enabled = true, line_length = cc },
                        isort = { enabled = true },
                        mypy = {
                            enabled = true,
                            live_mode = true,
                            report_progress = true,
                        },
                        pylint = {
                            args = {
                                '--enable-all-extensions',
                                '--good-names-rgxs=[a-z]',
                                '--good-names=ex,Run,_',
                                '--include-naming-hint=True',
                                '--max-line-length=' .. cc,
                                '--reports=True',
                            },
                            enabled = true,
                        },
                        ruff = { enabled = true },
                    },
                },
            },
        },
    },
    {
        'rust_analyzer',
        {
            settings = {
                ['rust-analyzer'] = {
                    checkOnSave = { command = 'clippy' },
                    completion = { privateEditable = enable },
                    hover = { actions = { references = enable, run = disable } },
                    rustfmt = {
                        extraArgs = {
                            '--config',
                            'max_width=' .. cc .. ',newline_style=Unix',
                        },
                    },
                },
            },
        },
    },
}

api.nvim_create_augroup('nvim-lightbulb', {})

require('inlay-hints').setup()
local defaults = {
    capabilities = require('cmp_nvim_lsp').default_capabilities(
        lsp.protocol.make_client_capabilities()
    ),
    on_attach = function(client, bufnr)
        api.nvim_create_autocmd(
            { 'CursorHold', 'CursorHoldI', 'CursorMoved', 'DiagnosticChanged' },
            {
                buffer = bufnr,
                callback = require('nvim-lightbulb').update_lightbulb,
                group = 'nvim-lightbulb',
            }
        )
        if client.server_capabilities.inlayHintProvider
        then
            require('inlay-hints').on_attach(client, bufnr)
        end

        if client.name == 'lua_ls'
        then
            client.server_capabilities.semanticTokensProvider = nil
            -- the above should be enough but is not, hence the next line
            vim.lsp.semantic_tokens.stop(bufnr, client.id)
        end
        -- TODO: this but better:
        -- if client.server_capabilities.documentHighlightProvider then
        --     vim.api.nvim_create_augroup("lsp_document_highlight",
        --         { clear = true })
        --     vim.api.nvim_clear_autocmds { buffer = bufnr, group =
        --     "lsp_document_highlight" }
        --     vim.api.nvim_create_autocmd("CursorHold", {
        --         callback = vim.lsp.buf.document_highlight,
        --         buffer = bufnr,
        --         group = "lsp_document_highlight",
        --         desc = "Document Highlight",
        --     })
        --     vim.api.nvim_create_autocmd("CursorMoved", {
        --         callback = vim.lsp.buf.clear_references,
        --         buffer = bufnr,
        --         group = "lsp_document_highlight",
        --         desc = "Clear All the References",
        --     })
        -- end
    end,
    single_file_support = true,
}

local lspconfig = require('lspconfig')
for _, server in ipairs(servers) do
    if type(server) == 'string'
    then
        lspconfig[server].setup(defaults)
    else
        lspconfig[server[1]].setup(
            vim.tbl_deep_extend('force', defaults, server[2])
        )
    end
end

local tab_size = function(params)
    return params
        and params.options
        and params.options.tabSize
        or vim.bo.shiftwidth
end

local null_ls = require('null-ls')
null_ls.setup({
    sources = {
        null_ls.builtins.code_actions.gitsigns,
        null_ls.builtins.code_actions.shellcheck,
        null_ls.builtins.diagnostics.shellcheck.with({
            extra_args = { '--enable=all', '--exclude=SC1071,SC2312,SC2148,SC3057' },
            extra_filetypes = { 'zsh' },
        }),
        null_ls.builtins.formatting.prettier.with({
            extra_args = function(params)
                return { '--print-width', cc, '--tab-width', tab_size(params) }
            end,
        }),
        null_ls.builtins.formatting.shfmt.with({
            extra_args = function(params)
                return {
                    '--indent',
                    tab_size(params),
                    '--binary-next-line',
                    '--case-indent',
                    '--language-dialect',
                    'bash',
                    '--space-redirects',
                }
            end,
            extra_filetypes = { 'zsh' },
        }),
        null_ls.builtins.diagnostics.vint.with({
            extra_args = { '--enable-neovim' },
        }),
        null_ls.builtins.formatting.taplo.with({
            extra_args = function(params)
                local opts = {}
                for _, opt in ipairs({
                    'allowed_blank_lines=1',
                    'column_width=' .. cc,
                    'indent_tables=true',
                    'indent_entries=true',
                    'indent_string=' .. string.rep(' ', tab_size(params)),
                })
                do
                    table.insert(opts, '--option')
                    table.insert(opts, opt)
                end
                return opts
            end,
        }),
    },
})

local _format = vim.lsp.buf.format
---@diagnostic disable-next-line: duplicate-set-field
vim.lsp.buf.format = function(opts)
    pcall(cmd.mkview)
    _format(vim.tbl_deep_extend('force', { timeout_ms = 7500 }, opts or {}))
    cmd.retab()
    cmd.doautocmd('TextChanged')
    pcall(cmd.loadview)
    vim.diagnostic.show()
end

local telescope = function(s)
    return function(...)
        require('lazyload').require('telescope.builtin')['lsp_' .. s](...)
    end
end

local handlers = {
    ['callHierarchy/incomingCalls'] = telescope('incoming_calls'),
    ['callHierarchy/outgoingCalls'] = telescope('outgoing_calls'),
    -- ['textDocument/codeAction'] = cmd.CodeActionMenu,
    ['textDocument/declaration'] = telescope('definitions'),
    ['textDocument/definition'] = telescope('definitions'),
    ['textDocument/documentSymbol'] = telescope('document_symbols'),
    ['textDocument/hover'] = { lsp.handlers.hover, { border = 'single' } },
    ['textDocument/implementation'] = telescope('implementations'),
    ['textDocument/references'] = telescope('references'),
    ['textDocument/signatureHelp'] = {
        lsp.handlers.signature_help, { border = 'single' },
    },
    ['textDocument/typeDefinition'] = telescope('type_definitions'),
    ['workspace/symbol'] = telescope('workspace_symbols'),
}

for k in pairs(handlers)
do
    local handler = handlers[k]
    if type(handler) == 'function'
    then
        lsp.handlers[k] = lsp.with(handler, {})
    else
        lsp.handlers[k] = lsp.with(unpack(handler))
    end
end

-- overriding codeAction handler doesn't work
vim.lsp.buf.code_action = cmd.CodeActionMenu

vim.diagnostic.config({
    severity_sort = true,
    signs = true,
    underline = true,
    update_in_insert = false,
    virtual_text = false,
})

local diagnostic_signs = {
    'DiagnosticSignError',
    'DiagnosticSignWarn',
    'DiagnosticSignInfo',
    'DiagnosticSignHint',
}

-- define the default signs, instead of doing it manually
pcall(vim.diagnostic.handlers.signs.show, 0, 0, {})
vim.diagnostic.handlers.signs.show = function(
    namespace,
    bufnr,
    diagnostics,
    opts
)
    opts = opts or {}
    if not bufnr or bufnr == 0
    then
        bufnr = api.nvim_get_current_buf()
    end

    local ns = vim.diagnostic.get_namespace(namespace)
    if not ns.user_data.sign_group
    then
        ns.user_data.sign_group = string.format('vim.diagnostic.%s', ns.name)
    end

    local base_priority = opts.signs.priority or 10
    local sign_group = ns.user_data.sign_group
    for _, diagnostic in ipairs(diagnostics)
    do
        local lnum = diagnostic.lnum + 1
        local priority = base_priority
            + (vim.diagnostic.severity.HINT - diagnostic.severity)
        local placed = fn.sign_getplaced(
            bufnr,
            { group = sign_group, lnum = lnum }
        )[1].signs[1]

        if not placed or placed.priority < priority
        then
            fn.sign_place(
                0,
                sign_group,
                diagnostic_signs[diagnostic.severity],
                bufnr,
                { priority = priority, lnum = lnum }
            )

            if placed
            then
                fn.sign_unplace(
                    sign_group,
                    { buffer = bufnr, id = placed.id }
                )
            end
        end
    end
end
