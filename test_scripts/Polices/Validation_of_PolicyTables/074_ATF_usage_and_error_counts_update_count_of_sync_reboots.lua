---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] "usage_and_error_counts" and "count_of_sync_reboots" update
--
-- Check SDL behavior in case got SDL.OnSystemError("SYNC_REBOOTED")
-- 1. Used preconditions:
-- Start default SDL
-- InitHMI register MobileApp
--
-- 2. Performed steps:
-- Send DL.OnSystemError("SYNC_REBOOTED") from HMI
-- Check LocalPT changes
--
-- Expected result:
-- SDL must: increment "count_of_sync_reboots" section value of Local Policy Table.
---------------------------------------------------------------------------------------------


--[[ Required Shared libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')

--[[ General configuration parameters ]]
Test = require('user_modules/dummy_connecttest')
local config = require('config')
config.defaultProtocolVersion = 2
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
require('user_modules/AppTypes')

--[[ Local Variables ]]

local TESTED_DATA = {
  policy_table = {
    usage_and_error_counts = {
      count_sync_out_of_memory = 0,
      count_of_iap_buffer_full = 0,
      count_of_sync_reboots = 7
    }
  }
}

local TestData = {
  path = config.pathToSDL .. "TestData",
  isExist = false,
  init = function(self)
    if not self.isExist then
      os.execute("mkdir ".. self.path)
      os.execute("echo 'List test data files files:' > " .. self.path .. "/index.txt")
      self.isExist = true
    end
  end,
  store = function(self, message, pathToFile, fileName)
    if self.isExist then
      local dataToWrite = message

      if pathToFile and fileName then
        os.execute(table.concat({"cp ", pathToFile, " ", self.path, "/", fileName}))
        dataToWrite = table.concat({dataToWrite, " File: ", fileName})
      end

      dataToWrite = dataToWrite .. "\n"
      local file = io.open(self.path .. "/index.txt", "a+")
      file:write(dataToWrite)
      file:close()
    end
  end,
  delete = function(self)
    if self.isExist then
      os.execute("rm -r -f " .. self.path)
      self.isExist = false
    end
  end,
  info = function(self)
    if self.isExist then
      commonFunctions:userPrint(35, "All test data generated by this test were stored to folder: " .. self.path)
    else
      commonFunctions:userPrint(35, "No test data were stored" )
    end
  end
}

local function constructPathToDatabase()
  if commonSteps:file_exists(config.pathToSDL .. "storage/policy.sqlite") then
    return config.pathToSDL .. "storage/policy.sqlite"
  elseif commonSteps:file_exists(config.pathToSDL .. "policy.sqlite") then
    return config.pathToSDL .. "policy.sqlite"
  else
    commonFunctions:userPrint(31, "policy.sqlite is not found" )
    return nil
  end
end

local function executeSqliteQuery(rawQueryString, dbFilePath)
  if not dbFilePath then
    return nil
  end
  local queryExecutionResult = {}
  local queryString = table.concat({"sqlite3 ", dbFilePath, " '", rawQueryString, "'"})
  local file = io.popen(queryString, 'r')
  if file then
    local index = 1
    for line in file:lines() do
      queryExecutionResult[index] = line
      index = index + 1
    end
    file:close()
    return queryExecutionResult
  else
    return nil
  end
end

local function isValuesCorrect(actualValues, expectedValues)
  if #actualValues ~= #expectedValues then
    return false
  end

  local tmpExpectedValues = {}
  for i = 1, #expectedValues do
    tmpExpectedValues[i] = expectedValues[i]
  end

  local isFound
  for j = 1, #actualValues do
    isFound = false
    for key, value in pairs(tmpExpectedValues) do
      if value == actualValues[j] then
        isFound = true
        tmpExpectedValues[key] = nil
        break
      end
    end
    if not isFound then
      return false
    end
  end
  if next(tmpExpectedValues) then
    return false
  end
  return true
end

function Test.checkLocalPT(checkTable)
  local expectedLocalPtValues
  local queryString
  local actualLocalPtValues
  local comparationResult
  local isTestPass = true
  for _, check in pairs(checkTable) do
    expectedLocalPtValues = check.expectedValues
    queryString = check.query
    actualLocalPtValues = executeSqliteQuery(queryString, constructPathToDatabase())
    if actualLocalPtValues then
      comparationResult = isValuesCorrect(actualLocalPtValues, expectedLocalPtValues)
      if not comparationResult then
        TestData:store(table.concat({"Test ", queryString, " failed: SDL has wrong values in LocalPT"}))
        TestData:store("ExpectedLocalPtValues")
        commonFunctions:userPrint(31, table.concat({"Test ", queryString, " failed: SDL has wrong values in LocalPT"}))
        commonFunctions:userPrint(35, "ExpectedLocalPtValues")
        for _, values in pairs(expectedLocalPtValues) do
          TestData:store(values)
          print(values)
        end
        TestData:store("ActualLocalPtValues")
        commonFunctions:userPrint(35, "ActualLocalPtValues")
        for _, values in pairs(actualLocalPtValues) do
          TestData:store(values)
          print(values)
        end
        isTestPass = false
      end
    else
      TestData:store("Test failed: Can't get data from LocalPT")
      commonFunctions:userPrint(31, "Test failed: Can't get data from LocalPT")
      isTestPass = false
    end
  end
  return isTestPass
end

function Test:onSystemError(errorMessage)
  self.hmiConnection:SendNotification("SDL.OnSystemError", { error = errorMessage })
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition()
  TestData:init(self)
end

function Test:SDLStatePrecondition() 
  self:runSDL()
  commonFunctions:waitForSDLStart(self):Do(function()
    self:initHMI():Do(function()
      commonFunctions:userPrint(35, "HMI initialized")
      self:initHMI_onReady():Do(function ()
        commonFunctions:userPrint(35, "HMI is ready")
        self:connectMobile():Do(function ()
          commonFunctions:userPrint(35, "Mobile Connected")
          self:startSession()
        end)
      end)
    end)
  end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:HMIsendOnSystemError()
  for _ = 1, 3 do
    os.execute("sleep 2")
    print("Calling onSystemError(SYNC_REBOOTED)") 
    self:onSystemError("SYNC_REBOOTED")
  end
end

function Test:StopSDL()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
    { reason = "SUSPEND" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete"):Do(function()
    print("Received BasicCommunication.OnSDLPersistenceComplete, stopping SDL")
    StopSDL()
  end)
end

function Test:StartSDL2() 
  self:runSDL()
  commonFunctions:waitForSDLStart(self):Do(function()
    self:initHMI():Do(function()
      commonFunctions:userPrint(35, "HMI initialized")
      self:initHMI_onReady():Do(function ()
        commonFunctions:userPrint(35, "HMI is ready")
        self:connectMobile():Do(function ()
          commonFunctions:userPrint(35, "Mobile Connected")
          self:startSession()
        end)
      end)
    end)
  end)
end

function Test:HMIsendOnSystemError2()
  for _ = 1, 4 do
    os.execute("sleep 2")
    print("Calling onSystemError(SYNC_REBOOTED)") 
    self:onSystemError("SYNC_REBOOTED")
  end
end

function Test:StopSDL2()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
    { reason = "SUSPEND" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete"):Do(function()
    print("Received BasicCommunication.OnSDLPersistenceComplete, stopping SDL")
    StopSDL()
  end)
end

function Test:CheckPTUinLocalPT()
  TestData:store("Store LocalPT after SDL.onSystemError", constructPathToDatabase(), "policy.sqlite" )
  local checks = {
    {
      query = 'select count_of_iap_buffer_full, count_sync_out_of_memory, count_of_sync_reboots from usage_and_error_count',
      expectedValues = {table.concat(
          {
            TESTED_DATA.policy_table.usage_and_error_counts.count_of_iap_buffer_full, "|",
            TESTED_DATA.policy_table.usage_and_error_counts.count_sync_out_of_memory, "|",
            TESTED_DATA.policy_table.usage_and_error_counts.count_of_sync_reboots
          })
      }
    }
  }
  if not self.checkLocalPT(checks) then
    self:FailTestCase("SDL has wrong values in LocalPT")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition()
  commonSteps:DeletePolicyTable()
  TestData:info()
end

return Test