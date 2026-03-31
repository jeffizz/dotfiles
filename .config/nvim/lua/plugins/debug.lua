return {
  -- Debugger plugin for Neovim (DAP - Debug Adapter Protocol)
  'mfussenegger/nvim-dap',
  -- Only load this plugin if not in VSCode integration mode
  cond = not vim.g.vscode,
  -- Dependencies required for nvim-dap and its UI
  dependencies = {
    -- Provides a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui, handles async operations
    'nvim-neotest/nvim-nio',

    -- Manages and installs debug adapters automatically
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Go-specific debugger configuration
    'leoluz/nvim-dap-go',

    -- Displays debug information as virtual text in the buffer
    'theHamsta/nvim-dap-virtual-text',
  },
  keys = {
    -- Basic debugging keymaps, feel free to change to your liking!
    {
      '<leader>dc',
      function()
        require('dap').continue()
      end,
      desc = 'Debug: Start/Continue',
    },
    {
      '<leader>di',
      function()
        require('dap').step_into()
      end,
      desc = 'Debug: Step Into',
    },
    {
      '<leader>do',
      function()
        require('dap').step_over()
      end,
      desc = 'Debug: Step Over',
    },
    {
      '<leader>dO',
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: Step Out',
    },
    {
      '<leader>dx',
      function()
        require('dap').terminate()
      end,
      desc = 'Debug: Terminate',
    },
    {
      '<leader>b',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Debug: Toggle Breakpoint',
    },
    {
      '<leader>B',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Debug: Set Conditional Breakpoint',
    },
    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    {
      '<leader>u',
      function()
        require('dapui').toggle()
      end,
      desc = 'Debug: Toggle UI',
    },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'
    local virtual_text = require 'nvim-dap-virtual-text'

    -- Configure mason-nvim-dap for automatic debug adapter installation
    require('mason-nvim-dap').setup {
      -- Automatically install missing debug adapters
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- Ensure these debug adapters are installed
      -- (You'll need to check that you have the required external tools installed)
      ensure_installed = {
        -- Delve for Go debugging
        'delve',
        -- PWA Node.js debug adapter for JavaScript/TypeScript
        'js-debug-adapter',
      },
    }

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      -- Feel free to remove or use ones that you like more!
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '➜(',
          step_over = '⬇︎',
          step_out = '⬆',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
      -- Define the layout of the DAP UI windows
      layouts = {
        {
          elements = {
            { id = 'scopes', size = 0.4 },
            { id = 'breakpoints', size = 0.2 },
            { id = 'stacks', size = 0.2 },
            { id = 'watches', size = 0.2 },
          },
          size = 40,
          position = 'right',
        },
        {
          elements = {
            { id = 'repl', size = 0.5 },
            { id = 'console', size = 0.5 },
          },
          size = 10,
          position = 'bottom',
        },
      },
    }

    -- Optional: Change breakpoint icons and highlights (currently commented out)
    -- This section uses Nerd Fonts for custom icons if available.
    -- vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
    -- vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
    -- local breakpoint_icons = vim.g.have_nerd_font
    --     and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
    --   or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
    -- for type, icon in pairs(breakpoint_icons) do
    --   local tp = 'Dap' .. type
    --   local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
    --   vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
    -- end

    -- Auto-open DAP UI when debugging starts and close when it ends
    dap.listeners.after.event_initialized['dapui_config'] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated['dapui_config'] = function()
      dapui.close()
    end
    dap.listeners.before.event_exited['dapui_config'] = function()
      dapui.close()
    end

    -- Configure nvim-dap-virtual-text
    virtual_text.setup {
      enabled = true,
      commented = false, -- Whether to show virtual text in comments too
      only_first_definition = true,
      all_references = false,
      virt_text_pos = 'eol', -- Display at the end of the line (can be 'inline')
    }

    -- Go specific DAP configuration (using nvim-dap-go)
    require('dap-go').setup {
      delve = {
        -- On Windows, delve must be run attached or it crashes.
        -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
        detached = vim.fn.has 'win32' == 0,
      },
    }

    -- Configure the PWA Node.js debug adapter for JavaScript/TypeScript
    require('dap').adapters['pwa-node'] = {
      type = 'server',
      host = 'localhost',
      port = '${port}',
      executable = {
        command = 'js-debug-adapter', -- Use `:Mason` to install this adapter
        args = { '${port}' },
      },
    }

    -- Define DAP configurations for JavaScript and TypeScript languages
    for _, language in ipairs { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' } do
      dap.configurations[language] = {
        -- Launch configuration for the current file
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Launch current file',
          program = '${file}',
          cwd = '${workspaceFolder}',
          console = 'integratedTerminal',
          skipFiles = { '<node_internals>/**' },
          stopOnEntry = true,
        },
        -- Attach configuration to a running Node.js process
        {
          type = 'pwa-node',
          request = 'attach',
          name = 'Attach to running Node process',
          processId = require('dap.utils').pick_process,
          cwd = '${workspaceFolder}',
          skipFiles = { '<node_internals>/**' },
        },
      }
    end
  end,
}
