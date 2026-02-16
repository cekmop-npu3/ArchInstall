vim.diagnostic.config({
  virtual_text = true,
  virtual_lines = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})


---@param ev {id: number, event: string, group: number|nil, file: string, match: string, buf: number, data: any}
---@return nil
local function lspCallback(ev)
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
        return
    end
    if client:supports_method('textDocument/completion') then
        local chars = {}; for i = 32, 126 do table.insert(chars, string.char(i)) end
        client.server_capabilities.completionProvider.triggerCharacters = chars
        vim.lsp.completion.enable(true, client.id, ev.buf, {autotrigger=true})
    elseif client:supports_method('textDocument/diagnostic') then
        vim.lsp.diagnostic.enable(not vim.diagnostic.is_enabled())
    end
end


vim.api.nvim_create_autocmd('LspAttach', {
    callback=lspCallback
})

