vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("custom-highlight-yank", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  desc = "Restore cursor to file position in previous editing session",
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      vim.api.nvim_win_set_cursor(0, mark)
      vim.schedule(function()
        vim.cmd "normal! zz"
      end)
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  desc = "No auto continue comments on new line",
  group = vim.api.nvim_create_augroup("no_auto_comment", { clear = true }),
  callback = function()
    vim.opt_local.formatoptions:remove { "c", "r", "o" }
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  desc = "Disable line numbers in terminal buffers",
  group = vim.api.nvim_create_augroup("custom-term-open", { clear = true }),
  callback = function()
    vim.o.number = false
    vim.o.relativenumber = false
  end,
})

vim.api.nvim_create_user_command("PackClean", function()
  local inactive = vim.iter(vim.pack.get())
    :filter(function(x)
      return not x.active
    end)
    :map(function(x)
      return x.spec.name
    end)
    :totable()
  if #inactive == 0 then
    vim.notify("No inactive plugins to remove", vim.log.levels.INFO)
    return
  end
  vim.pack.del(inactive)
  vim.notify("Removed: " .. table.concat(inactive, ", "), vim.log.levels.INFO)
end, { desc = "Remove plugins not in vim.pack.add() specs" })
