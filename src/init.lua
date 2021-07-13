local M = {}

local function join(t1, t2)
	local res = {}
	for _, t in pairs(t1) do
		table.insert(res, t)
	end
	for _, t in pairs(t2) do
		table.insert(res, t)
	end
	return res
end

local function merge_in(t1, t2)
	for k, v in pairs(t2) do
		t1[k] = v
	end
end

local function longest_common_chain(a, b)
	local j = 1
	while true do
		if j == #a + 1 then
			break
		end
		if j == #b + 1 then
			break
		end
		if a:sub(j, j) ~= b:sub(j, j) then
			break
		end
		j = j + 1
	end
	return a:sub(1, j - 1)
end

local prefix = ""
local opts = {
	on_one_file_messages = {
		{ LogInfo = "triggered" },
		{ CallLuaSilently = "custom.type_to_nav_quit_focus" },
	},
	default_bindings = true,
}

xplr.fn.custom.type_to_nav_quit = function()
	local old = prefix
	prefix = ""
	return {
		{ RemoveNodeFilter = {
			filter = "RelativePathDoesStartWith",
			input = old,
		} },
		"ExplorePwd",
		"PopMode",
		{ SwitchModeBuiltin = "default" },
	}
end

xplr.fn.custom.type_to_nav_quit_focus = function(app)
	local focused_node = app.focused_node
	if not focused_node then
		return xplr.fn.custom.type_to_nav_quit()
	end
	local old = prefix
	prefix = ""
	return join({ { FocusPath = focused_node.absolute_path } }, xplr.fn.custom.type_to_nav_quit())
end

xplr.fn.custom.type_to_nav_complete = function(app)
	if not app.directory_buffer then
		return
	end
	prefix = nil
	for _, node in ipairs(app.directory_buffer.nodes) do
		local p = node.relative_path
		if not prefix then
			prefix = p
		else
			prefix = longest_common_chain(prefix, p)
		end
	end
	local old = prefix
	return {
		{ RemoveNodeFilter = {
			filter = "RelativePathDoesStartWith",
			input = old,
		} },
		{ AddNodeFilter = {
			filter = "RelativePathDoesStartWith",
			input = prefix,
		} },
		"ExplorePwdAsync",
	}
end

xplr.fn.custom.type_to_nav_backspace = function()
	if #prefix == 0 then
		return
	end
	local old = prefix
	prefix = prefix:sub(1, -2)
	return {
		{ RemoveNodeFilter = {
			filter = "RelativePathDoesStartWith",
			input = old,
		} },
		{ AddNodeFilter = {
			filter = "RelativePathDoesStartWith",
			input = prefix,
		} },
		"ExplorePwdAsync",
	}
end

xplr.fn.custom.type_to_nav_accept = function(app)
	local focus = app.directory_buffer.focus
	local node = app.directory_buffer.nodes[focus]
	if node.is_dir then
		local old = prefix
		prefix = ""
		return {
			{ RemoveNodeFilter = {
				filter = "RelativePathDoesStartWith",
				input = old,
			} },
			{ ChangeDirectory = node.absolute_path },
		}
	elseif node.is_file then
		local old = prefix
		prefix = ""
		return join(opts.on_one_file_messages, {
			{ RemoveNodeFilter = {
				filter = "RelativePathDoesStartWith",
				input = old,
			} },
			"ExplorePwdAsync",
		})
	end
end

xplr.fn.custom.type_to_nav_check_dir = function(app)
	local card
	if app.directory_buffer then
		card = #app.directory_buffer.nodes
	else
		card = 0
	end
	if card == 1 then
		local node = app.directory_buffer.nodes[1]
		if node.is_dir then
			local old = prefix
			prefix = ""
			return {
				{ RemoveNodeFilter = {
					filter = "RelativePathDoesStartWith",
					input = old,
				} },
				{ ChangeDirectory = node.absolute_path },
			}
		elseif node.is_file then
			local old = prefix
			prefix = ""
			return join(opts.on_one_file_messages, {
				{ RemoveNodeFilter = {
					filter = "RelativePathDoesStartWith",
					input = old,
				} },
				"ExplorePwdAsync",
			})
		end
	end
end

xplr.config.modes.custom.type_to_nav = {
	name = "type-to-nav",
	key_bindings = {
		on_key = {},
	},
}
for i = 32, 126 do
	local key = string.char(i)
	local identifier = "type_to_nav_press_" .. tostring(i)
	xplr.fn.custom[identifier] = function(app)
		local old = prefix
		prefix = prefix .. key
		local messages
		if prefix == "." then
			messages = {
				{ RemoveNodeFilter = { filter = "RelativePathDoesNotStartWith", input = "." } },
			}
		else
			messages = {}
		end
		return join(messages, {
			{ RemoveNodeFilter = {
				filter = "RelativePathDoesStartWith",
				input = old,
			} },
			{ AddNodeFilter = {
				filter = "RelativePathDoesStartWith",
				input = prefix,
			} },
			"ExplorePwd",
			{ CallLuaSilently = "custom.type_to_nav_check_dir" },
		})
	end
	xplr.config.modes.custom.type_to_nav.key_bindings.on_key[key] = {
		messages = {
			{ CallLuaSilently = "custom." .. identifier },
		},
	}
end

M.setup = function(lopts)
	if lopts then
		merge_in(opts, lopts)
	end
	if opts.default_bindings then
		xplr.config.modes.builtin.default.key_bindings.on_key["ctrl-n"] = {
			help = "type-to-nav",
			messages = {
				{ SwitchModeCustom = "type_to_nav" },
			},
		}
		merge_in(xplr.config.modes.custom.type_to_nav.key_bindings.on_key, {
			esc = {
				help = "quit mode",
				messages = { { CallLuaSilently = "custom.type_to_nav_quit" } },
			},
			backspace = {
				help = "backspace",
				messages = { { CallLuaSilently = "custom.type_to_nav_backspace" } },
			},
			tab = {
				help = "complete",
				messages = { { CallLuaSilently = "custom.type_to_nav_complete" } },
			},
			enter = {
				help = "accept",
				messages = { { CallLuaSilently = "custom.type_to_nav_accept" } },
			},
		})
	end
end

return M
