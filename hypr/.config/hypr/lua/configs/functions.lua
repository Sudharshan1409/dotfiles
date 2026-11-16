local function KeyCombo(...)
	local args = { ... }
	assert(#args >= 2, "KeyCombo requires at least 2 arguments")
	return table.concat(args, " + ")
end

return {
	KeyCombo = KeyCombo,
}
