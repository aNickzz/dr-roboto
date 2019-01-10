colors = {
	-- Colors
	white = 1,
	orange = 2,
	magenta = 4,
	lightBlue = 8,
	yellow = 16,
	lime = 32,
	pink = 64,
	gray = 128,
	lightGray = 256,
	cyan = 512,
	purple = 1024,
	blue = 2048,
	brown = 4096,
	green = 8192,
	red = 16384,
	black = 32768,
	combine = function(...)
		local r = 0
		for n, c in ipairs({...}) do
			r = bit32.bor(r, c)
		end
		return r
	end,
	subtract = function(colors, ...)
		local r = colors
		for n, c in ipairs({...}) do
			r = bit32.band(r, bit32.bnot(c))
		end
		return r
	end,
	test = function(colors, color)
		return ((bit32.band(colors, color)) == color)
	end
}
colours = colors
