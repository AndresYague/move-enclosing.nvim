# move-enclosing.nvim

## Description

Simple plugin that allows to move enclosing pairs around the next word. For example, with the cursor inside of the parenthesis in `()lorem ipsum` and pressing the mapped keyword, default `<C-E>`, makes the following change to the text:

    ()lorem ipsum -> (lorem) ipsum

Pairs are moved from inside out, but they are never moved to a place that would make other pairs unbalanced, so for example, with the cursor inside of the parenthesis in `[()lorem] ipsum` and pressing the mapped keyword 3 consecutive times, makes the change:

    [()lorem] ipsum -> [(lorem)] ipsum -> [(lorem) ipsum] -> [(lorem ipsum)]

Another example is (cursor inside of the brackets):

    []lorem(()) ipsum -> [lorem](()) ipsum -> [lorem(())] ipsum -> [lorem(()) ipsum]

The pair moves to the end of a vim `word`, when using `word_keymap`

    ()lorem_ ipsum -> (lorem)_ ipsum -> (lorem_) ipsum -> (lorem_ ipsum)

And to the end of a vim `WORD` when using `WORD_keymap`

    ()lorem_ ipsum -> (lorem_) ipsum -> (lorem_ ipsum)

If the end of a vim `WORD` is the end of the string and would leave the string unbalanced, then keep walking back until a suitable place is found

    [()lorem_] -> [(lorem_)]

## Treesitter

This plugin also has `Treesitter` support. In languages with a `Treesitter` grammar, the `word` keymap will move the enclosing pair to the end of the next `Treesitter` node. This behaviour will not be applied to the `WORD` keymap. It can also be disabled for the `word` keymap with the `use_ts` option. There is also a function `toggle_ts` exposed through the API to toggle this behavour.

## Installation

Install it like any other plugin. For example, if using `LazyVim` as your package manager:


```lua
  {
    'AndresYague/move-enclosing.nvim',
    opts = {},
  }
```

The default options are

```lua
  {
    'AndresYague/move-enclosing.nvim',
    opts = {
      word_keymap = '<C-E>', -- Move enclosing to the end of next word
      WORD_keymap = '<C-S-E>', -- Move enclosing to the end of next WORD
      use_ts = true, -- Whether to use the Treesitter support
    },
  }
```

It can also be initialized through a `setup` call:

```lua
  require('move-enclosing').setup {}
```

or, with options

```lua
  require('move-enclosing').setup {
      word_keymap = '<C-E>', -- Move enclosing to the end of next word
      WORD_keymap = '<C-S-E>', -- Move enclosing to the end of next WORD
      use_ts = true, -- Whether to use the Treesitter support
  }
```

## Inspiration

This plugin is inspired by https://github.com/jiangmiao/auto-pairs.git
