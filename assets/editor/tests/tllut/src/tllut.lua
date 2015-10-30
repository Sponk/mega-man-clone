-- tllut.lua - The main framework

local tllut = {}
local suites = {}

local testdata = {}
local currentTestName = ""

local TEST_FAIL = 0
local TEST_SUCCESS = 1

--- Adds a suite to the current testing setup
--
-- The table should be structured like
-- /code
-- function functionA() end
-- function functionB() end
--
-- local suite = { ["functionA"] = functionA, ["functionB"] = functionB }
-- /endcode
-- @param s A table containing all functions to test
function tllut:addSuite(s)
   table.insert(suites, s)
end

function tllut:runSuite(s)
   for k,v in pairs(s) do
	  if type(v) == "function" then
		 currentTestName = k
		 testdata[currentTestName] = {status = TEST_SUCCESS, name = currentTestName}
  
		 print("==> Running '" .. k .. "'")
		 v()
		 print()
	  end
   end
end

--- Runs all suites registered with the current testing setup
function tllut:runAll()
   for i,v in ipairs(suites) do
	  self:runSuite(v)
   end
end

--- Prints the result of the current testing setup.
function tllut:printResult()
   local num = 0
   local percentage = 0
   local length = 0
   
   for k,v in pairs(testdata) do
	  if v.status == TEST_SUCCESS then
		 print("Passed Test: " .. v.name)
		 num = num + 1
	  else
		 print("Failed Test: " .. v.name)
	  end

	  length = length + 1
   end

   if num > 0 then
	  percentage = (num/length * 100)
   end
   
   print("This suite passed " .. num .. " out of " .. length
			.. " tests, that is " .. percentage .. "%")

   if percentage < 50 then
	  print("Go and fix your shit!")
   end
end

--- Checks if the arguments are equal
-- @param expected The expected value
-- @param actual The actual value that was found
-- @param failmsg An optional message that gets printed at failure
function assertEquals(expected, actual, failmsg) 

   local info = debug.getinfo(2)
   info = info.short_src .. ":" .. info.linedefined
   if expected ~= actual then
	  print("Assertion failed: Expected value '" .. tostring(expected) .. "' but got '" .. tostring(actual) .. "' at " .. info)
	  io.write((failmsg or ""))
	  testdata[currentTestName] = {status = TEST_FAIL, name = currentTestName}
	  return
   end

   -- print("Assertion passed with value " .. actual)
end

--- Checks if the arguments are not equal
-- @param expected The expected value
-- @param actual The actual value that was found
-- @param failmsg An optional message that gets printed at failure
function assertNotEquals(expected, actual, failmsg) 

   local info = debug.getinfo(2)
   info = info.short_src .. ":" .. info.linedefined
   if expected == actual then
	  print("Assertion failed: Did not expect value '" .. tostring(expected) .. "' and got '" .. tostring(actual) .. "' at " .. info)
	  io.write((failmsg or ""))
	  testdata[currentTestName] = {status = TEST_FAIL, name = currentTestName}
	  return
   end

   -- print("Assertion passed with value " .. actual)
end

local function compareTables(t1, t2)

   local lt1 = 0
   local lt2 = 0

   -- Compare every element and count elements in t1
   for k,v in pairs(t1) do
	  lt1 = lt1 + 1

	  -- If the element is not equal, return false
	  if t2[k] ~= v then
		 return false
	  end
   end

   -- Count all elements in t2
   for k,v in pairs(t2) do
	  lt2 = lt2 + 1
   end

   -- If the don't have the same length, they can't be equal
   return (lt2 == lt1)
end

local function table2string(t)
   local str = "{ "
   for k,v in pairs(t) do
	  str = str .. "[" .. k .. "]" .. " = " .. v .. ", "
   end

   str = str:sub(0, str:len() - 2)
   
   return str .. " }"
end


--- Checks if the argument tables are equal
-- @param expected The expected value
-- @param actual The actual value that was found
-- @param failmsg An optional message that gets printed at failure
function assertArrayEquals(expected, actual, failmsg) 

   local info = debug.getinfo(2)
   info = info.short_src .. ":" .. info.linedefined
   if not compareTables(expected, actual) then
	  print("Assertion failed: Expected value '" .. table2string(expected) .. "' but got '" .. table2string(actual) .. "' at " .. info)
	  io.write((failmsg or ""))
	  testdata[currentTestName] = {status = TEST_FAIL, name = currentTestName}
	  return
   end

   -- print("Assertion passed with value " .. actual)
end

return tllut
