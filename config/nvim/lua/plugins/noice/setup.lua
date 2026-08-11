local M = {}

local function remove_hover_signature(contents)
    local lines = vim.lsp.util.convert_input_to_markdown_lines(contents)

    if not lines or #lines == 0 then
        return nil
    end

    local result = {}
    local i = 1
    local found_function = false

    while i <= #lines do
        local line = lines[i]

        if not found_function
            and line:match("^###%s+function%s*$")
        then
            found_function = true
            i = i + 1

            local in_code_block = false

            while i <= #lines do
                local current = lines[i]

                if current:match("^```") then
                    if in_code_block then
                        i = i + 1
                        break
                    else
                        in_code_block = true
                    end
                end

                i = i + 1
            end

            while i <= #lines do
                local current = lines[i]

                if current:match("^%s*$")
                    or current:match("^%-%-%-%s*$")
                then
                    i = i + 1
                else
                    break
                end
            end
        else
            table.insert(result, line)
            i = i + 1
        end
    end

    while #result > 0 do
        local first = result[1]

        if first:match("^%s*$")
            or first:match("^%-%-%-%s*$")
        then
            table.remove(result, 1)
        else
            break
        end
    end

    if #result == 0 then
        return nil
    end

    return {
        kind = "markdown",
        value = table.concat(result, "\n"),
    }
end

function M.setup()
    local ok_noice, noice = pcall(require, "noice")

    if not ok_noice then
        return
    end

    local popup_winhighlight = {
        Normal = "PopupMenuBody",
        NormalFloat = "PopupMenuBody",
        FloatBorder = "PopupMenuBorder",
    }

    noice.setup({
        views = {
            popup = {
                win_options = {
                    winhighlight = popup_winhighlight,
                },
            },

            hover = {
                relative = "cursor",
                anchor = "SW",
                position = {
                    row = 0,
                    col = 4,
                },
                scrollbar = false,
                size = {
                    width = "50%",
                    height = "30%",
                },
                win_options = {
                    winhighlight = popup_winhighlight,
                },
            },
        },

        lsp = {
            override = {
                ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                ["vim.lsp.util.stylize_markdown"] = true,
                ["cmp.entry.get_documentation"] = true,
            },

            signature = {
                enabled = true,
            },
        },

        presets = {
            command_palette = true,
            long_message_to_split = true,
            lsp_doc_border = true,
        },

        messages = {
            enabled = false,
        },
    })

    local signature = require("noice.lsp.signature")
    local original_on_signature = signature.on_signature

    signature.on_signature = function(err, result, ctx, config)
        if err or not result or not result.signatures then
            return original_on_signature(err, result, ctx, config)
        end

        local client = vim.lsp.get_client_by_id(ctx.client_id)

        if not client or client.name ~= "clangd" then
            return original_on_signature(err, result, ctx, config)
        end

        local bufnr = ctx.bufnr
        local ft = vim.bo[bufnr].filetype

        if ft ~= "c"
            and ft ~= "cpp"
            and ft ~= "objc"
            and ft ~= "objcpp"
        then
            return original_on_signature(err, result, ctx, config)
        end

        local win = vim.api.nvim_get_current_win()

        if not vim.api.nvim_win_is_valid(win) then
            return original_on_signature(err, result, ctx, config)
        end

        local cursor = vim.api.nvim_win_get_cursor(win)
        local row = cursor[1] - 1
        local col = cursor[2]

        local line = vim.api.nvim_buf_get_lines(
            bufnr,
            row,
            row + 1,
            false
        )[1]

        if not line then
            return original_on_signature(err, result, ctx, config)
        end

        local before_cursor = line:sub(1, col + 1)
        local open_paren = before_cursor:find("(", 1, true)

        if not open_paren then
            return original_on_signature(err, result, ctx, config)
        end

        local before_paren = line:sub(1, open_paren - 1)
        local name_start = before_paren:find("[%w_~]+%s*$")

        if not name_start then
            return original_on_signature(err, result, ctx, config)
        end

        local hover_params = {
            textDocument = {
                uri = vim.uri_from_bufnr(bufnr),
            },
            position = {
                line = row,
                character = name_start - 1,
            },
        }

        client:request(
            "textDocument/hover",
            hover_params,
            function(hover_err, hover_result)
                vim.schedule(function()
                    if hover_err
                        or not hover_result
                        or not hover_result.contents
                    then
                        return original_on_signature(
                            err,
                            result,
                            ctx,
                            config
                        )
                    end

                    local documentation =
                        remove_hover_signature(
                            hover_result.contents
                        )

                    if not documentation then
                        return original_on_signature(
                            err,
                            result,
                            ctx,
                            config
                        )
                    end

                    for _, sig in ipairs(result.signatures) do
                        sig.documentation = documentation
                    end

                    original_on_signature(
                        nil,
                        result,
                        ctx,
                        config
                    )
                end)
            end
        )
    end

    require("plugins.noice.keymaps").setup()
end

return M

