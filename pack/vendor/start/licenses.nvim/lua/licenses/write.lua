local core = require('licenses')
local util = require('licenses/util')

return function(path, config)
    vim.validate({
        path = { path, 'string' },
        config = { config, 'table' },
        license = { config.license, { 'function', 'string' } },
    })

    local id = util.get_val(config.license)
    local license = util.get_file('text/' .. id .. '.txt')
    if not license
    then
        return 'License id `' .. id .. '` not found'
    end

    local ok, res = pcall(
        vim.fn.writefile,
        core.get_text(
            license,
            nil,
            config.vars,
            ---@diagnostic disable-next-line: param-type-mismatch
            util.get_val(config.wrap_width) or 0
        ),
        path
    )

    if not ok then return res --[[@as string]] end
end
