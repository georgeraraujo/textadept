-- Copyright 2020-2024 Mitchell. See LICENSE.

--- Returns whether or not line number *line* has a bookmark on it.
-- @param line Line number to check for a bookmark on.
local function has_bookmark(line)
	return buffer:marker_get(line) & 1 << textadept.bookmarks.MARK_BOOKMARK - 1 > 0
end

test('bookmarks.toggle should bookmark the current line', function()
	textadept.bookmarks.toggle()

	test.assert_equal(has_bookmark(1), true)
end)

test("bookmarks.toggle should remove a line's existing bookmark", function()
	textadept.bookmarks.toggle()

	textadept.bookmarks.toggle()

	test.assert_equal(has_bookmark(1), false)
end)

test('bookmarks.clear should remove all buffer bookmarks', function()
	textadept.bookmarks.toggle()

	textadept.bookmarks.clear()

	test.assert_equal(has_bookmark(1), false)
end)

test('bookmarks.goto_mark should prompt for a bookmark to go to', function()
	buffer:add_text(test.lines(2))
	textadept.bookmarks.toggle()
	local bookmarked_line = buffer:line_from_position(buffer.current_pos)
	buffer:line_up()
	local select_first_item = test.stub(1)
	local _<close> = test.mock(ui.dialogs, 'list', select_first_item)

	textadept.bookmarks.goto_mark()

	local line = buffer:line_from_position(buffer.current_pos)
	test.assert_equal(line, bookmarked_line)
end)

test('bookmarks.goto_mark(true) should go to the next bookmark', function()
	buffer:add_text(test.lines(2))
	textadept.bookmarks.toggle()
	local bookmarked_line = buffer:line_from_position(buffer.current_pos)
	buffer:line_up()

	textadept.bookmarks.goto_mark(true)

	local line = buffer:line_from_position(buffer.current_pos)
	test.assert_equal(line, bookmarked_line)
end)

test('bookmarks.goto_mark(true) should go to the next (wrapped) bookmark', function()
	buffer:append_text(test.lines(2))
	textadept.bookmarks.toggle()
	local bookmarked_line = buffer:line_from_position(buffer.current_pos)
	buffer:line_down()

	textadept.bookmarks.goto_mark(true)

	local line = buffer:line_from_position(buffer.current_pos)
	test.assert_equal(line, bookmarked_line)
end)

test('bookmarks.goto_mark(false) should go to the previous bookmark', function()
	buffer:append_text(test.lines(2))
	textadept.bookmarks.toggle()
	local bookmarked_line = buffer:line_from_position(buffer.current_pos)
	buffer:line_down()

	textadept.bookmarks.goto_mark(false)

	local line = buffer:line_from_position(buffer.current_pos)
	test.assert_equal(line, bookmarked_line)
end)

test('bookmarks.goto_mark(false) should go to the previous (wrapped) bookmark', function()
	buffer:add_text(test.lines(2))
	textadept.bookmarks.toggle()
	local bookmarked_line = buffer:line_from_position(buffer.current_pos)
	buffer:line_up()

	textadept.bookmarks.goto_mark(false)

	local line = buffer:line_from_position(buffer.current_pos)
	test.assert_equal(line, bookmarked_line)
end)

test('bookmarks.goto_mark prompt should include bookmarks from other buffers', function()
	local f<close> = test.tmpfile('\n', true)
	buffer:line_down()
	textadept.bookmarks.toggle()
	local bookmarked_line = buffer:line_from_position(buffer.current_pos)

	buffer.new()
	textadept.bookmarks.toggle()

	local select_second_item = test.stub(2)
	local _<close> = test.mock(ui.dialogs, 'list', select_second_item)

	textadept.bookmarks.goto_mark()

	local line = buffer:line_from_position(buffer.current_pos)
	test.assert_equal(buffer.filename, f.filename)
	test.assert_equal(line, bookmarked_line)
end)

test('bookmarks should restore upon file reload', function()
	local _<close> = test.tmpfile('\n', true)
	buffer:line_down()
	textadept.bookmarks.toggle()
	local bookmarked_line = buffer:line_from_position(buffer.current_pos)

	buffer:reload()

	test.assert_equal(has_bookmark(bookmarked_line), true)
end)
