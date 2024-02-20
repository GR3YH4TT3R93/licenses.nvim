local lazy = require('lazyload')

local fn = vim.fn

-- bigger plugins with their own config files
require('plugins/feline')
require('plugins/lspconfig')
require('plugins/null-ls')
require('plugins/nvim-cmp')

-- autosession.nvim
require('autosession').setup()

-- copilot.lua
lazy.register(
    'copilot.lua',
    {
        commands = { 'Copilot' },
        setup = function()
            require('copilot').setup({
                suggestion = { enabled = false },
                panel = { enabled = false },
            })
            vim.cmd.Copilot('disable')
        end,
    }
)

-- gitsigns.nvim
if fn.executable('git') == 1 then
    require('gitsigns').setup(
        {
            diff_opts = { algorithm = 'minimal', internal = true, linematch = 60 },
            current_line_blame = true,
            numhl = true,
            trouble = true,
        }
    )
end

if fn.executable('xxd') == 1 then
    require('hex').setup()
end

-- nvim-colorizer
require('colorizer').setup()

-- indent-blankline.nvim
require('indent_blankline').setup({
    -- char = '|',
    char_blankline = '',
    show_current_context = true,
    use_treesitter = true,
})

-- iron.nvim
lazy.register(
    'iron.nvim',
    {
        commands = { 'Iron*' },
        setup = function()
            require('iron.core').setup({
                config = {
                    scratch_repl = true,
                    -- Your repl definitions come here
                    -- repl_definition = {
                    --     sh = {
                    --         -- Can be a table or a function that
                    --         -- returns a table (see below)
                    --         command = { "zsh" },
                    --     },
                    -- },
                    repl_open_cmd = require('iron.view').split.vertical('50%'),
                },
                keymaps = {
                    -- send_motion = "<space>sc",
                    -- visual_send = "<space>sc",
                    -- send_file = "<space>sf",
                    -- send_line = "<space>sl",
                    -- send_mark = "<space>sm",
                    -- mark_motion = "<space>mc",
                    -- mark_visual = "<space>mc",
                    -- remove_mark = "<space>md",
                    -- cr = "<space>s<cr>",
                    -- interrupt = "<space>s<space>",
                    -- exit = "<space>sq",
                    -- clear = "<space>cl",
                },
                -- highlight = { italic = true },
                ignore_blank_lines = true,
            })
        end,
    }
)


---@diagnostic disable-next-line: missing-fields
require('licenses').setup({
    copyright_holder = function()
        ---@diagnostic disable-next-line: param-type-mismatch
        return vim.trim(fn.system({ 'git', 'config', 'user.name' }))
    end,
    email = function()
        ---@diagnostic disable-next-line: param-type-mismatch
        return vim.trim(fn.system({ 'git', 'config', 'user.email' }))
    end,
    license = 'MIT',
    remember_previous_id = true,
    skip_lines = { '^#!', '^# shellcheck ' },
    wrap_width = tonumber(vim.o.cc) - 1,
    -- XXX: consider making this default in licenses.nvim
    write_license_to_file = function(id)
        local file = './LICENSES/' .. id .. '.txt'

        if fn.filereadable(file) == 1 then return false end

        return fn.confirm(
            'Also write license to ' .. file .. '?', '&Yes\n&No', 2
        ) == 1
    end,
})

-- LuaSnip
require('luasnip').setup({
    history = true,
    delete_check_events = 'TextChanged',
    enable_autosnippets = true,
    store_selection_keys = '<C-n>',
})

vim.api.nvim_create_autocmd(
    'VimEnter',
    {
        callback = function()
            require('luasnip').filetype_extend('typescriptreact', { 'html' })
            require('luasnip.loaders.from_lua').lazy_load()
            require('luasnip.loaders.from_vscode').lazy_load()
        end,
    }
)

-- nvim-code-action-menu
lazy.register('nvim-code-action-menu', { commands = { 'CodeActionMenu' } })

-- nvim-dap
lazy.register(
    'nvim-dap',
    {
        commands = { 'Dap*' },
        modules = { 'dap', 'dapui' },
        setup = function() require('plugins/nvim-dap') end,
    }
)

-- nvim-treesitter
vim.treesitter.language.register('bash', 'sh')
vim.treesitter.language.register('bash', 'oil')
vim.treesitter.language.register('bash', 'zsh')

local ts_disable = { 'gitcommit', 'vimdoc', 'zig' }
---@diagnostic disable-next-line: missing-fields
require('nvim-treesitter.configs').setup({
    sync_install = false,
    auto_install = true,
    ignore_install = ts_disable,
    highlight = {
        enable = true,
        disable = ts_disable,
        additional_vim_regex_highlighting = false,
    },
    matchup = { enable = true },
    textobjects = {
        select = {
            enable = true,
            lookahead = true,
            keymaps = {
                at = '@function.outer',
                ut = '@function.inner',
                ad = '@class.outer',
                ud = '@class.inner',
            },
        },
        move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
                [']h'] = '@function.outer',
                [']{'] = '@block.outer',
                [']['] = '@class.outer',
            },
            goto_next_end = {
                [']H'] = '@function.outer',
                [']}'] = '@block.outer',
                [']]'] = '@class.outer',
            },
            goto_previous_start = {
                ['[h'] = '@function.outer',
                ['[{'] = '@block.outer',
                ['[['] = '@class.outer',
            },
            goto_previous_end = {
                ['[H'] = '@function.outer',
                ['[}'] = '@block.outer',
                ['[]'] = '@class.outer',
            },
        },
    },
})

-- nvim-treesitter-context
---@diagnostic disable-next-line: missing-fields
require('treesitter-context').setup({
    enable = true,
    max_lines = 0,
    trim_scope = 'outer',
    min_window_height = 0,
})

-- oil.nvim
require('oil').setup({
    default_file_explorer = true,
    cleanup_delay_ms = false,
    keymaps = {
        ['g?'] = 'actions.show_help',
        ['<CR>'] = 'actions.select',
        ['<C-r>'] = 'actions.select_vsplit',
        ['<C-m>'] = 'actions.select_split',
        ['<C-b>'] = 'actions.select_tab',
        ['<C-;>'] = 'actions.preview',
        ['<C-d>'] = 'actions.close',
        ['<C-i>'] = 'actions.refresh',
        ['-'] = 'actions.parent',
        ['_'] = 'actions.open_cwd',
        ['`'] = 'actions.cd',
        ['~'] = 'actions.tcd',
        ['gr'] = 'actions.change_sort',
        ['gc'] = 'actions.open_external',
        ['g.'] = 'actions.toggle_hidden',
    },
    use_default_keymaps = false,
    view_options = {
        show_hidden = true
    }
})

-- rainbow-delimiters.nvim
vim.g.rainbow_delimiters = {
    strategy = { [''] = require('rainbow-delimiters').strategy['global'] },
    query = { [''] = 'rainbow-delimiters', lua = 'rainbow-blocks' },
    highlight = {
        'RainbowDelimiterRed',
        'RainbowDelimiterYellow',
        'RainbowDelimiterBlue',
        'RainbowDelimiterOrange',
        'RainbowDelimiterGreen',
        'RainbowDelimiterViolet',
        'RainbowDelimiterCyan',
    },
}

-- stabilize.nvim
require('stabilize').setup({
    force = true,
    ignore = {
        buftype = {},
        filetype = {},
        nested = "QuickFixCmdPost,DiagnosticChanged *",
    },
})

-- synctex.nvim
require('synctex').setup()

-- telescope.nvim
lazy.register(
    'telescope.nvim',
    {
        commands = { 'Telescope' },
        modules = { 'telescope', 'telescope.builtin' },
        setup = function()
            local telescope = require('telescope')

            local actions = require('telescope.actions')
            telescope.setup {
                defaults = {
                    dynamic_preview_title = true,
                    results_title = false,
                    prompt_title = false,
                    layout_config = {
                        height = 0.95,
                        width = 0.85,
                        preview_width = 0.55,
                    },
                    default_mappings = {},
                    mappings = {
                        i = {
                            ['<C-n>'] = actions.move_selection_next,
                            ['Down'] = actions.move_selection_next,
                            ['<C-e>'] = actions.move_selection_previous,
                            ['Up'] = actions.move_selection_previous,
                            ['<Esc>'] = actions.close,
                            ['<Cr>'] = actions.select_default,
                            ['<C-c>'] = actions.file_split,
                            ['<C-v>'] = actions.file_vsplit,
                            ['<C-b>'] = actions.file_tab,
                            ['<C-w>'] = { '<c-s-w>', type = 'command' },
                            ['<C-l>'] = actions.preview_scrolling_up,
                            ['<C-s>'] = actions.preview_scrolling_down,
                        },
                    },
                },
                extensions = { ['licenses-nvim'] = { default_action = 'pick' } },
            }

            telescope.load_extension('licenses-nvim')
        end,
    }
)

-- trouble.nvim
lazy.register(
    'trouble.nvim',
    {
        commands = { 'Trouble*' },
        modules = { 'trouble' },
        setup = function()
            require('trouble').setup({
                position = "bottom",
                height = 8,
                icons = true,
                mode = "workspace_diagnostics",
                fold_open = "",
                fold_closed = "",
                group = true,
                padding = true,
                action_keys = {
                    -- map to {} to remove a mapping, for example:
                    -- close = {},
                    close = "q",
                    cancel = "<esc>",
                    refresh = "p",
                    jump = { "<cr>", "<tab>" },
                    open_split = 'r',
                    open_vsplit = 'v',
                    open_tab = {},
                    jump_close = {},
                    toggle_mode = "h",
                    toggle_preview = "G",
                    hover = "<space>",
                    preview = "g",
                    close_folds = {},
                    open_folds = {},
                    toggle_fold = 't',
                    previous = "e",
                    next = "n",
                },
                indent_lines = false,
                auto_open = false,
                auto_close = false,
                auto_preview = false,
                auto_fold = false,
                auto_jump = { "lsp_definitions" },
                signs = {
                    error = "",
                    warning = "",
                    hint = "",
                    information = "",
                    other = "﫠",
                },
                use_diagnostic_signs = false,
            })
        end,
    }
)

-- cmd.set(
--     string.format(
--         'runtimepath+=%s/local/%s', fn.stdpath('config'), 'vimdoc.nvim'
--     )
-- )
