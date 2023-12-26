local M = {}

local language_extensions = {
  python = "py"
}

local convert_to_script = function(filepath)
  local metadata = vim.json.decode(io.open(filepath, "r"):read "a")["metadata"]

  local language = metadata.kernelspec.language
  local extension = language_extensions[language]


  local script_filepath = vim.fn.fnamemodify(filepath, ':r') .. '.' .. extension

  vim.fn.system('python3 ../../python/ipynb/convert.py ' .. filepath .. ' ' .. script_filepath)

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
