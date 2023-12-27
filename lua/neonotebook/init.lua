local M = {}

local language_extensions = {
  python = "py"
}

local convert_to_script = function(filepath)
  local metadata = vim.json.decode(io.open(filepath, "r"):read "a")["metadata"]

  local language = metadata.kernelspec.language
  local extension = language_extensions[language]


  local script_filepath = vim.fn.fnamemodify(filepath, ':r') .. '.' .. extension

  local plugin_dir = require('utils').get_plugin_dir()

  local command = 'python3 convert.py ' .. filepath .. ' ' .. script_filepath
  local output = vim.fn.system(command)

  if vim.v.shell_error ~= 0 then
    print(output)
    vim.api.nvim_err_writeln(command .. ": " .. vim.v.shell_error)
    return
  end

  if vim.fn.filereadable(script_filepath) then
    local script_content = vim.fn.readfile(script_filepath)

    -- Replace the buffer content with the jupytext content
    vim.api.nvim_buf_set_lines(0, 0, -1, false, script_content)
  else
    error "Couldn't find script file."
    return
  end

  vim.api.nvim_create_autocmd({ "BufWriteCmd", "FileWriteCmd" }, {
    pattern = "<buffer>",
    group = "jupytext-nvim",
    callback = function(ev)
      write_to_ipynb(ev.match, output_extension)
    end,
  })

  vim.api.nvim_command("setlocal fenc=utf-8 ft=" .. language)

  -- In order to make :undo a no-op immediately after the buffer is read, we
  -- need to do this dance with 'undolevels'.  Actually discarding the undo
  -- history requires performing a change after setting 'undolevels' to -1 and,
  -- luckily, we have one we need to do (delete the extra line from the :r
  -- command)
  -- (Comment straight from goerz/jupytext.vim)
  local levels = vim.o.undolevels
  vim.o.undolevels = -1
  vim.api.nvim_command "silent delete"
  vim.o.undolevels = levels

  -- First time we enter the buffer redraw. Don't know why but jupytext.vim was
  -- doing it. Apply Chesterton's fence principle.
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "<buffer>",
    group = "neonotebook",
    once = true,
    command = "redraw",
  })
end

M.setup = function(config)
  vim.validate(config,'table')

  vim.api.nvim_create_augroup("neonotebook", { clear = true })
  vim.api.nvim_create_autocmd("BufReadCmd", {
    pattern = { "*.ipynb" },
    group = "neonotebook",
    callback = function(ev)
      convert_to_script(ev.match)
    end,
  })
end

return M
