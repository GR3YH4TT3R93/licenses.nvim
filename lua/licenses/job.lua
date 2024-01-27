-- SPDX-License-Identifier: Unlicense

-- This is free and unencumbered software released into the public domain.

-- Anyone is free to copy, modify, publish, use, compile, sell, or distribute
-- this software, either in source code form or as a compiled binary, for any
-- purpose, commercial or non-commercial, and by any means.

-- In jurisdictions that recognize copyright laws, the author or authors of
-- this software dedicate any and all copyright interest in the software to the
-- public domain. We make this dedication for the benefit of the public at
-- large and to the detriment of our heirs and successors. We intend this
-- dedication to be an overt act of relinquishment in perpetuity of all present
-- and future rights to this software under copyright law.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
-- ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

-- For more information, please refer to <https://unlicense.org/>

local M = {}

local uv = vim.loop

local Job = {}
Job.__index = Job

---@param key string
---@return fun(err: string?, data: string?, job: Job)
local on_output = function(key)
    return function(e, d, j)
        assert(not e, e)
        if d then j[key] = j[key] .. d:gsub('\r', '') end
    end
end

---@return uv_stream_t
local new_pipe = function()
    local pipe, err = uv.new_pipe(false)
    assert(pipe, err)
    return pipe
end

---@class Opts
---@field cmd string[]
---@field cwd string
---@field env table<string, string>
---@field on_stdout fun(err: string?, data: string?, job: Job) | boolean
---@field on_stderr fun(err: string?, data: string?, job: Job) | boolean
---@field on_exit fun(code: integer, job: Job)
---@field on_failure fun(code: integer, job: Job)
---@field on_success fun(job: Job)
---@field stdio uv_stream_t[]

---@param opts Opts
function Job:new(opts)
    vim.validate({
        opts = { opts, 'table' },
        cmd = { opts.cmd, 'table' },
        cwd = { opts.cwd, 'string', true },
        env = { opts.env, 'table', true },
        on_stdout = { opts.on_stdout, { 'boolean', 'function' }, true },
        on_stderr = { opts.on_stderr, { 'boolean', 'function' }, true },
        on_exit = { opts.on_exit, 'function', true },
        on_failure = { opts.on_failure, 'function', true },
        on_success = { opts.on_success, 'function', true },
        stdio = { opts.stdio, 'table', true },
    })

    opts.env = opts.env or {}
    opts.stdio = opts.stdio or {}
    assert(#opts.cmd ~= 0, 'cmd: cannot be empty')
    assert(
        not (opts.stdio[2] and opts.on_stdout),
        'cannot use on_stdout and pass stdout via stdio at the same time'
    )
    assert(
        not (opts.stdio[3] and opts.on_stderr),
        'cannot use on_stderr and pass stderr via stdio at the same time'
    )
    assert(
        not (opts.on_exit and (opts.on_failure or opts.on_success)),
        'on_exit and on_failure/on_success are mutually exclusive'
    )

    self = {}
    self._path = table.remove(opts.cmd, 1)
    self._stdio = opts.stdio

    if opts.on_stdout
    then
        self._stdio[2] = new_pipe()
        if opts.on_stdout == true
        then
            self._stdout_data = ''
            opts.on_stdout = on_output('_stdout_data')
        end
    end

    if opts.on_stderr
    then
        self._stdio[3] = new_pipe()
        if opts.on_stderr == true
        then
            self._stderr_data = ''
            opts.on_stderr = on_output('_stderr_data')
        end
    end

    local env = {}
    for k, v in ipairs(opts.env) do table.insert(env, k .. '=' .. v) end

    self._spawn_opts = {
        args = opts.cmd,
        stdio = self._stdio,
        env = env,
        cwd = opts.cwd,
    }

    self._callbacks = {
        on_exit = opts.on_exit or function(c, j)
            local cb = j._callbacks
            if c == 0
            then
                if cb.on_success then cb.on_success(j) end
            else
                if cb.on_failure then cb.on_failure(c, j) end
            end
        end,
        on_failure = opts.on_failure,
        on_success = opts.on_success,
        on_stdout = opts.on_stdout,
        on_stderr = opts.on_stderr,
    }

    return setmetatable(self, Job)
end

---@return integer | nil
function Job:exit_code()
    return self:is_active() and nil or self._exit_code
end

---@return string | nil
function Job:stdout() return self._stdout_data end

---@return string | nil
function Job:stderr() return self._stderr_data end

---@return boolean
function Job:is_active()
    return self._handle and self._handle:is_active() or false
end

---@return integer | nil
function Job:get_pid()
    return self:is_active() and self._handle:get_pid() or nil
end

function Job:stop()
    for i = 1, 3, 1
    do
        local stream = self._stdio[i]
        if stream and not stream:is_closing()
        then
            stream:read_stop()
            stream:close()
        end
    end
    if self._handle and not self._handle:is_closing()
    then
        self._handle:close()
    end
end

---@param timeout integer
---@return boolean
function Job:wait(timeout)
    local finished = vim.wait(
        timeout, function() return not self:is_active() end
    )
    if not finished then self:stop() end
    return finished
end

function Job:start()
    assert(not self:is_active(), 'job already started')
    local cb = self._callbacks
    local err
    self._handle, err = uv.spawn(
        self._path,
        self._spawn_opts,
        function(c)
            self._exit_code = c
            if cb.on_exit then cb.on_exit(c, self) end
            self:stop()
        end
    )
    assert(
        self._handle, string.format('failed to spawn %s (%s)', self._path, err)
    )

    if cb.on_stdout
    then
        self._stdio[2]:read_start(function(e, d) cb.on_stdout(e, d, self) end)
    end

    if cb.on_stderr
    then
        self._stdio[3]:read_start(function(e, d) cb.on_stderr(e, d, self) end)
    end
end

---@param timeout integer
---@return boolean
function Job:start_sync(timeout)
    self:start()
    return self:wait(timeout)
end

---@param signal integer | uv.aliases.signals
---@return 0 | nil success, string? err_name, string? err_msg
function Job:kill(signal)
    if self._handle then return self._handle:kill(signal) end
end

M.Job = Job

---@param opts Opts
M.run = function(opts) Job:new(opts):start() end

---@param opts Opts
---@param timeout integer
---@return boolean
M.run_sync = function(opts, timeout)
    return Job:new(opts):start_sync(timeout)
end

return M
