vim.b.format_opts = {
    filter = function(client) return client.name == 'null-ls' end,
}
