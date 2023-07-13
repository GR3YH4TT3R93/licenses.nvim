local colors = require('colorscheme')
local fn = vim.fn
local lsp = require('feline.providers.lsp')

local components = { active = { {}, {}, {} }, inactive = { {}, {} } }

local mode_colors = {
    ['n'] = { 'NORMAL', colors.blue },
    ['no'] = { 'N-PENDING', colors.blue },
    ['i'] = { 'INSERT', colors.green },
    ['ic'] = { 'INSERT', colors.green },
    ['t'] = { 'TERMINAL', colors.green },
    ['v'] = { 'VISUAL', colors.flamingo },
    ['V'] = { 'V-LINE', colors.flamingo },
    [''] = { 'V-BLOCK', colors.flamingo },
    ['R'] = { 'REPLACE', colors.maroon },
    ['Rv'] = { 'V-REPLACE', colors.maroon },
    ['s'] = { 'SELECT', colors.maroon },
    ['S'] = { 'S-LINE', colors.maroon },
    [''] = { 'S-BLOCK', colors.maroon },
    ['c'] = { 'COMMAND', colors.peach },
    ['cv'] = { 'COMMAND', colors.peach },
    ['ce'] = { 'COMMAND', colors.peach },
    ['r'] = { 'PROMPT', colors.teal },
    ['rm'] = { 'MORE', colors.teal },
    ['r?'] = { 'CONFIRM', colors.mantle },
    ['!'] = { 'SHELL', colors.green },
}

local file_info = function(use_icon, max_width)
    max_width = math.floor(vim.api.nvim_win_get_width(0) / 100 * max_width)
    local fname = fn.expand('%:~:.')

    local ok, icons = pcall(require, 'nvim-web-devicons')
    local icon = use_icon
        and ok
        and icons.get_icon(fname, fn.expand('%:e'))

    -- from https://github.com/nvim-lualine/lualine.nvim/blob/master/lua/lualine/components/filename.lua
    local len = #fname
    ---@diagnostic disable-next-line: missing-parameter
    local segments = vim.split(fname, '/')
    for i = 1, #segments - 1
    do
        if len <= max_width
        then
            break
        end

        local segment = segments[i]
        local shortened = segment:sub(
            1, vim.startswith(segment, '.') and 2 or 1
        )
        segments[i] = shortened
        len = len - (#segment - #shortened)
    end
    if len > max_width
    then
        fname = fn.fnamemodify(fname, ':t')
    else
        fname = table.concat(segments, '/')
    end

    if icon then fname = icon .. ' ' .. fname end
    if vim.bo.modified then fname = fname .. ' [+]' end
    if vim.bo.readonly or not vim.bo.modifiable then fname = fname .. ' [-]' end

    return fname
end

local is_trouble = function() return vim.bo.filetype == 'Trouble' end

local git_info_exists = require('feline.providers.git').git_info_exists

local add_active = function(idx, component)
    table.insert(components.active[idx], component)
end

local add_inactive = function(idx, component)
    table.insert(components.inactive[idx], component)
end

add_active(
    1, {
        provider = function()
            local current_line = fn.line('.')
            local total_line = fn.line('$')

            if current_line == 1
            then
                return ' Top'
            elseif current_line == fn.line('$')
            then
                return ' Bot'
            end

            local result, _ = math.modf((current_line / total_line) * 100)
            return (result < 10 and ' 0' or ' ') .. result .. '%%'
        end,
        enabled = function() return not is_trouble() end,
        hl = { fg = colors.mantle, bg = colors.lavender },
    }
)

add_active(
    1, {
        provider = 'position',
        enabled = function() return not is_trouble() end,
        hl = { fg = colors.mantle, bg = colors.lavender },
        left_sep = { str = ' ', hl = { bg = colors.lavender } },
        right_sep = {
            str = 'right_rounded',
            hl = function()
                return { fg = colors.lavender, bg = mode_colors[fn.mode()][2] }
            end,
        },
    }
)


add_active(
    1, {
        provider = function()
            return ' '
                .. (is_trouble() and 'Trouble' or mode_colors[fn.mode()][1])
        end,
        hl = function()
            return { fg = colors.mantle, bg = mode_colors[fn.mode()][2] }
        end,
        right_sep = {
            str = 'right_rounded',
            hl = function()
                return {
                    fg = mode_colors[fn.mode()][2],
                    bg = git_info_exists() and colors.mantle or colors.surface0,
                }
            end,
        },
    }
)

add_active(
    1, {
        provider = 'git_branch',
        enabled = git_info_exists,
        hl = { fg = colors.mauve, bg = colors.mantle },
        icon = '',
        left_sep = { str = ' ', hl = { bg = colors.mantle } },
    }
)

add_active(
    1, {
        provider = 'git_diff_added',
        enabled = git_info_exists,
        hl = { fg = colors.green, bg = colors.mantle },
        icon = ' +',
    }
)

add_active(
    1, {
        provider = 'git_diff_removed',
        enabled = git_info_exists,
        hl = { fg = colors.red, bg = colors.mantle },
        icon = ' -',
    }
)

add_active(
    1, {
        provider = 'git_diff_changed',
        enabled = git_info_exists,
        hl = { fg = colors.yellow, bg = colors.mantle },
        icon = ' ~',
    }
)

add_active(
    1, {
        provider = '',
        enabled = git_info_exists,
        hl = { fg = colors.mantle, bg = colors.surface0 },
    }
)

local get_active_clients = function()
    local clients = {}
    for _, client in ipairs(
        vim.lsp.get_active_clients(
            { bufnr = vim.api.nvim_get_current_buf() }
        )
    )
    do
        if client.name ~= 'null-ls' then table.insert(clients, client.name) end
    end
    return clients
end

local is_lsp_progress = function()
    local prog = vim.lsp.util.get_progress_messages()[1]
    return prog
        and prog.name
        and vim.tbl_contains(get_active_clients(), prog.name)
end

add_active(
    2, {
        provider = function()
            local prog = vim.lsp.util.get_progress_messages()[1]

            if prog
            then
                local title = prog.title and prog.title .. ' ' or ''
                local msg = prog.message and prog.message .. ' ' or ''
                local percentage = prog.percentage
                if not percentage then return '' end

                return string.format('%s%s(%s%%%%)', title, msg, percentage)
            end
            return ''
        end,
        enabled = is_lsp_progress,
        hl = { fg = colors.text, bg = colors.surface0 },
    }
)

local diagnostics_enabled = function(severity)
    return not is_lsp_progress()
        and lsp.diagnostics_exist(vim.diagnostic.severity[severity])
end

add_active(
    2, {
        provider = 'diagnostic_errors',
        enabled = function() return diagnostics_enabled('ERROR') end,
        hl = { fg = colors.red, bg = colors.surface0 },
    }
)

add_active(
    2, {
        provider = 'diagnostic_warnings',
        enabled = function() return diagnostics_enabled('WARN') end,
        hl = { fg = colors.yellow, bg = colors.surface0 },
    }
)

add_active(
    2, {
        provider = 'diagnostic_info',
        enabled = function() return diagnostics_enabled('INFO') end,
        hl = { fg = colors.sky, bg = colors.surface0 },
    }
)

add_active(
    2, {
        provider = 'diagnostic_hints',
        enabled = function() return diagnostics_enabled('HINT') end,
        hl = { fg = colors.teal, bg = colors.surface0 },
    }
)

add_active(
    3, {
        provider = function()
            return ' ' .. table.concat(get_active_clients(), ', ') .. ' '
        end,
        hl = { fg = colors.mantle, bg = colors.flamingo },
        left_sep = {
            str = 'left_rounded',
            hl = { fg = colors.flamingo, bg = colors.surface0 },
        },
        enabled = function() return #get_active_clients() ~= 0 end,
    }
)

add_active(
    3, {
        provider = function()
            return file_info(true, is_lsp_progress() and 30 or 40)
        end,
        enabled = function() return not is_trouble() end,
        hl = { fg = colors.mantle, bg = colors.maroon },
        left_sep = {
            str = 'left_rounded',
            hl = function()
                return {
                    fg = colors.maroon,
                    bg = #get_active_clients() == 0
                        and colors.surface0
                        or colors.flamingo,
                }
            end,
        },
        right_sep = { str = ' ', hl = { bg = colors.maroon } },
    }
)

add_inactive(
    1, {
        provider = function()
            return is_trouble() and 'Trouble' or file_info(false, 60)
        end,
        left_sep = { str = ' ', hl = { bg = colors.mantle } },
        hl = { fg = colors.text, bg = colors.mantle },
        icon = '',
    }
)

add_inactive(
    2, {
        provider = 'diagnostic_errors',
        enabled = function()
            return lsp.diagnostics_exist(vim.diagnostic.severity.ERROR)
        end,
        hl = { fg = colors.red, bg = colors.mantle },
    }
)

add_inactive(
    2, {
        provider = 'diagnostic_warnings',
        enabled = function()
            return lsp.diagnostics_exist(vim.diagnostic.severity.WARN)
        end,
        hl = { fg = colors.yellow, bg = colors.mantle },
    }
)

add_inactive(
    2, {
        provider = 'diagnostic_info',
        enabled = function()
            return lsp.diagnostics_exist(vim.diagnostic.severity.INFO)
        end,
        hl = { fg = colors.sky, bg = colors.mantle },
    }
)

add_inactive(
    2, {
        provider = 'diagnostic_hints',
        enabled = function()
            return lsp.diagnostics_exist(vim.diagnostic.severity.HINT)
        end,
        hl = { fg = colors.teal, bg = colors.mantle },
    }
)

add_inactive(2, { provider = ' ', hl = { bg = colors.mantle } })

require('feline').setup({ components = components })
