local util = require 'lspconfig.util'

local texlab_build_status = {
  [0] = 'Success',
  [1] = 'Error',
  [2] = 'Failure',
  [3] = 'Cancelled',
}

local texlab_forward_status = {
  [0] = 'Success',
  [1] = 'Error',
  [2] = 'Failure',
  [3] = 'Unconfigured',
}

local function buf_build(bufnr)
  bufnr = util.validate_bufnr(bufnr)
  local texlab_client = util.get_active_client_by_name(bufnr, 'texlab')
  local pos = vim.api.nvim_win_get_cursor(0)
  local params = {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    position = { line = pos[1] - 1, character = pos[2] },
  }
  if texlab_client then
    texlab_client.request('textDocument/build', params, function(err, result)
      if err then
        error(tostring(err))
      end
      vim.notify('Build ' .. texlab_build_status[result.status])
    end, bufnr)
  else
    vim.notify 'method textDocument/build is not supported by any servers active on the current buffer'
  end
end

local function buf_search(bufnr)
  bufnr = util.validate_bufnr(bufnr)
  local texlab_client = util.get_active_client_by_name(bufnr, 'texlab')
  local pos = vim.api.nvim_win_get_cursor(0)
  local params = {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    position = { line = pos[1] - 1, character = pos[2] },
  }
  if texlab_client then
    texlab_client.request('textDocument/forwardSearch', params, function(err, result)
      if err then
        error(tostring(err))
      end
      vim.notify('Search ' .. texlab_forward_status[result.status])
    end, bufnr)
  else
    vim.notify 'method textDocument/forwardSearch is not supported by any servers active on the current buffer'
  end
end

local function on_clean_error(err, result)
  if err then
    error(tostring(err))
  end
  vim.notify('Cleaned build files.')
end

local function buf_clean_auxiliary(bufnr)
  bufnr = util.validate_bufnr(bufnr)
  local texlab_client = util.get_active_client_by_name(bufnr, 'texlab')
  local params = {
    command='texlab.cleanAuxiliary',
    arguments = { uri = vim.uri_from_bufnr(bufnr) },
  }
  if texlab_client then
    texlab_client.request('workspace/executeCommand', params, on_clean_error, bufnr)
  else
    vim.notify 'Could not find the texlab executable.'
  end
end

local function buf_clean_artifacts(bufnr)
  bufnr = util.validate_bufnr(bufnr)
  local texlab_client = util.get_active_client_by_name(bufnr, 'texlab')
  local params = {
    command='texlab.cleanArtifacts',
    arguments = { uri = vim.uri_from_bufnr(bufnr) },
  }
  if texlab_client then
    texlab_client.request('workspace/executeCommand', params, on_clean_error, bufnr)
  else
    vim.notify 'Could not find the texlab executable.'
  end
end

local function buf_cancel_build(bufnr)
  bufnr = util.validate_bufnr(bufnr)
  local texlab_client = util.get_active_client_by_name(bufnr, 'texlab')
  local params = { command = 'texlab.cancelBuild', }
  if texlab_client then
    texlab_client.request('workspace/executeCommand', params, function(err, result)
      if err then
        error(tostring(err))
      else
        vim.notify('Cancelled build command.') 
      end
    end, bufnr)
  else
    vim.notify 'Could not find the texlab executable.'
  end

end

-- bufnr isn't actually required here, but we need a valid buffer in order to
-- be able to find the client for buf_request.
-- TODO find a client by looking through buffers for a valid client?
-- local function build_cancel_all(bufnr)
--   bufnr = util.validate_bufnr(bufnr)
--   local params = { token = "texlab-build-*" }
--   lsp.buf_request(bufnr, 'window/progress/cancel', params, function(err, method, result, client_id)
--     if err then error(tostring(err)) end
--     print("Cancel result", vim.inspect(result))
--   end)
-- end

return {
  default_config = {
    cmd = { 'texlab' },
    filetypes = { 'tex', 'plaintex', 'bib' },
    root_dir = util.root_pattern('.git', '.latexmkrc', '.texlabroot', 'texlabroot', 'Tectonic.toml'),
    single_file_support = true,
    settings = {
      texlab = {
        rootDirectory = nil,
        build = {
          executable = 'latexmk',
          args = { '-pdf', '-interaction=nonstopmode', '-synctex=1', '%f' },
          onSave = false,
          forwardSearchAfter = false,
        },
        auxDirectory = '.',
        forwardSearch = {
          executable = nil,
          args = {},
        },
        chktex = {
          onOpenAndSave = false,
          onEdit = false,
        },
        diagnosticsDelay = 300,
        latexFormatter = 'latexindent',
        latexindent = {
          ['local'] = nil, -- local is a reserved keyword
          modifyLineBreaks = false,
        },
        bibtexFormatter = 'texlab',
        formatterLineLength = 80,
      },
    },
  },
  commands = {
    TexlabBuild = {
      function()
        buf_build(0)
      end,
      description = 'Build the current buffer',
    },
    TexlabForward = {
      function()
        buf_search(0)
      end,
      description = 'Forward search from current position',
    },
    TexlabCleanAuxiliary = {
      function()
        buf_clean_auxiliary(0)
      end,
      description = 'Clean the auxiliary files generated from the build.',
    },
    TexlabCleanArtifacts = {
      function()
        buf_clean_artifacts(0)
      end,
      description = 'Clean all artifacts generated from the build.',
    },
    TexlabCancelBuild = {
      function()
        buf_cancel_build(0)
      end,
      description = 'Cancel the build commands currently running.',
    },
  },
  docs = {
    description = [[
https://github.com/latex-lsp/texlab

A completion engine built from scratch for (La)TeX.

See https://github.com/latex-lsp/texlab/wiki/Configuration for configuration options.
]],
  },
}
