local col = require 'Util/TextColors'

local LOG_NONE = -1
local LOG_SOME = 0
local LOG_ALL = 1

local function createTestParams()
	local calls = {}
	local t = {}
	function t.assertEqual(result, expected)
		if (result == expected) then
			return
		end

		error('Assert ==,\nExpected "' .. tostring(expected) .. '"\n but got "' .. tostring(result) .. '"', 2)
	end

	function t.assertTableEqual(result, expected, errorString)
		if errorString == nil then
			errorString = '\nAssert Table Equal,\n'
		end

		if result == expected then
			return
		end

		for k1, v1 in next, result do
			if not expected[k1] then
				error(errorString .. 'Unexpected key "' .. tostring(k1) .. '"', 2)
			end
			if expected[k1] ~= v1 then
				error(
					errorString ..
						'Incorrect value for key "' ..
							tostring(k1) .. '"\n expected "' .. tostring(expected[k1]) .. '"\n  but got "' .. tostring(v1) .. '"',
					2
				)
			end
			if type(v1) == 'table' then
				t.assertTableEqual(
					v1,
					expected[k1],
					errorString .. ' \nIn inner table "' .. tostring(k1) .. '":\n ' .. tostring(k1):gsub('\n', '\n ')
				)
			end
		end

		for k2, v2 in next, expected do
			if not result[k2] then
				error(errorString .. 'Missing key "' .. tostring(k2) .. '"', 2)
			end
		end
	end

	function t.assertNotEqual(result, unexpected)
		if (result ~= unexpected) then
			return
		end

		error('Assert ~=,\nGot "' .. tostring(result) .. '"', 2)
	end

	function t.assertThrows(method)
		local success = pcall(method)

		if (success) then
			error('Assert throws')
		end
	end

	function t.assertCalled()
		local id = {}

		calls[id] = false

		return function()
			calls[id] = true
		end
	end

	function t.assertCalledWith(...)
		local id = {}
		local expectedArgs = {...}

		calls[id] = false

		return function(...)
			local args = {...}

			if (#args ~= #expectedArgs) then
				error('Incorrect call, got "' .. #args .. '" args but expected "' .. #expectedArgs .. '"')
			end

			for i = 1, #args do
				if (args[i] ~= expectedArgs[i]) then
					error(
						'Incorrect call,\nExpected arg "' .. tostring(args[i]) .. '"\n but got arg "' .. tostring(expectedArgs[i]) .. '"',
						2
					)
				end
			end

			calls[id] = true
		end
	end

	function t.assertNotCalled()
		return function()
			error('Function should not have been called')
		end
	end

	function t.finalize()
		for _, call in pairs(calls) do
			t.assertEqual(call, true)
		end
	end

	-- Creates a dummy object that will will return a function every time it is indexed
	-- The function will return the values supplied in retVals, or retVals if it is not a table
	function t.mock(name, retVals, doPrint, stackLevels)
		if (type(retVals) ~= 'table') then
			retVals = {retVals}
		end

		if (doPrint == nil) then
			doPrint = true
		end

		if (stackLevels == nil) then
			stackLevels = 1
		end

		return t.mockCustom(
			function(t, v)
				return function(...)
					if (doPrint) then
						if (#{...} > 0) then
							print('Mock ' .. name .. '.' .. v .. '(', unpack({...}), ')')
						else
							print('Mock ' .. name .. '.' .. v .. '()')
						end
					end

					if (stackLevels > 0) then
						printStackTrace(stackLevels, 2)
					end

					return unpack(retVals)
				end
			end
		)
	end

	function t.mockCustom(index, newIndex)
		local meta = {}

		if (index ~= nil) then
			meta.__index = index
		end

		if (newIndex ~= nil) then
			meta.__newindex = newIndex
		end

		return setmetatable({}, meta)
	end

	return t
end

local function doTest(testObj, testContext)
	if (testContext == nil) then
		testContext = {
			logLevel = 2,
			loggedAny = false,
			lastNamespace = '',
			printedNamespace = false
		}
	end

	-- Print out tne namespace if its different to the last test
	if (testContext.lastNamespace ~= testObj.namespace and testObj.namespace ~= nil) then
		testContext.printedNamespace = false
		if (testContext.logLevel > LOG_ALL) then
			col.print(col.blue .. '[' .. testObj.namespace .. ']\n')
			testContext.printedNamespace = true
		end
		testContext.lastNamespace = testObj.namespace
	end

	-- Print out the test name
	if (testContext.logLevel > LOG_ALL) then
		testContext.loggedAny = true
		if (#testObj.name > 37) then
			io.write(string.sub(testObj.name, 1, 37) .. ':')
		else
			io.write(testObj.name .. string.rep(' ', 37 - #testObj.name) .. ':')
		end
	end

	local testParams = createTestParams()
	local errors = {}

	local testWrapper = function()
		testObj.tester(testParams)
		testParams.finalize()
	end

	local env = {}
	env._G = env
	setmetatable(env, {__index = _G})
	setfenv(testWrapper, env)

	-- Start buffering calls to io.write and print (so they dont interfere with the nice formatting)
	local oldwrite = io.write
	local oldprint = print
	local printlines = {}

	io.write = function(...)
		-- oldwrite(...)
		table.insert(printlines, {'write', {...}})
	end
	print = function(...)
		-- oldprint(...)
		table.insert(printlines, {'print', {...}})
	end

	local success, result =
		xpcall(
		testWrapper,
		function(err)
			table.insert(errors, err)
		end
	)

	-- Restore printing functions
	io.write = oldwrite
	print = oldprint

	--TODO: potentially check for changes to env to detect side-effects?

	if (testContext.logLevel > LOG_SOME) then
		if (testContext.logLevel <= LOG_ALL and not success) then
			if (not testContext.printedNamespace) then
				col.print(col.blue .. '[' .. testObj.namespace .. ']\n')
				testContext.printedNamespace = true
			end

			testContext.loggedAny = true

			if (#testObj.name > 37) then
				io.write(string.sub(testObj.name, 1, 37) .. ':')
			else
				io.write(testObj.name .. string.rep(' ', 37 - #testObj.name) .. ':')
			end
		end
		if (testContext.logLevel > LOG_ALL or not success) then
			if (success) then
				col.print(col.green, 'O\n')
			else
				col.print(col.red, 'X\n')
			end

			-- Print all the buffered calls to io.write and print
			for i = 1, #printlines do
				if (printlines[i][1] == 'write') then
					io.write(unpack(printlines[i][2]))
				else
					print(unpack(printlines[i][2]))
				end
			end

			-- Print any errors
			for _, errMsg in ipairs(errors) do
				col.print(col.red, ' ' .. errMsg .. '\n')
			end
		end
	end

	return success
end

local testMeta = {
	__index = function(test, key)
		if (key == 'fullName') then
			if (rawget(test, 'namespace') ~= nil) then
				return rawget(test, 'namespace') .. '.' .. rawget(test, 'name')
			else
				return rawget(test, 'name')
			end
		end

		return rawget(test, key)
	end
}

--[[
	Prepares tests for execution.
	
	Tester functions are invoked using xpcall. If the function returns; the test passes, if it errors; it fails.

	A "testing table" is a recursive structure for tests. A value can be either a tester function, or another testing table.
	If the value is a function, then the key is the test's name, if the value is a table, then the key is a subnamespace that gets appended to the current namespace using dot notation.

	The testing table below yields 3 tests
	test({
		['Core'] = {
			['My Tests'] = {
				['Test 1'] = function(t) end
				['Test 2'] = function(t) end
			}
		},
		['Aux'] = function(t) end
	})

	- Core.My Tests.Test 1
	- Core.My Tests.Test 2
	- Aux

	Tests are not guarenteed to execute in the same order they are written. This is due to the way lua tables work.

	To fit in the standard ComputerCraft window, test names should be 37 or less characters and (fully concatenated) namespaces should be 37 characters or less

	test(namespace: string, name: string, tester: function) prepares a test for execution
	test(namespace: string, tests: table) prepares a testing table for execution
	test(tests: table) prepares a testing table for execution
]]
local function createTests(namespace, name, tester)
	if (type(namespace) == 'table') then
		return createTests('', namespace)
	end

	if (type(name) == 'table') then
		local tests = {}
		for i, v in pairs(name) do
			local result = createTests(namespace, i, v)
			for _, k in pairs(result) do
				table.insert(tests, k)
			end
		end
		return tests
	end

	if (type(tester) == 'table') then
		if (namespace == '') then
			namespace = name
		else
			namespace = namespace .. '.' .. name
		end
		return createTests(namespace, tester)
	end

	return {
		setmetatable(
			{
				namespace = namespace,
				name = name,
				tester = tester
			},
			testMeta
		)
	}
end

local function runTests(tests, logLevel)
	if (logLevel == nil) then
		logLevel = 0
	end

	local testContext = {
		logLevel = logLevel,
		loggedAny = false,
		lastNamespace = '',
		printedNamespace = false
	}

	local testPass = 0

	for _, testObj in ipairs(tests) do
		-- Actually run the test
		local success = doTest(testObj, testContext)

		if (success) then
			testPass = testPass + 1
		end
	end

	if (testContext.logLevel > LOG_ALL or testContext.loggedAny) then
		print()
	end
	if (testContext.logLevel > LOG_SOME or testPass ~= #tests) then
		print(testPass .. ' out of ' .. #tests .. ' tests passed.')
	end
end

--[[
	Searches through all folders for any files ending with "Test.lua" and returns their full paths.
]]
local function findTests(directory)
	local results = {}

	local dirsToCheck = {directory}

	while (#dirsToCheck > 0) do
		local currentDirectory = table.remove(dirsToCheck)
		if (fs.isDir(currentDirectory)) then
			local files = fs.list(currentDirectory)

			for _, file in ipairs(files) do
				if (fs.isDir(currentDirectory .. '/' .. file)) then
					if (file ~= '.' and file ~= '..') then
						table.insert(dirsToCheck, currentDirectory .. '/' .. file)
					end
				elseif (file:sub(-(#'Test.lua')) == 'Test.lua') then
					table.insert(results, currentDirectory .. '/' .. file)
				end
			end
		end
	end

	return results
end

local function loadAllTests()
	local tests = {}
	local env =
		setmetatable(
		{
			test = function(...)
				local testObjs = createTests(...)
				for _, testObj in pairs(testObjs) do
					table.insert(tests, testObj)
				end
			end
		},
		{__index = getfenv()}
	)
	local files = findTests('.')
	for _, file in ipairs(files) do
		pcall(
			function()
				dofileSandbox(file, env)
			end
		)
	end
	return tests
end

local args = {...}
local loglevel = 1
if (#args > 0) then
	if (tonumber(args[1]) ~= nil) then
		loglevel = tonumber(table.remove(args, 1))
	end
end
if (#args == 0) then
	print('Running startup tests...')
	print()
	runTests(loadAllTests(), loglevel)
else
	local allTests = loadAllTests()
	local testsToDo = {}
	for _, testName in ipairs(args) do
		local pattern = string.gsub(testName, '%.', '%%.')
		pattern = '^' .. string.gsub(pattern, '%*', '.*') .. '$'
		for _, testObj in ipairs(allTests) do
			if (string.match(testObj.fullName, pattern) ~= nil) then
				table.insert(testsToDo, testObj)
			end
		end
		runTests(testsToDo, loglevel)
	end
end
