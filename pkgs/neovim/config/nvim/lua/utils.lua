local M = {}

function M.map(mode, lhs, rhs, options)
  local opts = {
    silent = true,
  }
  if type(options) == 'table' then
    if type(options.remap) == 'boolean' then
      opts.remap = options.remap
    end

    if type(options.silent) == 'boolean' then
      opts.silent = options.silent
    end

    if type(options.expr) == 'boolean' then
      opts.expr = options.expr
    end

    if options.buffer ~= nil then
      opts.buffer = options.buffer
    end
  end
  vim.keymap.set(mode, lhs, rhs, opts)
end

return M
