local M = {}

-- Reverse a bracket
local reverse_bracket = {}
reverse_bracket[")"] = "("
reverse_bracket["]"] = "["
reverse_bracket["}"] = "{"
reverse_bracket[">"] = "<"
reverse_bracket['"'] = '"'
reverse_bracket["'"] = "'"
reverse_bracket['`'] = '`'

---Move character in "from" to "to"
---@param str string String to move characters in
---@param from integer Move character from here
---@param to integer Move character here (current index)
---@return string
local move_char = function(str, from, to)
  local str_split = string.sub(str, 1, from - 1)
  str_split = str_split .. string.sub(str, from + 1, to)
  str_split = str_split .. string.sub(str, from, from)
  str_split = str_split .. string.sub(str, to + 1)

  return str_split
end

---Return true if specific open and close strings are balanced
---@param str string String in which to check balance
---@param open string "open" character
---@param close string "close" character
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

    -- Saw more closing strings than opening strings,
    -- we can exit already
    if balance < 0 then
      return false
    end
  end

  return balance == 0
end

---Return true if substring is balanced
---@param str string String to check
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
  if not is_balanced_pair(str, "<", ">") then
    return false
  end
  if not is_balanced_pair(str, "'", "'") then
    return false
  end
  if not is_balanced_pair(str, '"', '"') then
    return false
  end
  if not is_balanced_pair(str, "`", "`") then
    return false
  end

  return true
end

---Find the next closing match from "start"
---@param str string String in which to search closing match
---@param cursor integer Current cursor position
---@param start integer Where to start the search from
---@return integer?
local find_next = function(str, cursor, start)
  for i = start, string.len(str) do
    -- Find the next match
    local position, _, match = string.find(str, "([])}>`\"'])", i)

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

---Find the next position we would try to move the match
---@param line string String to find the position in
---@param position integer Current position (finding the next one)
---@param find_space boolean Try to find next space instead of next non-word character
---@return integer?
local next_position = function(line, position, find_space)
  local next_punctuation = nil
  local next_word = nil

  -- Find the last thing before a space after the closing parenthesis
  -- Otherwise find the end of the line
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
    return nil
  end

  -- At minimum, we are going to the "next space"
  -- which includes the end of the line
  local position_bracket = next_space

  -- Check if next_punctuation or next_word comes before
  if next_punctuation then
    position_bracket = math.min(next_punctuation, position_bracket)
  end
  if next_word then
    position_bracket = math.min(next_word, position_bracket)
  end

  -- If position_bracket is in the original space, try to move it one space
  -- over to start with
  position_bracket = math.max(position_bracket, position + 1)

  return position_bracket
end

---Move match to encompass next word
---For example, if moving parens do ()here -> (here)
---@param line string String to modify
---@param position integer Where to start looking for new position of closing
---@param find_space boolean Find space instead of next non-word character
---@return integer?
local move_match = function(line, position, find_space)
  -- Start looking from "position"
  local from = position

  -- Simple local function to try and rewrite the line (only
  -- if string is balanced). This avoids repetition below
  ---@param rewrite_to integer
  ---@return boolean
  local rewrite_line = function(rewrite_to)
    local new_line = move_char(line, position, rewrite_to)

    -- Put it in position_bracket unless making the inner string unbalanced
    if is_balanced(string.sub(new_line, position, rewrite_to - 1)) then
      vim.api.nvim_set_current_line(new_line)
      return true
    end

    return false
  end

  -- If stopped because of making an unbalanced string, keep moving until
  -- the string is balanced again
  while true do
    local position_bracket = next_position(line, from, find_space)

    if find_space then
      -- If we are finding space, we may need to adjust position_bracket
      if position_bracket then
        -- If position_bracket found, just try to mvoe the closing
        -- string there, normally
        local was_moved = rewrite_line(position_bracket)
        if was_moved then
          return position_bracket
        end
      else
        -- If it was not found, move from the end of the string until
        -- we find a place we can put it in
        local new_position = string.len(line)
        while new_position > position do
          local was_moved = rewrite_line(new_position)
          if was_moved then
            return new_position
          end

          new_position = new_position - 1
        end

        -- If the new_position was not found, then break
        -- so it can return nil
        break
      end
    else
      -- If we are not finding space, then try to position the bracket
      -- only once

      -- If nil, exit
      if not position_bracket then
        break
      end

      -- If we managed to move the closing string, we can
      -- return the position, otherwise continue cycling
      local was_moved = rewrite_line(position_bracket)
      if was_moved then
        return position_bracket
      end
    end

    -- In this case we have nowhere else to move,
    -- so we can exit here
    if from == position_bracket then
      break
    end

    from = position_bracket
  end

  return nil
end

---Pattern match different types of closing pair and move them
---@param find_space boolean Find space instead of next non-word character
local move_closing = function(find_space)
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] -- x-axis of cursor

  -- Find next match
  for i = col + 1, string.len(line) do
    local pos = find_next(line, col, i)
    -- If there is no match, continue to the next iteration
    if not pos then
      goto continue
    end

    -- Otherwise try to move it the match. If it was moved, exit.
    if move_match(line, pos, find_space) then
      break
    end

    ::continue::
  end
end

---@param rhs string Keybind
---@param callable function callable(find_space: boolean)
---@param find_space boolean Find space instead of next non-word character
---@param description string Description of what the map does
local map = function(rhs, callable, find_space, description)
  vim.keymap.set({ "n", "i" }, rhs, function()
    callable(find_space)
  end, { desc = "Move parenthesis around next " .. description })
end

---@param opts table? Optional configuration table
M.setup = function(opts)
  opts = opts or {}
  opts.word_keymap = opts.word_keymap or "<C-E>"
  opts.WORD_keymap = opts.WORD_keymap or "<C-S-E>"

  map(opts.word_keymap, move_closing, false, "word")
  map(opts.WORD_keymap, move_closing, true, "WORD")
end

M._is_balanced_pair = is_balanced_pair
M._is_balanced = is_balanced
M._find_next = find_next
M._move_match = move_match

return M
