vim.cmd.packadd('nvim-dap-ui')

vim.api.nvim_create_user_command('DapUiOpen', require('dapui').open, {})
vim.api.nvim_create_user_command('DapUiClose', require('dapui').close, {})

local dap = require('dap')

local fn = vim.fn

dap.adapters.lldb = {
    type = 'executable',
    command = '/usr/bin/lldb-vscode',
    name = 'lldb',
}

dap.adapters.cppdbg = {
    id = 'cppdbg',
    type = 'executable',
    command = fn.expand(
        '~/.local/share/vscode-cpptools/extension/debugAdapters/bin/OpenDebugAD7'
    ),
}

dap.configurations.cpp = {
    {
        name = 'Launch',
        type = 'cppdbg',
        request = 'launch',
        program = function()
            if not vim.g.dap_executable
            then
                vim.g.dap_executable = fn.input(
                    'Path to executable: ',
                    './',
                    'file'
                )
            end
            return vim.g.dap_executable
        end,
        cwd = '${workspaceFolder}',
        stopAtEntry = false,
        args = function()
            return vim.g.dap_args or {}
        end,
        MIMode = 'gdb',
        miDebuggerPath = '/usr/bin/gdb',
        setupCommands = {
            {
                text = '-enable-pretty-printing',
                description = 'enable pretty printing',
                ignoreFailures = false,
            },
        },
    },
}
dap.configurations.c = dap.configurations.cpp

dap.configurations.rust = {
    {
        name = 'Launch',
        type = 'lldb',
        request = 'launch',
        program = function()
            if not vim.g.dap_executable
            then
                vim.g.dap_executable = fn.input(
                    'Path to executable: ',
                    './',
                    'file'
                )
            end
            return vim.g.dap_executable
        end,
        cwd = '${workspaceFolder}',
        stopAtEntry = false,
        args = function()
            return vim.g.dap_args or {}
        end,

        initCommands = function()
            local rustlib = fn.trim(
                fn.system({ 'rustc', '--print', 'sysroot' }) or ''
            ) .. '/lib/rustlib'

            local commands = {
                'command script import "' .. rustlib .. '/etc/lldb_lookup.py"',
            }

            local f = io.open(rustlib .. '/etc/lldb_commands')
            if f
            then
                for line in f:lines()
                do
                    table.insert(commands, line)
                end
                f:close()
            end

            return commands
        end,
    },
}

require('dapui').setup({
    controls = { element = 'repl', enabled = true },
    element_mappings = {},
    expand_lines = true,
    floating = { border = 'single', mappings = { close = { 'q', '<Esc>' } } },
    force_buffers = true,
    icons = { collapsed = '', current_frame = '', expanded = '' },
    layouts = {
        {
            elements = {
                { id = 'scopes', size = 0.25 },
                { id = 'breakpoints', size = 0.25 },
                { id = 'stacks', size = 0.25 },
                { id = 'watches', size = 0.25 },
            },
            position = 'left',
            size = 40,
        },
        {
            elements = {
                { id = 'repl', size = 0.5 },
                { id = 'console', size = 0.5 },
            },
            position = 'bottom',
            size = 10,
        },
    },
    mappings = {
        edit = 'u',
        expand = { '<CR>', '<2-LeftMouse>' },
        open = 'y',
        remove = 's',
        repl = 'p',
        toggle = 'b',
    },
    render = { indent = 1, max_value_lines = 100 },
})
