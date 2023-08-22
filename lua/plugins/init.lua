local l = require('lazyload')

local cmd = vim.cmd
local fn = vim.fn

-- autosession.nvim
require('autosession').setup()

-- feline.nvim
require('plugins/feline')

-- gitsigns.nvim
if fn.executable('git') == 1 then require('gitsigns').setup() end

-- nvim-dap
l.register(
    'nvim-dap',
    {
        commands = { 'Dap*' },
        modules = { 'dap', 'dapui' },
        setup = function() require('plugins/nvim-dap') end,
    }
)

-- nvim-code-action-menu
l.register('nvim-code-action-menu', { commands = { 'CodeActionMenu' } })

-- nvim-colorizer
require('colorizer').setup()

-- nvim-lightbulb
require('nvim-lightbulb').setup({
    sign = { enabled = true, priority = 10, text = 'A' },
    autocmd = { enabled = false },
})

-- nvim-treesitter
vim.treesitter.language.register('bash', 'sh')
vim.treesitter.language.register('bash', 'oil')
vim.treesitter.language.register('bash', 'zsh')

local ts_disable = { 'vimdoc' }
require('nvim-treesitter.configs').setup({
    sync_install = false,
    auto_install = true,
    highlight = {
        enable = true,
        disable = ts_disable,
        additional_vim_regex_highlighting = false,
    },
    matchup = { enable = true },
})

-- nvim-treesitter-context
require('treesitter-context').setup({
    enable = true,
    max_lines = 0,
    trim_scope = 'outer',
    min_window_height = 0,
})

-- indent-blankline.nvim
require('indent_blankline').setup({
    char = '|',
    char_blankline = '',
    show_current_context = true,
    use_treesitter = true,
})

-- iron.nvim
l.register(
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


l.register(
    'licenses.nvim',
    {
        commands = { 'License*' },
        modules = { 'licenses' },
        setup = function()
            require('licenses').setup(
                {
                    copyright_holder = 'reggie',
                    email = 'contact<at>reggie<dot>re',
                    license = 'MIT',
                    remember_previous_id = true,
                    skip_lines = { '^#!', '^# shellcheck ' },
                    wrap_width = tonumber(vim.o.cc) - 1,
                }
            )
            require('luasnip.loaders.from_lua').lazy_load()
        end,
    }
)

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

-- neodev.nvim
l.register(
    'neodev.nvim',
    {
        filetypes = { 'lua' },
        modules = { 'neodev' },
        setup = function()
            require('neodev').setup({
                library = {
                    enabled = true,
                    runtime = true,
                    types = true,
                    plugins = false,
                },
                setup_jsonls = true,
                lspconfig = true,
                pathStrict = true,
            })
        end,
    }
)

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
    ignore = {
        buftype = { "quickfix", "loclist" },
        filetype = {
            'help',
            'list'
        }
    }
})

-- telescope.nvim
l.register(
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

            l.load('licenses.nvim')
            telescope.load_extension('licenses-nvim')
        end,
    }
)

-- trouble.nvim
l.register(
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

-- WIP personal plugins
local config = fn.stdpath('config')
local add_local = function(plugin)
    cmd.set(string.format('runtimepath+=%s/local/%s', config, plugin))
end

for _, plugin in ipairs({
    'dot_repeat',
    'tasks',
    'vimdoc',
})
do
    add_local(plugin .. '.nvim')
end

require('tasks').setup()
require('tasks').register({
    name = 'build.sh',
    cmd = './build.sh',
    condition = function() return vim.fn.executable('./build.sh') == 1 end,
})
