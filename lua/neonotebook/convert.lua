convert = {}

--local convert_script = require('neonotebook.utils').get_lua_dir() .. '../../python/convert.py'

--local shellescape = vim.fn.shellescape

--local execute = function(command)
--  local output = vim.fn.system(command)
--  if vim.v.shell_error ~= 0 then
--    vim.api.nvim_err_writeln(command .. ": " .. output .. ": " .. vim.v.shell_error)
--    return
--  end
--end

local percent_start = '# %%'
local comment_start = '#'

convert.convert_notebook = function(nb, script_filepath, outputs_filepath)
	local script_content = {''}
	local output_content = {''}

	local cells = nb['cells']

	for i,cell in ipairs(cells) do
		local cell_type = cell['cell_type']
		local cell_source = cell['source']

		if cell_type == 'code' then
			local execution_count = cell['execution_count']
			local header = percent_start .. ' execution_count=' .. execution_count
			script_content[#script_content+1] = header 

			local cell_outputs = cell['outputs']
			if #cell_outputs > 0 then 
				output_content[#output_content+1] = header

				for j,cell_output in ipairs(cell_outputs) do
					local output_type = cell_output['output_type']
					if output_type == 'stream' then
						output_content[#output_content+1] = table.concat(cell_output['text'])
					elseif output_type == 'display_data' then
						local image = require('image').from_data(cell_output['data']['image/png'])
						output_content[#output_content+1] = '!image=' .. image.path .. '\n'
					end
				end
			end

			script_content[#script_content+1] = table.concat(cell_source)

		else
			script_content[#script_content+1] = percent_start .. ' [' .. cell_type ..']'

			table.insert(cell_source, 1, comment_start .. ' ')
			script_content[#script_content+1] = table.concat(cell_source):gsub('\n', '\n' .. comment_start .. ' ')
		end
	end

	local script_file = io.open(script_filepath,'w+')
	script_file:write(table.concat(script_content, '\n'))
	io.close(script_file)
	local outputs_file = io.open(outputs_filepath,'w+')
	outputs_file:write(table.concat(output_content, '\n'))
	io.close(outputs_file)
end

convert.convert_script = function(filepath, outputs_filepath, ipynb_filepath)
  --local command = 'python3 ' .. shellescape(convert_script) .. ' ' .. shellescape(filepath) .. 
  --  ' --cell_outputs ' .. outputs_filepath .. ' --output ' .. shellescape(script_filepath)
  --execute(command)
end

return convert
