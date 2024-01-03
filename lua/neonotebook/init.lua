local M = {}

local language_extensions = {
  python = ".py"
}

local outputs_extension = '.ipyout'
local outputs_text_extension = '.ipyout.out'

local remove_undo = function()
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
end

local convert_notebook = function(filepath)
  local metadata = vim.json.decode(io.open(filepath, "r"):read "a")["metadata"]

  local language = metadata.kernelspec.language
  local extension = language_extensions[language]

  local script_filepath = vim.fn.fnamemodify(filepath, ':r') .. extension
  local outputs_filepath = vim.fn.fnamemodify(filepath, ':r') .. outputs_extension

  require('neonotebook.convert').convert_notebook(filepath, script_filepath, outputs_filepath)

  if vim.fn.filereadable(script_filepath) then
    local script_content = vim.fn.readfile(script_filepath)

    -- Replace the buffer content with the script content
    vim.api.nvim_buf_set_lines(0, 0, -1, false, script_content)
  else
    error "Couldn't find script file."
    return
  end

  vim.api.nvim_create_autocmd({ "BufWriteCmd", "FileWriteCmd" }, {
    pattern = "<buffer>",
    group = "neonotebook",
    callback = function(ev)
      convert_script(ev.match, output_extension)
    end,
  })

  --vim.api.nvim_command("setlocal fenc=utf-8 ft=" .. language)
  vim.opt_local.fenc='utf-8'
  vim.opt_local.ft=language


  remove_undo()

  -- First time we enter the buffer redraw. Don't know why but jupytext.vim was
  -- doing it. Apply Chesterton's fence principle.
  --vim.api.nvim_create_autocmd("BufEnter", {
  --  pattern = "<buffer>",
  --  group = "neonotebook",
  --  once = true,
  --  command = "redraw",
  --})
end

local convert_outputs = function(filepath)
  local out_text_filepath = vim.fn.fnamemodify(filepath, ':r') .. outputs_text_extension

  require('neonotebook.convert').convert_outputs(filepath, out_text_filepath)

  if vim.fn.filereadable(out_text_filepath) then
    local text_content = vim.fn.readfile(out_text_filepath)

    -- Replace the buffer content with the script content
    vim.api.nvim_buf_set_lines(0, 0, -1, false, text_content)
  else
    error "Couldn't find out text file."
    return
  end

  vim.bo.modifiable = false
  vim.bo.buftype = 'nowrite'
  vim.opt_local.fenc = 'utf-8'
  vim.opt_local.ft = 'nn_out'
  vim.opt_local.cursorline = false


  remove_undo()

  -- First time we enter the buffer redraw. Don't know why but jupytext.vim was
  -- doing it. Apply Chesterton's fence principle.
  --vim.api.nvim_create_autocmd("BufEnter", {
  --  pattern = "<buffer>",
  --  group = "neonotebook",
  --  once = true,
  --  command = "redraw",
  --})
end


M.setup = function(config)
  vim.validate(config,'table')

  vim.api.nvim_create_augroup("neonotebook", { clear = true })
  vim.api.nvim_create_autocmd("BufReadCmd", {
    pattern = { "*.ipynb" },
    group = "neonotebook",
    callback = function(ev)
      convert_notebook(ev.match)
    end,
  })

  vim.api.nvim_create_autocmd("BufReadCmd", {
    pattern = { "*.ipyout" },
    group = "neonotebook",
    callback = function(ev)
      convert_outputs(ev.match)
    end,
  })
end

return M
