local yd = require 'yo-dawg'

---Markdown document with Lua code inside a code block
local markdown_with_injected_lua = [[This is some Markdown

```lua
print(((('Hello world'))))
```

This is more markdown.]]

---Markdown document with Lua code outside a code block
local markdown_without_injected_lua = [[This is some Markdown

```lua
```
print(((('Hello world'))))

This is more markdown.]]


describe('Buffer Manipulation', function()
	local nvim

	before_each(function()
		nvim = yd.start()
		nvim:exec_lua('TSEnsure(...)', {'lua', 'vim', 'markdown'})
		nvim:exec_lua([[
			local rb = require 'rainbow-delimiters'
			local global = rb.strategy.global
			assert(nil ~= global)
			vim.g.rainbow_delimiters = {
				strategy = {
					[''] = global
				},
			}
		]], {})
	end)

	after_each(function()
		yd.stop(nvim)
	end)

	it('Clears extmarks when moving line out of injected langauge', function()
		nvim:exec_lua('TSEnsure(...)', {'lua', 'markdown'})
		nvim:buf_set_lines(0, 0, -2, true, vim.fn.split(markdown_with_injected_lua, '\n'))
		nvim:buf_set_option(0, 'filetype', 'markdown')
		assert.nvim(nvim).has_extmarks_at(3, 5, 'lua')

		-- Move Lua line out of code block
		nvim:cmd({cmd = 'move', range = {4}, args = {5}}, {})

		local given = vim.fn.join(nvim:buf_get_lines(0, 0, -2, true), '\n')
		assert.is.equal(markdown_without_injected_lua, given)

		assert.nvim(nvim).Not.has_extmarks_at(4, 5, 'lua')
	end)

	it('Adds extmarks when moving line into injected langauge', function()
		nvim:exec_lua('TSEnsure(...)', {'lua', 'markdown'})
		nvim:buf_set_lines(0, 0, -2, true, vim.fn.split(markdown_without_injected_lua, '\n'))
		nvim:buf_set_option(0, 'filetype', 'markdown')
		assert.nvim(nvim).Not.has_extmarks_at(4, 5, 'lua')

		-- Move Lua line out of code block
		nvim:cmd({cmd = 'move', range = {5}, args = {3}}, {})

		local given = vim.fn.join(nvim:buf_get_lines(0, 0, -2, true), '\n')
		assert.is.equal(markdown_with_injected_lua, given)

		assert.nvim(nvim).has_extmarks_at(3, 5, 'lua')
	end)
end)
