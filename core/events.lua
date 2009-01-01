-- Copyright 2007-2009 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Module that handles Scintilla and Textadept notifications/events.
-- Most of Textadept's functionality comes through handlers. Scintilla
-- notifications, Textadept's own events, and user-defined events can all be
-- handled.
module('textadept.events', package.seeall)

-- Usage:
-- Each event can have multiple handlers, which are simply Lua functions that
-- are called in the sequence they are added as handler functions. Sometimes it
-- is useful to have a handler run under a specific condition(s). If this is the
-- case, place a conditional in the function that returns if it isn't met.
--
-- For users creating their own events, one does not have to be explicitly
-- defined. A handler can simply be added for an event name, and 'handle'd when
-- necessary.
--
-- For reference, events will be shown in 'event(arguments)' format, but in
-- reality, the event is handled as 'handle(event, arguments)'.
--
-- Scintilla notifications:
--   char_added(ch)
--     ch: the (integer) character added.
--   save_point_reached()
--   save_point_left()
--   double_click(position, line)
--     position: the position of the beginning of the line clicked.
--     line: the line clicked.
--   update_ui()
--   macro_record(message, wParam, lParam)
--     message: the SCI_* message.
--     wParam: wParam in SCI_*.
--     lParam: lParam in SCI_*.
--   margin_click(margin, modifiers, position)
--     margin: the margin number.
--     modifiers: mouse modifiers.
--     position: the position of the beginning of the line at the point clicked.
--   user_list_selection(wParam, text)
--     wParam: the user list ID.
--     text: the text of the selected item.
--   uri_dropped(text)
--     text: the URI dropped.
--   call_tip_click(position)
--     position: 1 or 2 if the up or down arrow was clicked; 0 otherwise.
--   auto_c_selection(lParam, text)
--     lParam: the start position of the word being completed.
--     text: the text of the selected item.
--
-- Textadept events:
--   buffer_new()
--   buffer_deleted()
--   buffer_switch()
--   view_new()
--   view_switch()
--   quit()
--     Note: when adding a quit handler, it must be inserted at index 1 because
--     the default quit handler returns true, which ignores all subsequent
--     handlers.
--   keypress(code, shift, control, alt)
--     code: the key code.
--     shift: flag indicating whether or not shift is pressed.
--     control: flag indicating whether or not control is pressed.
--     alt: flag indicating whether or not alt is pressed.
--   menu_clicked(menu_item)
--     menu_item: text of the menu item clicked.

local events = textadept.events

---
-- Adds a handler function to an event.
-- @param event The string event name.
-- @param f The Lua function to add.
-- @param index Optional index to insert the handler into.
function add_handler(event, f, index)
  local plural = event..'s'
  if not events[plural] then events[plural] = {} end
  local handlers = events[plural]
  if index then
    table.insert(handlers, index, f)
  else
    handlers[#handlers + 1] = f
  end
end

---
-- Calls every handler function added to an event in sequence.
-- If true or false is returned by any handler, the iteration ceases. Normally
-- this function is called by the system when necessary, but it can be called
-- in scripts to handle user-defined events.
-- @param event The string event name.
-- @param ... Arguments to the handler.
function handle(event, ...)
  local plural = event..'s'
  local handlers = events[plural]
  if not handlers then return end
  for _, f in ipairs(handlers) do
    local result = f( unpack{...} )
    if result == true or result == false then return result end
  end
end

---
-- Reloads event handlers.
-- Clears each event's table of handlers and reloads this module to reset to the
-- default handlers.
function reload()
  package.loaded['events'] = nil
  for handler in pairs(events) do
    if events[handler..'s'] then events[handler..'s'] = nil end
  end
  require 'events'
end

-- Textadept events.
function buffer_new()
  return handle('buffer_new')
end
function buffer_deleted()
  return handle('buffer_deleted')
end
function buffer_switch()
  return handle('buffer_switch')
end
function view_new()
  return handle('view_new')
end
function view_switch()
  return handle('view_switch')
end
function quit()
  return handle('quit')
end
function keypress(code, shift, control, alt)
  return handle('keypress', code, shift, control, alt)
end
function menu_clicked(menu_item)
  return handle('menu_clicked', menu_item)
end

-- Scintilla notifications.
function char_added(n)
  if n.ch < 256 then return handle( 'char_added', string.char(n.ch) ) end
end
function save_point_reached()
  return handle('save_point_reached')
end
function save_point_left()
  return handle('save_point_left')
end
function double_click(n)
  return handle('double_click', n.position, n.line)
end
function update_ui()
  return handle('update_ui')
end
function macro_record(n)
  return handle('macro_record', n.message, n.wParam, n.lParam)
end
function margin_click(n)
  return handle('margin_click', n.margin, n.modifiers, n.position)
end
function user_list_selection(n)
  return handle('user_list_selection', n.wParam, n.text)
end
function uri_dropped(n)
  return handle('uri_dropped', n.text)
end
function call_tip_click(n)
  return handle('call_tip_click', n.position)
end
function auto_c_selection(n)
  return handle('auto_c_selection', n.lParam, n.text)
end

--- Map of Scintilla notifications to their handlers.
local c = textadept.constants
local scnnotifications = {
  [c.SCN_CHARADDED] = char_added,
  [c.SCN_SAVEPOINTREACHED] = save_point_reached,
  [c.SCN_SAVEPOINTLEFT] = save_point_left,
  [c.SCN_DOUBLECLICK] = double_click,
  [c.SCN_UPDATEUI] = update_ui,
  [c.SCN_MACRORECORD] = macro_record,
  [c.SCN_MARGINCLICK] = margin_click,
  [c.SCN_USERLISTSELECTION] = user_list_selection,
  [c.SCN_URIDROPPED] = uri_dropped,
  [c.SCN_CALLTIPCLICK] = call_tip_click,
  [c.SCN_AUTOCSELECTION] = auto_c_selection
}

---
-- Handles Scintilla notifications.
-- @param n The Scintilla notification structure as a Lua table.
function notification(n)
  local f = scnnotifications[n.code]
  if f then f(n) end
end

-- Default handlers to follow.

add_handler('view_new',
  function() -- sets default properties for a Scintilla window
    local c, buffer = textadept.constants, buffer

    -- properties
    buffer.property['textadept.home'] = _HOME
    buffer.property['lexer.lua.home'] = _HOME..'/lexers/'
    buffer.property['lexer.lua.script'] = _HOME..'/lexers/lexer.lua'
    if _THEME and #_THEME > 0 then
      buffer.property['lexer.lua.color.theme'] = _THEME
    end

    -- lexer
    buffer.style_bits = 8
    buffer.lexer = c.SCLEX_LPEG
    buffer:set_lexer_language('container')

    -- delete Windows/Linux key commands for Mac
    if MAC then
      buffer:clear_cmd_key(string.byte('Z'), c.SCMOD_CTRL)
      buffer:clear_cmd_key(string.byte('Y'), c.SCMOD_CTRL)
      buffer:clear_cmd_key(string.byte('X'), c.SCMOD_CTRL)
      buffer:clear_cmd_key(string.byte('C'), c.SCMOD_CTRL)
      buffer:clear_cmd_key(string.byte('V'), c.SCMOD_CTRL)
      buffer:clear_cmd_key(string.byte('A'), c.SCMOD_CTRL)
    end

    if _THEME and #_THEME > 0 then
      local ret, errmsg =
        pcall(dofile, _HOME..'/themes/'.._THEME..'/view.lua')
      if ret then return end
      io.stderr:write(errmsg)
    end

    -- Default Theme (Light).

    -- caret
    buffer.caret_fore = 3355443 -- 0x33 | 0x33 << 8 | 0x33 << 16
    buffer.caret_line_visible = true
    buffer.caret_line_back = 14540253 -- 0xDD | 0xDD << 8 | 0xDD << 16
    buffer:set_x_caret_policy(1, 20) -- CARET_SLOP
    buffer:set_y_caret_policy(13, 1) -- CARET_SLOP | CARET_STRICT | CARET_EVEN
    buffer.caret_style = 2
    buffer.caret_period = 0

    -- selection
    buffer:set_sel_fore(1, 3355443) -- 0x33 | 0x33 << 8 | 0x33 << 16
    buffer:set_sel_back(1, 10066329) -- 0x99 | 0x99 << 8 | 0x99 << 16

    buffer.margin_width_n[0] = 4 + 3 * -- line number margin
      buffer:text_width(c.STYLE_LINENUMBER, '9')

    buffer.margin_width_n[1] = 0 -- marker margin invisible

    -- fold margin
    buffer:set_fold_margin_colour(1, 13421772) -- 0xCC | 0xCC << 8 | 0xCC << 16
    buffer:set_fold_margin_hi_colour(1, 13421772) -- 0xCC | 0xCC << 8 | 0xCC << 16
    buffer.margin_type_n[2] = c.SC_MARGIN_SYMBOL
    buffer.margin_width_n[2] = 10
    buffer.margin_mask_n[2] = c.SC_MASK_FOLDERS
    buffer.margin_sensitive_n[2] = true

    -- fold margin markers
    buffer:marker_define(c.SC_MARKNUM_FOLDEROPEN, c.SC_MARK_ARROWDOWN)
    buffer:marker_set_fore(c.SC_MARKNUM_FOLDEROPEN, 0)
    buffer:marker_set_back(c.SC_MARKNUM_FOLDEROPEN, 0)
    buffer:marker_define(c.SC_MARKNUM_FOLDER, c.SC_MARK_ARROW)
    buffer:marker_set_fore(c.SC_MARKNUM_FOLDER, 0)
    buffer:marker_set_back(c.SC_MARKNUM_FOLDER, 0)
    buffer:marker_define(c.SC_MARKNUM_FOLDERSUB, c.SC_MARK_EMPTY)
    buffer:marker_define(c.SC_MARKNUM_FOLDERTAIL, c.SC_MARK_EMPTY)
    buffer:marker_define(c.SC_MARKNUM_FOLDEREND, c.SC_MARK_EMPTY)
    buffer:marker_define(c.SC_MARKNUM_FOLDEROPENMID, c.SC_MARK_EMPTY)
    buffer:marker_define(c.SC_MARKNUM_FOLDERMIDTAIL, c.SC_MARK_EMPTY)

    -- various
    buffer.buffered_draw = true
    buffer.two_phase_draw = false
    buffer.call_tip_use_style = 32
    buffer.use_popup = 0
    buffer:set_fold_flags(16)
    buffer.mod_event_mask = c.SC_MOD_CHANGEFOLD
    buffer.scroll_width = 2000
    buffer.h_scroll_bar = true
    buffer.end_at_last_line = true
    buffer.caret_sticky = false
  end)

add_handler('buffer_new',
  function() -- sets default properties for a Scintilla document
    local function run()
      local textadept, buffer = textadept, buffer

      -- lexer
      buffer.style_bits = 8
      buffer.lexer = textadept.constants.SCLEX_LPEG
      buffer:set_lexer_language('container')

      -- buffer
      buffer.code_page = textadept.constants.SC_CP_UTF8

      if _THEME and #_THEME > 0 then
       local ret, errmsg =
         pcall(dofile, _HOME..'/themes/'.._THEME..'/buffer.lua')
        if ret then return end
        io.stderr:write(errmsg)
      end

      -- Default theme.

      -- folding
      buffer.property['fold'] = '1'
      buffer.property['fold.by.indentation'] = '1'

      -- tabs and indentation
      buffer.tab_width = 2
      buffer.use_tabs = false
      buffer.indent = 2
      buffer.tab_indents = true
      buffer.back_space_un_indents = true
      buffer.indentation_guides = 1

      -- various
      buffer.eol_mode = textadept.constants.SC_EOL_LF
      buffer.auto_c_choose_single = true
    end
    -- normally when an error occurs, a new buffer is created with the error
    -- message, but if an error occurs here, this event would be called again
    -- and again, erroring each time resulting in an infinite loop; print error
    -- to stderr instead
    local ret, errmsg = pcall(run)
    if not ret then io.stderr:write(errmsg) end
  end)

add_handler('char_added',
  function(char) -- auto-indent on return
    if char ~= '\n' then return end
    local buffer = buffer
    local anchor, caret = buffer.anchor, buffer.current_pos
    local curr_line = buffer:line_from_position(caret)
    local last_line = curr_line - 1
    while last_line >= 0 and #buffer:get_line(last_line) == 1 do
      last_line = last_line - 1
    end
    if last_line >= 0 then
      local indentation = buffer.line_indentation[last_line]
      local s = buffer.line_indent_position[curr_line]
      buffer.line_indentation[curr_line] = indentation
      local e = buffer.line_indent_position[curr_line]
      local diff = e - s
      if e > s then -- move selection on
        if anchor >= s then anchor = anchor + diff end
        if caret  >= s then caret  = caret  + diff end
      elseif e < s then -- move selection back
        if anchor >= e then anchor = anchor >= s and anchor + diff or e end
        if caret  >= e then caret  = caret  >= s and caret  + diff or e end
      end
      buffer:set_sel(anchor, caret)
    end
  end)

---
-- [Local function] Sets the title of the Textadept window to the buffer's
-- filename.
-- @param buffer The currently focused buffer.
local function set_title(buffer)
  local buffer = buffer
  local filename = buffer.filename or 'Untitled'
  local d = buffer.dirty and ' * ' or ' - '
  textadept.title = filename:match('[^/\\]+$')..d..'Textadept ('..filename..')'
end

add_handler('save_point_reached',
  function() -- changes Textadept title to show 'clean' buffer
    buffer.dirty = false
    set_title(buffer)
  end)

add_handler('save_point_left',
  function() -- changes Textadept title to show 'dirty' buffer
    buffer.dirty = true
    set_title(buffer)
  end)

---
-- [Local table] A table of error string details.
-- Each entry is a table with the following fields:
--   pattern: the Lua pattern that matches a specific error string.
--   filename: the index of the Lua capture that contains the filename the error
--     occured in.
--   line: the index of the Lua capture that contains the line number the error
--     occured on.
--   message: [Optional] the index of the Lua capture that contains the error's
--     message. A call tip will be displayed if a message was captured.
-- When an error message is double-clicked, the user is taken to the point of
--   error.
-- @class table
-- @name _error_details
local _error_details = {
  lua = { pattern = '^lua: ([^:]+):(%d+): (.+)$',
          filename = 1, line = 2, message = 3 }
}

add_handler('double_click',
  function(pos, line_num) -- goes to the file and line specified by line's text
    if buffer.shows_errors then
      line = buffer:get_line(line_num)
      for _, error_detail in pairs(_error_details) do
        local captures = { line:match(error_detail.pattern) }
        if #captures > 0 then
          textadept.io.open( captures[error_detail.filename] )
          _m.textadept.editing.goto_line( captures[error_detail.line] )
          local msg = captures[error_detail.message]
          if msg then buffer:call_tip_show(buffer.current_pos, msg) end
          break
        end
      end
    end
  end)

add_handler('uri_dropped',
  function(uris)
    for uri in uris:gmatch('[^\r\n\f]+') do
      if uri:match('^file://') then
        uri = uri:match('^file://([^\r\n\f]+)')
        if WIN32 then
          uri = uri:sub(2, -1) -- ignore leading '/'
          uri = uri:gsub('%%20', ' ') -- sub back for spaces
        end
        textadept.io.open(uri)
      end
    end
  end)

---
-- [Local table] A table of (integer) brace characters with their matches.
-- @class table
-- @name _braces
local _braces = { -- () [] {} <>
  [40] = 1, [91] = 1, [123] = 1, [60] = 1,
  [41] = 1, [93] = 1, [125] = 1, [62] = 1,
}

---
-- [Local function] Highlights matching/mismatched braces appropriately.
-- @param current_pos The position to match braces at.
local function match_brace(current_pos)
  local buffer = buffer
  if _braces[ buffer.char_at[current_pos] ] and
    buffer:get_style_name( buffer.style_at[current_pos] ) == 'operator' then
    local pos = buffer:brace_match(current_pos)
    if pos ~= -1 then
      buffer:brace_highlight(current_pos, pos)
    else
      buffer:brace_bad_light(current_pos)
    end
    return true
  end
  return false
end

add_handler('update_ui',
  function() -- highlights matching braces
    local buffer = buffer
    if not match_brace(buffer.current_pos) then buffer:brace_bad_light(-1) end
  end)

local docstatusbar_text =
  "Line: %d/%d    Col: %d    Lexer: %s    %s    %s    %s"
add_handler('update_ui',
  function() -- sets docstatusbar text
    local buffer = buffer
    local pos = buffer.current_pos
    local line, max = buffer:line_from_position(pos) + 1, buffer.line_count
    local col = buffer.column[pos] + 1
    local lexer = buffer:get_lexer_language()
    local mode = buffer.overtype and 'OVR' or 'INS'
    local eol = ( { 'CRLF', 'CR', 'LF' } )[buffer.eol_mode + 1]
    local tabs = (buffer.use_tabs and 'Tabs:' or 'Spaces:')..buffer.indent
    textadept.docstatusbar_text =
      docstatusbar_text:format(line, max, col, lexer, mode, eol, tabs)
  end)

add_handler('margin_click',
  function(margin, modifiers, position) -- toggles folding
    local buffer = buffer
    local line = buffer:line_from_position(position)
    buffer:toggle_fold(line)
  end)

add_handler('buffer_new',
  function() -- set additional buffer functions
    local buffer, textadept = buffer, textadept
    buffer.reload = textadept.io.reload
    buffer.save = textadept.io.save
    buffer.save_as = textadept.io.save_as
    buffer.close = textadept.io.close
    set_title(buffer)
  end)

add_handler('buffer_switch',
  function() -- updates titlebar and statusbar
    set_title(buffer)
    update_ui()
  end)

add_handler('view_switch',
  function() -- updates titlebar and statusbar
    set_title(buffer)
    update_ui()
  end)

add_handler('quit',
  function() -- prompts for confirmation if any buffers are dirty; saves session
    local any = false
    local list = { 'The following buffers are unsaved:\n' }
    for _, buffer in ipairs(textadept.buffers) do
      if buffer.dirty then
        list[#list + 1] = buffer.filename or 'Untitled'
        any = true
      end
    end
    if any then
      list[#list + 1] = '\nYou will have to save changes manually.\n'
      if cocoa_dialog( 'yesno-msgbox', {
        title = 'Save?',
        text = 'Save changes before quitting?',
        ['informative-text'] = table.concat(list, '\n'),
        ['no-newline'] = true
      } ) ~= '2' then return false end
    end
    textadept.io.save_session()
    return true
  end)

if MAC then
  function appleevent_odoc(uri) return handle('appleevent_odoc', uri) end
  add_handler('appleevent_odoc', function(uri) textadept.io.open(uri) end)
end

---
-- Default error handler.
-- Opens a new buffer (if one hasn't already been opened) for printing errors.
-- @param ... Error strings.
function error(...)
  local function handle_error(...)
    local textadept = textadept
    local error_message = table.concat( {...} , '\n' )
    local error_buffer
    for index, buffer in ipairs(textadept.buffers) do
      if buffer.shows_errors then
        error_buffer = buffer
        if buffer.doc_pointer ~= textadept.focused_doc_pointer then
          view:goto_buffer(index)
        end
        break
      end
    end
    if not error_buffer then
      error_buffer = textadept.new_buffer()
      error_buffer.shows_errors = true
    end
    error_buffer:append_text(error_message..'\n')
    error_buffer:set_save_point()
  end
  pcall( handle_error, unpack{...} ) -- prevent endless loops if this errors
end

textadept.print = error
