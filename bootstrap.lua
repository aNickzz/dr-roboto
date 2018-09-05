if (_G.require == nil) then
	--Running in ComputerCraft
	--This require function mostly emulates the one in normal lua 5.1
	--Will get confused if called both with and without '.lua' extension

	_G.package =
		setmetatable(
		{},
		{
			__index = {
				loaded = setmetatable(
					{},
					{
						__metatable = {}
					}
				)
			},
			__metatable = {},
			__newindex = function()
				error("'package' is read only")
			end
		}
	)
	local currentlyLoading = {}

	_G.require = function(module)
		if (module:sub(-(#'.lua')) == '.lua') then
			error('Do not include .lua in module names')
		end

		if (_G.package.loaded[module]) then
			return _G.package.loaded[module]
		end

		if (currentlyLoading[module]) then
			error('Recursive module loading not supported')
		end

		currentlyLoading[module] = true

		if (fs.exists(module)) then
			_G.package.loaded[module] = dofile(module)
		else
			_G.package.loaded[module] = dofile(module .. '.lua')
		end

		currentlyLoading[module] = nil

		return _G.package.loaded[module]
	end
end

if (_G.fs == nil) then
	_G.fs = {
		list = function(directory)
			local i, t, popen = 0, {}, io.popen
			local pfile = popen('ls -a "' .. directory .. '"')
			for filename in pfile:lines() do
				i = i + 1
				t[i] = filename
			end
			pfile:close()
			return t
		end
	}
end