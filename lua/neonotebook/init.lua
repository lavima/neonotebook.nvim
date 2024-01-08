local M = {}

local language_extensions = {
  python = ".py"
}

local outputs_extension = '.out'

local remove_undo = function()
  -- In order to make :undo a no-op, we need to do this dance with 'undolevels'.  
	-- Discarding the undo history requires performing a change after setting 'undolevels' to -1 and,
  -- luckily, we have one we need to do delete the extra line at the beginning
  local levels = vim.o.undolevels
  vim.o.undolevels = -1
  vim.api.nvim_command "silent delete"
  vim.o.undolevels = levels
end

local convert_notebook = function(filepath)
	-- Load the entire notebook
	local json = vim.json.decode(io.open(filepath):read('a'))

  local metadata = json["metadata"]

  local language = metadata.kernelspec.language
  local extension = language_extensions[language]

  local script_filepath = filepath .. extension
  local outputs_filepath = filepath .. outputs_extension

  require('neonotebook.convert').convert_notebook(json, script_filepath, outputs_filepath)

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

  -- This doesn't appear to be needed. Keep as comment for now
  --vim.api.nvim_create_autocmd("BufEnter", {
  --  pattern = "<buffer>",
  --  group = "neonotebook",
  --  once = true,
  --  command = "redraw",
  --})
end


M.setup = function(config)
  vim.validate(config,'table')

	vim.filetype.add({ extension = { out = 'output' }, pattern = { ['*.ipynb.out'] = { 'output', { priority=100 } } } })

  vim.api.nvim_create_augroup("neonotebook", { clear = true })
  vim.api.nvim_create_autocmd("BufReadCmd", {
    pattern = { "*.ipynb" },
    group = "neonotebook",
    callback = function(ev)
      convert_notebook(ev.match)
    end,
  })

end

return M
