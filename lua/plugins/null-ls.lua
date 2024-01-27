local cc = (tonumber(vim.o.cc) or 80) - 1

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
            extra_args = {
                '--enable=all',
                '--exclude=SC1071,SC2312,SC2148,SC3057',
            },
            extra_filetypes = { 'zsh' },
        }),
        null_ls.builtins.formatting.clang_format.with({
            extra_args = {
                '--style=file:'
                .. vim.api.nvim_get_runtime_file(
                    'lspconfig/clang-format', false
                )[1],
            },
        }),
        null_ls.builtins.formatting.isort,
        null_ls.builtins.formatting.black.with({
            extra_args = { '--line-length', cc },
        }),
        null_ls.builtins.formatting.latexindent,
        null_ls.builtins.formatting.prettier.with({
            extra_args = function(params)
                local args = {
                    '--print-width',
                    cc,
                    '--tab-width',
                    tab_size(params),
                }

                if vim.fn.fnamemodify(params.bufname, ':e') == ''
                then
                    args = vim.list_extend(
                        { '--parser', vim.bo[params.bufnr].filetype }, args
                    )
                end

                return args
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
        null_ls.builtins.formatting.typstfmt,
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
