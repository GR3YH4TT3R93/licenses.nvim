local api = vim.api
local fn = vim.fn
local cmd = vim.cmd
local lsp = vim.lsp

require('lsp_lines').setup()

-- XXX: wait for https://github.com/lvimuser/lsp-inlayhints.nvim/issues/17#issuecomment-1242142570
--      also reenable hints for rust once it lands
require('lsp-inlayhints').setup({
    inlay_hints = {
        parameter_hints = {
            show = true,
            prefix = '<- ',
            separator = ', ',
            remove_colon_start = false,
            remove_colon_end = true,
        },
        type_hints = {
            -- type and other hints
            show = true,
            prefix = '',
            separator = ', ',
            remove_colon_start = false,
            remove_colon_end = false,
        },
        only_current_line = false,
        -- separator between types and parameter hints. Note that type hints are
        -- shown before parameter
        labels_separator = ' ',
        -- whether to align to the length of the longest line in the file
        max_len_align = false,
        -- padding from the left if max_len_align is true
        max_len_align_padding = 1,
        -- highlight group
        highlight = 'LspInlayHint',
        -- virt_text priority
        priority = 0,
    },
    enabled_at_startup = true,
    debug_mode = false,
})

local cc = (tonumber(vim.o.cc) or 80) - 1
local enable = { enable = true }
local disable = { enable = false }

local servers = {
    'clangd',
    'gopls',
    'ltex',
    {
        'lua_ls',
        {
            on_attach = function(client, bufnr)
                client.server_capabilities.semanticTokensProvider = nil
                vim.lsp.semantic_tokens.stop(bufnr, client.id)
            end,
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
                    -- hint = disable,
                    hint = enable,
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
            on_attach = function(client)
                client.server_capabilities.documentFormattingProvider = nil
            end,
            settings = {
                pylsp = {
                    plugins = {
                        black = { enabled = true, line_length = cc },
                        isort = { enabled = true },
                        pylsp_mypy = {
                            enabled = true,
                            live_mode = true,
                            report_progress = true,
                            overrides = {
                                '--python-executable=' .. fn.exepath("python"),
                                '--ignore-missing-imports',
                                true,
                            },
                        },
                        pylint = {
                            args = {
                                -- '--enable-all-extensions',
                                '--good-names-rgxs=[a-z]',
                                '--good-names=ex,Run,_',
                                '--include-naming-hint=True',
                                '--max-line-length=' .. cc,
                                '--reports=True',
                                "--init-hook='" .. table.concat(
                                    {
                                        'import sys',
                                        string.format(
                                            'sys.path.append("%s/lspconfig")',
                                            fn.stdpath('config')
                                        ),
                                        'import pylint_venv',
                                        'pylint_venv.inithook(quiet=True)',
                                    },
                                    ';'
                                ) .. "'",
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
            on_attach = function(client)
                client.server_capabilities.inlayHintProvider = nil
            end,
            -- https://rust-analyzer.github.io/manual.html
            settings = {
                ['rust-analyzer'] = {
                    checkOnSave = true,
                    check = {
                        command = 'clippy',
                        extraArgs = {
                            '--',
                            '-W',
                            'clippy::all',
                            '-W',
                            'clippy::correctness',
                            '-W',
                            'clippy::complexity',
                            '-W',
                            'clippy::nursery',
                            '-W',
                            'clippy::perf',
                            '-W',
                            'clippy::cargo',
                            '-A',
                            'clippy::cargo_common_metadata',
                            '-A',
                            'clippy::option-if-let-else',
                        },
                    },
                    cargo = { noDefaultFeatures = false },
                    completion = { privateEditable = enable },
                    hover = { actions = { references = enable, run = disable } },
                    imports = { prefer = { no = { std = true } } },
                    inlayHints = {
                        closureReturnTypeHints = enable,
                        lifetimeElisionHints = enable,
                    },
                    rustfmt = {
                        extraArgs = {
                            '--config',
                            table.concat({
                                'max_width=' .. cc,
                                'newline_style=Unix',
                                'format_strings=true',
                            }, ','),
                        },
                    },
                },
            },
        },
    },
    { 'typst_lsp', { settings = { exportPdf = 'never' } } },
}

local defaults = {
    capabilities = vim.tbl_deep_extend('force',
        require('cmp_nvim_lsp').default_capabilities(),
        {
            offsetEncoding = { 'utf-16' },
            workspace = { didChangeWatchedFiles = { dynamicRegistration = false } },
        }
    ),
    on_attach = function(client, bufnr)
        require("lsp-inlayhints").on_attach(client, bufnr)

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
    flags = { debounce_text_changes = 2500 },
}

local lspconfig = require('lspconfig')
for _, server in ipairs(servers) do
    if type(server) == 'string'
    then
        lspconfig[server].setup(defaults)
    else
        local name, conf = unpack(server)

        local on_attach = conf.on_attach
        if on_attach
        then
            conf.on_attach = function(...)
                on_attach(...)
                defaults.on_attach(...)
            end
        end

        lspconfig[name].setup(vim.tbl_deep_extend('force', defaults, conf))
    end
end

local _format = vim.lsp.buf.format
---@diagnostic disable-next-line: duplicate-set-field
vim.lsp.buf.format = function(opts)
    pcall(cmd.mkview)
    _format(
        vim.tbl_deep_extend(
            'force',
            { timeout_ms = 7500 },
            opts or {},
            ---@diagnostic disable-next-line: undefined-field
            vim.b.format_opts or {}
        )
    )
    cmd.retab()
    cmd.doautocmd('TextChanged')
    pcall(cmd.loadview)
    vim.diagnostic.show()
end

local telescope = function(s)
    return function()
        require('lazyload').require('telescope.builtin')['lsp_' .. s]()
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
    virtual_lines = { only_current_line = true },
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
