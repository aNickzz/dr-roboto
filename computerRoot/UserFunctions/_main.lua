local function loadAllUserFunctions()
	local userFunctions = {}
	local env =
		setmetatable(
		{
			registerUserFunction = function(func, name, ...)
				userFunctions[name] = {
					params = {...},
					func = func
				}
			end,
			registerUserFunctionFromFile = function(path, name, ...)
				userFunctions[name] = {
					params = {...},
					func = function(...)
						os.run(_G, path, name, unpack({...}))
					end
				}
			end
		},
		{__index = getfenv()}
	)
	local files = fs.listRecursive('UserFunctions')
	for _, file in ipairs(files) do
		if (not stringutil.endsWith(file, '_main.lua')) then
			if (stringutil.endsWith(file, '.lua')) then
				pcall(
					function()
						dofileSandbox(file, env)
					end
				)
			end
		end
	end
	return userFunctions
end

if (rawget(_G, 'shell') ~= nil) then
	local oldComplete = shell.complete

	shell.complete = function(stub)
		if (stringutil.startsWith(stub, 'run ')) then
			stub = stub:sub(5)

			local results = {}

			local userFunctions = loadAllUserFunctions()

			for name, func in pairs(userFunctions) do
				if (stringutil.startsWith(stub, name)) then
					local subStub = stub:sub(#name + 1)

					if (func.params and #func.params > 0) then
						--Count the current number of arguments the user has typed, doesn't consider quoted arguemts that contain spaces
						local argsInput = 0
						for i in string.gmatch(subStub, '%S+') do
							argsInput = argsInput + 1
						end

						local result = ''

						if ((#func.params - argsInput > 0) and subStub:sub(#subStub) ~= ' ') then
							result = ' '
						end

						for i = argsInput + 1, #func.params do
							result = result .. func.params[i]
							if (i < #func.params) then
								result = result .. ' '
							end
						end

						if (#func.params - argsInput <= 0) then
							if (stringutil.endsWith(func.params[#func.params], '...')) then
								if (subStub:sub(#subStub) ~= ' ') then
									result = result .. ' '
								end
								result = result .. func.params[#func.params]
							end
						end
						table.insert(results, result)
					end
				elseif (stringutil.startsWith(name, stub)) then
					table.insert(results, name:sub(#stub + 1))
				end
			end

			table.sort(results)
			return results
		else
			return oldComplete(stub)
		end
	end
end

function runUserFunction(name, ...)
	local userFunctions = loadAllUserFunctions()
	if (userFunctions[name] == nil) then
		print('No function named ' .. name .. ' defined.')
		return
	end
	return userFunctions[name].func(...)
end
