# Headwind.nvim

Headwind.nvim is a modern and lightweight Neovim plugin designed to streamline your development workflow. It provides a seamless experience for managing and organizing your code, offering powerful features to enhance productivity and code quality.

## Features

- **Code Organization**: Automatically sort and organize your code for better readability.
- **Customizable**: Tailor the plugin to fit your specific needs with flexible configuration options.
- **Lightweight**: Minimal performance overhead, ensuring a smooth and fast coding experience.
- **Seamless Integration**: Works effortlessly with your existing Neovim setup.

## Installation

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

Add the following to your `init.lua` or `init.vim`:

```lua
use {
    'gwydion67/headwind.nvim',
    config = function()
        require('headwind').setup({
            -- Add your configuration here
        })
    end
}
```

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

Add the following to your `init.lua`:

```lua
require('lazy').setup({
    {
        'gwydion67/headwind.nvim',
        config = function()
            require('headwind').setup({
                -- Add your configuration here
            })
        end
    }
})
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

Add the following to your `.vimrc` or `init.vim`:

```vim
Plug 'gwydion67/headwind.nvim'

" After installation, configure the plugin
lua << EOF
require('headwind').setup({
    -- Add your configuration here
})
EOF
```

## Usage

Once installed, Headwind.nvim can be triggered using the following commands:

- `:HeadwindSort` - Automatically sort and organize your code.
- `:HeadwindConfig` - Open the configuration file for customization.

You can also map these commands to your preferred keybindings for quick access.

## Configuration

Headwind.nvim provides a simple and intuitive configuration interface. Below is an example configuration:

```lua
require('headwind').setup({
    sort_order = 'alphabetical', -- Options: 'alphabetical', 'custom'
    enable_logging = true,       -- Enable or disable logging
    custom_sort = {              -- Define your custom sort order
        'imports',
        'constants',
        'functions',
        'variables'
    }
})
```

## Contributing

Contributions are welcome! If you encounter any issues or have feature requests, feel free to open an issue or submit a pull request on the [GitHub repository](https://github.com/gwydion67/headwind.nvim).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgements

Special thanks to the Neovim community for their continuous support and inspiration.

---
Elevate your Neovim experience with Headwind.nvim and enjoy a more organized and efficient coding workflow!

