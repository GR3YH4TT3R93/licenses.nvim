vim.cmd.packadd('nvim-dap-ui')

vim.api.nvim_create_user_command('DapUiOpen', require('dapui').open, {})
vim.api.nvim_create_user_command('DapUiClose', require('dapui').close, {})

local dap = require('dap')

local fn = vim.fn

-- dap.adapters.lldb = {
--     type = 'executable',
--     command = '/usr/bin/lldb-vscode',
--     name = 'lldb',
-- }

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
            if not vim.g.dap_program
            then
                vim.g.dap_program = fn.input(
                    'Path to executable: ',
                    fn.getcwd() .. '/', 'file'
                )
            end
            return vim.g.dap_program
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

local rustlib = fn.trim(
    fn.system({ 'rustc', '--print', 'sysroot' })
) .. '/lib/rustlib'
if vim.v.shell_error == 0
then
    dap.configurations.rust = {
        {
            name = 'Launch',
            type = 'cppdbg',
            request = 'launch',
            program = function()
                if not vim.g.dap_program
                then
                    vim.g.dap_program = fn.input(
                        'Path to executable: ',
                        fn.getcwd() .. '/', 'file'
                    )
                end
                return vim.g.dap_program
            end,
            cwd = '${workspaceFolder}',
            stopAtEntry = false,
            args = function()
                return vim.g.dap_args or {}
            end,
            MIMode = 'lldb',
            miDebuggerPath = fn.expand(
                '~/.local/share/vscode-cpptools/lldb-mi'
            ),
            sourceLanguages = { 'rust' },
            setupCommands = {
                {
                    text = string.format(
                        'command script import "%s/etc/lldb_lookup.py"', rustlib
                    ),
                    description = 'enable rust support 1',
                    ignoreFailures = false,
                },
                {
                    text = string.format(
                        'command source -s 0 "%s/etc/lldb_commands"', rustlib
                    ),
                    description = 'enable rust support 2',
                    ignoreFailures = false,
                },
            },
        },
    }
end

require('dapui').setup({
    controls = { element = "repl", enabled = true },
    element_mappings = {},
    expand_lines = true,
    floating = { border = "single", mappings = { close = { "q", "<Esc>" } } },
    force_buffers = true,
    icons = { collapsed = "", current_frame = "", expanded = "" },
    layouts = {
        {
            elements = {
                { id = "scopes", size = 0.25 },
                { id = "breakpoints", size = 0.25 },
                { id = "stacks", size = 0.25 },
                { id = "watches", size = 0.25 },
            },
            position = "left",
            size = 40,
        },
        {
            elements = {
                { id = "repl", size = 0.5 },
                { id = "console", size = 0.5 },
            },
            position = "bottom",
            size = 10,
        },
    },
    mappings = {
        edit = "u",
        expand = { "<CR>", "<2-LeftMouse>" },
        open = "y",
        remove = "s",
        repl = "p",
        toggle = "b",
    },
    render = { indent = 1, max_value_lines = 100 },
})
