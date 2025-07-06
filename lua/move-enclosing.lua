local M = {}

-- Reverse a bracket
local reverse_bracket = {}
reverse_bracket[")"] = "("
reverse_bracket["]"] = "["
reverse_bracket["}"] = "{"
reverse_bracket['"'] = '"'
reverse_bracket["'"] = "'"

-- Move character in "from" to "to"
---@param str string
---@param from integer
---@param to integer
---@return string
local move_char = function(str, from, to)
  local str_split = string.sub(str, 1, from - 1)
  str_split = str_split .. string.sub(str, from + 1, to)
  str_split = str_split .. string.sub(str, from, from)
  str_split = str_split .. string.sub(str, to + 1)

  return str_split
end

-- Return true if specific open and close strings are balanced
---@param str string
---@param open string
---@param close string
---@return boolean
local is_balanced_pair = function(str, open, close)
  local balance = 0
  local same = open == close
  for i = 1, string.len(str) do
    local c = string.sub(str, i, i)
    if c == open then
      balance = balance + 1
      -- In the case that the open and closed string are the same,
      -- just return balanced if the number we see is even
      if same then
        balance = balance % 2
      end
    elseif c == close then
      balance = balance - 1
    end

    if balance < 0 then
      return false
    end
  end

  return balance == 0
end

--Return true if substring is balanced
---@param str string
---@return boolean
local is_balanced = function(str)
  if not is_balanced_pair(str, "(", ")") then
    return false
  end
  if not is_balanced_pair(str, "[", "]") then
    return false
  end
  if not is_balanced_pair(str, "{", "}") then
    return false
  end
  if not is_balanced_pair(str, "'", "'") then
    return false
  end
  if not is_balanced_pair(str, '"', '"') then
    return false
  end

  return true
end

-- Find the next closing match from "start"
---@param str string
---@param cursor integer
---@param start integer
---@return integer?
local find_next = function(str, cursor, start)
  for i = start, string.len(str) do
    -- Find the next match
    local position, _, match = string.find(str, "([])}\"'])", i)

    -- See if there is an unbalanced string between the cursor
    -- and the match
    local substring = string.sub(str, cursor + 1, position)
    if is_balanced_pair(substring, reverse_bracket[match], match) then
      goto continue
    end

    -- It also needs to be unbalanced in the other direction
    substring = string.sub(str, 1, cursor)
    if is_balanced_pair(substring, reverse_bracket[match], match) then
      goto continue
    else
      return position
    end

    ::continue::
  end
end

-- Move match with to encompass next word
-- For example, if moving parens do ()here -> (here)
---@param line string
---@param position integer
---@param find_space boolean
---@return boolean
local move_match = function(line, position, find_space)
  local next_punctuation = nil
  local next_word = nil

  -- Find the last thing before a space after the closing parenthesis
  local next_space = string.find(line, "%S%s", position + 1)
    or string.find(line, "%S$", position + 1)

  if not find_space then
    -- Find the next punctuation
    next_punctuation = string.find(line, "%p", position + 1)
      or string.find(line, "%p$", position + 1)

    -- Find the end of the next word
    next_word = string.find(line, "%w%W", position + 1)
      or string.find(line, "%w$", position + 1)
  end

  -- Exit if next_space is nil
  if not next_space then
    return false
  end

  -- At minimum, we are going to the "next space"
  local position_bracket = next_space

  -- Check if next_punctuation or next_word comes before
  if next_punctuation then
    position_bracket = math.min(next_punctuation, position_bracket)
  end
  if next_word then
    position_bracket = math.min(next_word, position_bracket)
  end

  -- Put it in position_bracket unless making the inner string unbalanced
  -- If stopped because of making an unbalanced string, keep moving until the
  -- string is balanced again
  -- If position_bracket is in the original space, try to move it one space
  -- over to start with
  position_bracket = math.max(position_bracket, position + 1)
  for i = position_bracket, string.len(line) do
    -- New line with moved closing bracket
    local new_line = move_char(line, position, i)

    -- Check if new line is balanced, if so, write line
    if is_balanced(string.sub(new_line, position, i - 1)) then
      vim.api.nvim_set_current_line(new_line)
      return true
    end
  end

  return false
end

-- Pattern match different types of closing pair and move them
---@param find_space boolean
local move_closing = function(find_space)
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] -- x-axis of cursor

  -- Find next match
  for i = col + 1, string.len(line) do
    local pos = find_next(line, col, i)
    -- If there is no match, continue to the next loop
    if not pos then
      goto continue
    end

    -- Otherwise try to move it
    if move_match(line, pos, find_space) then
      break
    end

    ::continue::
  end
end

---@param rhs string
---@param callable function
---@param find_space boolean
local map = function(rhs, callable, find_space)
  vim.keymap.set({ "n", "i" }, rhs, function()
    callable(find_space)
  end, { desc = "Move parenthesis around next word" })
end

---@param opts table?
M.setup = function(opts)
  opts = opts or {}
  opts.word_keymap = opts.word_keymap or "<C-E>"
  opts.WORD_keymap = opts.WORD_keymap or "<C-S-E>"

  map(opts.word_keymap, move_closing, false)
  map(opts.WORD_keymap, move_closing, true)
end

M._is_balanced_pair = is_balanced_pair
M._is_balanced = is_balanced
M._find_next = find_next
M._move_match = move_match

return M
