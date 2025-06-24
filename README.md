# move-enclosing.nvim

Simple plugin that allows to move enclosing pairs around the next word. For example, with the cursor inside of the parenthesis in `()lorem ipsum` and pressing the mapped keyword, default `<C-E>`, makes the following change to the text:

    ()lorem ipsum -> (lorem) ipsum

Pairs are moved from inside out, but they are never moved to a place that would make other pairs unbalanced, so for example, with the cursor inside of the parenthesis in `[()lorem] ipsum` and pressing the mapped keyword 3 consecutive times, makes the change:

    [()lorem] ipsum -> [(lorem)] ipsum -> [(lorem) ipsum] -> [(lorem ipsum)]

Another example is (cursor inside of the brackets):

    []lorem(()) ipsum -> [lorem](()) ipsum -> [lorem(())] ipsum -> [lorem(()) ipsum]

Right now, the pair moves to the end of a vim `word`, therefore

    ()lorem_ ipsum -> (lorem)_ ipsum -> (lorem_) ipsum -> (lorem_ ipsum)

## Installation

Install it like any other plugin. For example, if using `LazyVim` as your package manager:

```lua
  {
    "AndresYague/MoveEnclosing.nvim",
    opts = {
      keymap = "<C-E>",
    },
  },
```

## Configuration

Right now only the `keymap` can be configured. This must be an entry in a table passed to `setup`. Such as:

```lua
require("move-enclosing").setup({keymap = "<C-E>"})
```

## Inspiration

This plugin is inspired by https://github.com/jiangmiao/auto-pairs.git
