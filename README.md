# move-enclosing.nvim

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

## Installation

Install it like any other plugin. For example, if using `LazyVim` as your package manager:

```lua
  {
    'AndresYague/move-enclosing.nvim',
    opts = {
      word_keymap = '<C-E>', -- Move enclosing to the end of next word
      WORD_keymap = '<C-S-E>', -- Move enclosing to the end of next WORD
    },
  }
```

## Configuration

Right now only `word_keymap` and `WORD_keymap` can be configured. This must be an entry in a table passed to `setup`. Such as:

```lua
  require('print-debug').setup {
    word_keymap = '<C-E>',
    WORD_keymap = '<C-S-E>',
  }
```

## Inspiration

This plugin is inspired by https://github.com/jiangmiao/auto-pairs.git
