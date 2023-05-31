local fn = vim.fn

local util = require('licenses/util')

return function(id, callback)
    vim.validate({
        id = { id, 'string' },
        callback = { callback, 'function', true },
    })

    callback = callback or function() end

    if fn.executable('curl') == 0
    then
        callback(
            'could not find `curl`, please make sure it is installed and in path'
        )
        return
    end

    local url = 'https://spdx.org/licenses/' .. id .. '.json'
    require('licenses/job').run({
        cmd = { 'curl', '-isS', url },
        on_stdout = true,
        on_stderr = true,
        on_failure = vim.schedule_wrap(
            function(_, job) callback(vim.trim(job:stderr())) end
        ),
        on_success = vim.schedule_wrap(
            function(job)
                local lines = vim.split(job:stdout(), '\n')
                local status = tonumber(util.split_words(lines[1])[2])

                if status ~= 200
                then
                    callback(string.format('curl: %s returned %s', url, status))
                    return
                end

                local i = 1
                while lines[i] and lines[i] ~= '' do i = i + 1 end

                local ok, json = pcall(
                    vim.fn.json_decode, vim.list_slice(lines, i + 1)
                )
                if not ok
                then
                    callback(json)
                    return
                end
                ---@cast json table

                local cache = util.get_cache()
                fn.mkdir(cache .. 'text', 'p')
                local f, msg = io.open(cache .. 'text/' .. id .. '.txt', 'w')
                assert(f, msg)
                f:write(json.standardLicenseTemplate)

                local header = json.standardLicenseHeaderTemplate
                if header
                then
                    fn.mkdir(cache .. 'header', 'p')
                    f, msg = io.open(cache .. 'header/' .. id .. '.txt', 'w')
                    assert(f, msg)
                    f:write(header)
                end

                vim.notify('licenses.nvim: Succsesfully downloaded ' .. id)
            end
        ),
    })
end
