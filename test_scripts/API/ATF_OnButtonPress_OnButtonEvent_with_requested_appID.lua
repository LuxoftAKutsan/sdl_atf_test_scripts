---------------------------------------------------------------------------------------------
-- Author: I.Stoimenova
-- Creation date: 12.08.2016
-- Last update date: 22.08.2016
-- ATF version: 2.2
-- GOAL: The script implements CRQ APPLINK-25467: [GENIVI] Conditions for SDL to transfer 
--           OnButtonPress/OnButtonEvent (name = "OK") to app with requested <appID>
-- Functional and non-functional requirements of CRQ are covered in TCs.
---------------------------------------------------------------------------------------------
----------------------------- General Preparation -------------------------------------------
---------------------------------------------------------------------------------------------
	local commonSteps   = require('user_modules/shared_testcases/commonSteps')
	local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

	commonSteps:DeleteLogsFileAndPolicyTable()

	if ( commonSteps:file_exists(config.pathToSDL .. "policy.sqlite") == true ) then
		print("policy.sqlite is found in bin folder")
  	os.remove(config.pathToSDL .. "policy.sqlite")
	end
---------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Precondition: preparation connecttest_OnButtonSubscription.lua
--------------------------------------------------------------------------------
	os.execute(  'cp ./modules/connecttest.lua  ./user_modules/connecttest_OnButtonSubscription.lua')

	f = assert(io.open('./user_modules/connecttest_OnButtonSubscription.lua', "r"))

	fileContent = f:read("*all")
	f:close()

	-- add "Buttons.OnButtonSubscription"
	local pattern1 = "registerComponent%s-%(%s-\"Buttons\"%s-[%w%s%{%}.,\"]-%)"
	local pattern1Result = fileContent:match(pattern1)

	if pattern1Result == nil then 
		print(" \27[31m Buttons registerComponent function is not found in /user_modules/connecttest_OnButtonSubscription.lua \27[0m ")
	else
		fileContent  =  string.gsub(fileContent, pattern1, 'registerComponent("Buttons", {"Buttons.OnButtonSubscription"})')
	end

	local pattern2 = "%{%s-capabilities%s-=%s-%{.-%}"
	local pattern2Result = fileContent:match(pattern2)

	if pattern2Result == nil then 
		print(" \27[31m capabilities array is not found in /user_modules/connecttest_OnButtonSubscription.lua \27[0m ")
	else
		fileContent  =  string.gsub(fileContent, pattern2, '{capabilities = {button_capability("PRESET_0"),button_capability("PRESET_1"),button_capability("PRESET_2"),button_capability("PRESET_3"),button_capability("PRESET_4"),button_capability("PRESET_5"),button_capability("PRESET_6"),button_capability("PRESET_7"),button_capability("PRESET_8"),button_capability("PRESET_9"),button_capability("OK", true, false, true),button_capability("SEEKLEFT"),button_capability("SEEKRIGHT"),button_capability("TUNEUP"),button_capability("TUNEDOWN"),button_capability("CUSTOM_BUTTON")}')
	end

	f = assert(io.open('./user_modules/connecttest_OnButtonSubscription.lua', "w+"))
	f:write(fileContent)
	f:close()
--------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
---------------------- require system ATF files for script like -----------------------------
---------------------------------------------------------------------------------------------
	Test = require('user_modules/connecttest_OnButtonSubscription')
	require('cardinalities')
	local events 				   = require('events')
	local mobile_session   = require('mobile_session')
	local mobile  			   = require('mobile_connection')
	local tcp 						 = require('tcp_connection')
	local file_connection  = require('file_connection')
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
	require('user_modules/AppTypes')
	local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
	local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
	config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

	--ToDo: shall be removed when APPLINK-16610 is fixed
	config.defaultProtocolVersion = 2

	local applicationData = 
	{
		-- MEDIA application
		{
									syncMsgVersion =
																	{
		  															majorVersion = 3,
		  															minorVersion = 3
																	},
									appName = "TestAppMedia",
									isMediaApplication = true,
									languageDesired = 'EN-US',
									hmiDisplayLanguageDesired = 'EN-US',
									appHMIType = { "MEDIA" },
									appID = "0000002",
									deviceInfo =
																{
		  														os = "Android",
		  														carrier = "Megafon",
		  														firmwareRev = "Name: Linux, Version: 3.4.0-perf",
		  														osVersion = "4.4.2",
		  														maxNumberRFCOMMPorts = 1
																}
	  						},
	  -- NON-MEDIA application
		{
										syncMsgVersion =
																		{
		  																majorVersion = 3,
		  																minorVersion = 3
																		},
										appName = "TestAppNonMedia",
										isMediaApplication = false,
										languageDesired = 'EN-US',
										hmiDisplayLanguageDesired = 'EN-US',
										appHMIType = { "DEFAULT" },
										appID = "0000003",
										deviceInfo =
																{
		  														os = "Android",
		  														carrier = "Megafon",
		  														firmwareRev = "Name: Linux, Version: 3.4.0-perf",
		  														osVersion = "4.4.2",
		  														maxNumberRFCOMMPorts = 1
																}
	  							},
	  -- NAVIGATION
	  {
											syncMsgVersion =
																			{
		  																	majorVersion = 3,
		  																	minorVersion = 3
																			},
											appName = "TestAppNavigation",
											isMediaApplication = true,
											languageDesired = 'EN-US',
											hmiDisplayLanguageDesired = 'EN-US',
											appHMIType = { "NAVIGATION" },
											appID = "0000004",
											deviceInfo =
																	{
		  															os = "Android",
		  															carrier = "Megafon",
		  															firmwareRev = "Name: Linux, Version: 3.4.0-perf",
		  															osVersion = "4.4.2",
		  															maxNumberRFCOMMPorts = 1
																	}
	  								},
	  -- COMMUNICATION
	  {
													syncMsgVersion =
																					{
		  																			majorVersion = 3,
		  																			minorVersion = 3
																					},
													appName = "TestAppCommunication",
													isMediaApplication = false,
													languageDesired = 'EN-US',
													hmiDisplayLanguageDesired = 'EN-US',
													appHMIType = { "COMMUNICATION" },
													appID = "0000005",
													deviceInfo =
																				{
		  																		os = "Android",
		  																		carrier = "Megafon",
		  																		firmwareRev = "Name: Linux, Version: 3.4.0-perf",
		  																		osVersion = "4.4.2",
		  																		maxNumberRFCOMMPorts = 1
																				}
	  										}
	}

	-- HMI application ID
	local HMIAppID = {}

	-- HMI level of application
	local HMILevel = {}
	
	-- SessionNumber
	local SessionNumber = {}

	local BtnEventMode = {"BUTTONDOWN","BUTTONUP"}
	local BtnPressMode = {"LONG","SHORT"}

---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
-----------------------------------Local functions ------------------------------------------
---------------------------------------------------------------------------------------------
	local function userPrint( color, message)

		print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
	end

	--Begin Test case PositiveResponseCheck.5
		--Description: [OnButtonEvent/OnButtonPress] SDL receives notification for "OK" button 
		--             with <appID> from HMI
		--             Eventmode: BUTTONDOWN
		--             PressMode: LONG
		--Requirement id in JIRA:  APPLINK-25480; APPLINK-25479; APPLINK-20174
		--Verification criteria:
			-- In case application is in NONE HMILevel and HMI sends OnButtonEvent/OnButtonPress(name= "OK") with <appID>
			-- SDL must NOT transfer this OnButtonEvent/OnButtonPress notification to registered app in NONE
			local	function NoNotificationOnBtnPressEvent(self, appNum, BtnEvent, BtnPress)
								
				userPrint(34, "====================== Test Case 01 CorrectAppID_Button_OK_NONE_"..applicationData[appNum].appHMIType[1].."_"..BtnEvent.."_".. BtnPress .."=================================")								
				--hmi side: send notification
				self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {	name = "OK", mode = BtnEvent, appID = tonumber(applicationData[appNum].appID) })

				--hmi side: send notification
				self.hmiConnection:SendNotification("Buttons.OnButtonPress", {	name = "OK", mode = BtnPress, appID = tonumber(applicationData[appNum].appID) })
	
				print("Check for no notification from SDL to app "..applicationData[appNum].appHMIType[1] .. " HMI level: " ..HMILevel[appNum])

				--mobile side: expect notification
				SessionNumber[appNum]:ExpectNotification("OnButtonEvent",{})
				:Times(0)
 								
				SessionNumber[appNum]:ExpectNotification("OnButtonPress",{})
				:Times(0)
			
				commonTestCases:DelayedExp(10000)
			end
	--Begin Test case PositiveResponseCheck.5

	--function Precondition_UnregisterApp(self, session, iappID, nameTC)
	function Precondition_UnregisterApp(AppNum, nameTC)
		
		Test[nameTC .. "_UnregisterApp_" .. applicationData[AppNum].appHMIType[1] ] = function(self)		
			
			--mobile side: UnregisterAppInterface request 	
			local correlationId = SessionNumber[AppNum]:SendRPC("UnregisterAppInterface", {})
			
			--hmi side: expected  BasicCommunication.OnAppUnregistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = false})
			:Do(function(_,data)
				if( HMIAppID[AppNum] ~= nil) then
					if(data.params.appID ~= HMIAppID[AppNum]) then
						return false
					end
				end
			end)
			
			--mobile side: UnregisterAppInterface response 
			SessionNumber[AppNum]:ExpectResponse(correlationId, {success = true , resultCode = "SUCCESS"})

		end
	end

	function Precondition_StartSession(AppNum, nameTC)

	 	Test[nameTC .."_StartSession_" .. applicationData[AppNum].appHMIType[1] ] = function(self)

	 		SessionNumber[AppNum] = mobile_session.MobileSession(self, self.mobileConnection, applicationData[AppNum])
	 		SessionNumber[AppNum]:StartService(7)
 
   		end
  	end

	function Precondition_RegisterApp(AppNum, nameTC)

	 	Test[nameTC .. "_RegisterApp_" .. applicationData[AppNum].appHMIType[1] ] = function(self)	

			local correlationId = SessionNumber[AppNum]:SendRPC("RegisterAppInterface", applicationData[AppNum])

			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {})
			:Do(function(_,data)
				
				HMIAppID[AppNum] = data.params.application.appID

				--mobile side: expect notification
 				SessionNumber[AppNum]:ExpectNotification("OnHMIStatus", {{ hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}})
 				:Do(function (_,data)
 					HMILevel[AppNum] = "NONE"
 					
 					NoNotificationOnBtnPressEvent(self, AppNum, BtnEventMode[1], BtnPressMode[1]) 					
 				end)

 				--hmi side: expect notification
 				EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {appID = self.applications[applicationData[AppNum].appName], isSubscribed = true, name = "CUSTOM_BUTTON"})

			end)

			SessionNumber[AppNum]:ExpectResponse(correlationId, { success = true })

 		end 	
 	end

 	function Precondition_ActivateApp(AppNum, nameTC)
		-- Issue of ATF, OnHMIStatus  is not verified correctly: APPLINK-17030
 	
 		Test[nameTC .. "_ActivateApp_" .. applicationData[AppNum].appHMIType[1] ] = function(self)	
			--userPrint(35, "======================================= " ..nameTC .. "_" .. applicationData[AppNum].appHMIType[1] .. " ====================================")
 			local HMIlevelNotActiveApp = { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}
 			local HMIlevelActiveApp 	 = { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}
 			
 			if(applicationData[AppNum].isMediaApplication == true) then
 				HMIlevelActiveApp = { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}
 			end

 			
 			--hmi side: sending SDL.ActivateApp request
			local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = HMIAppID[AppNum] })

			--hmi side: expect SDL.ActivateApp response
			EXPECT_HMIRESPONSE(RequestId)

			--mobile side: expect notification
 			SessionNumber[AppNum]:ExpectNotification("OnHMIStatus", HMIlevelActiveApp)
 			:Do(function(_,data)
 				HMILevel[AppNum] = data.payload.hmiLevel

 				if(data.payload.hmiLevel ~= "FULL") then
 					userPrint(31, "HMI level of application " .. applicationData[AppNum].appHMIType[1] .." is not FULL")
 					return false
 				end
 			end)

 			-- Previous registered application becomes not active
 			if(AppNum > 1) then
 				if(applicationData[AppNum - 1].isMediaApplication == true) then
 					HMIlevelNotActiveApp = { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}
 				end
 				--mobile side: expect notification
 				SessionNumber[AppNum - 1]:ExpectNotification("OnHMIStatus", HMIlevelNotActiveApp )
 				:Do(function(_,data)
 					HMILevel[AppNum -1] = data.payload.hmiLevel
 					if(data.payload.hmiLevel == "FULL") then
 						userPrint(31, "HMI level of application " .. applicationData[AppNum - 1].appHMIType[1] .." is still FULL")
 						return false
 					end
 				end)
 			end

		end
 	end

--------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
 	--Begin Precondition.1
	Test["General Preconditions"] = function(self)
		userPrint(35, "======================================= Preconditions ====================================")
		SessionNumber = {self.mobileSession1, self.mobileSession2, self.mobileSession3, self.mobileSession4}

		--mobile side: UnregisterAppInterface request 
		local CorIdURAI = self.mobileSession:SendRPC("UnregisterAppInterface", {})

		--hmi side: expected  BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {})

		--mobile side: UnregisterAppInterface response 
		self.mobileSession:ExpectResponse(CorIdURAI, {success = true , resultCode = "SUCCESS"})
	end
	--End Precondition.1

	--Begin Precondition.2
		--Requirement id in JIRA: APPLINK-20120
		--[SubscribeButton] Default "CUSTOM_BUTTON" subscription

		for appNum = 1, #applicationData do
			Precondition_StartSession(appNum, "TC01")
			
			-- CUSTOM_BUTTON will be subscribed
			Precondition_RegisterApp(appNum, "TC01")
		end
	--End Precondition.2
---------------------------------------------------------------------------------------------	

---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)--
---------------------------------------------------------------------------------------------
	--Test Block is not applicable because CRQ checks HMI requests.
---------------------------------------------------------------------------------------------

for appNum = 1, #applicationData do
	
	--Precondition Test case PositiveResponseCheck/NegativeRequestCheck
	Precondition_ActivateApp(appNum, "Precondition")

	-- OK button will be subscribed
	Test["TC02_Precondition_SubscribeBtn_OK"] = function(self)
 			local strAppName = applicationData.appName
				
 			--mobile side: sending SubscribeButton request
 			local cid = SessionNumber[appNum]:SendRPC("SubscribeButton",{buttonName = "OK"})

 			--hmi side: expect Buttons.OnButtonSubscription
 			EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {appID = self.applications[strAppName], isSubscribed = true, name = "OK"})
 			:Do(function(_,data) 
				--mobile side: expect SubscribeButton response
				SessionNumber[appNum]:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
					
 				--mobile side: expect notification
 				SessionNumber[appNum]:ExpectNotification("OnHashChange",{})
 			end)
	end
	
	for BtnEvent = 1, #BtnEventMode do
		for BtnPress = 1, #BtnPressMode do
			---------------------------------------------------------------------------------------------
			----------------------------------------II TEST BLOCK----------------------------------------
			----------------------------------------Positive cases---------------------------------------
			--Positive cases: Check of positive value of request/response parameters (mobile protocol, HMI protocol)
			---------------------------------------------------------------------------------------------
				--Begin Test suit PositiveResponseCheck
		
					--Begin Test case PositiveResponseCheck.1
					--Description: [OnButtonEvent/OnButtonPress] SDL receives notification for "OK" button 
					--             without <appID> from HMI
					--             Eventmode: BUTTONDOWN; BUTTONUP
					--             PressMode: LONG; SHORT
					--Requirement id in JIRA:  APPLINK-25481; APPLINK-25482; APPLINK-20174
					--Verification criteria:
						-- In case application is in FULL HMILevel and HMI sends OnButtonEvent/OnButtonPress(name= "OK") without <appID>
						-- SDL must transfer this OnButtonEvent notification to registered app in FULL only
						Test["TC02_OnButtonEventPress_OK_without_appID_"..applicationData[appNum].appHMIType[1] .."_"..BtnEventMode[BtnEvent].."_".. BtnPressMode[BtnPress] ] = function (self)
							userPrint(34, "====================== Test Case 01 No_appID_Button_OK_"..applicationData[appNum].appHMIType[1] .."_"..BtnEventMode[BtnEvent].."_".. BtnPressMode[BtnPress].."=================================")
							
							--hmi side: send notification
							self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {	name = "OK", mode = BtnEventMode[BtnEvent]})

							--hmi side: send notification
							self.hmiConnection:SendNotification("Buttons.OnButtonPress", {	name = "OK", mode = BtnPressMode[BtnPress]})

							for allApp = 1 , appNum do
								if(HMILevel[allApp] ~= FULL) then
									print("Check for no notification from SDL to app "..applicationData[allApp].appHMIType[1] .. " HMI level: " ..HMILevel[allApp])

 							 		--mobile side: expect notification
 							 		SessionNumber[allApp]:ExpectNotification("OnButtonEvent",{})
 							 		:Times(0)

 							 		SessionNumber[allApp]:ExpectNotification("OnButtonPress",{})
 							 		:Times(0)
 							 	else
 							 		print("Application "..applicationData[allApp].appHMIType[1] .. " has HMI level: " .. HMILevel[allApp])

 							 		--mobile side: expect notification
 							 		SessionNumber[allApp]:ExpectNotification("OnButtonEvent", {	buttonName = "OK", buttonEventMode = BtnEventMode[BtnEvent]} )

 							 		--mobile side: expect notification
 								 	SessionNumber[allApp]:ExpectNotification("OnButtonPress", {	buttonName = "OK", buttonPressMode = BtnPressMode[BtnPress]} )
								end
							end

						end
					--End Test case PositiveResponseCheck.1

					--Begin Test case PositiveResponseCheck.2
					--Description: [OnButtonEvent/OnButtonPress] SDL receives notification for "OK" button 
					--             with <appID> from HMI
					--             Eventmode: BUTTONDOWN; BUTTONUP
					--             PressMode: LONG; SHORT
					--Requirement id in JIRA:  APPLINK-25480; APPLINK-25479; APPLINK-20174
					--Verification criteria:
						-- In case application is in FULL HMILevel and HMI sends OnButtonEvent/OnButtonPress(name= "OK") with <appID>
						-- SDL must transfer this OnButtonEvent notification to registered app in FULL
						Test["TC03_OnButtonEventPress_OK_with_appID_FULL_"..applicationData[appNum].appHMIType[1] .."_"..BtnEventMode[BtnEvent].."_".. BtnPressMode[BtnPress] ] = function (self)
							userPrint(34, "====================== Test Case 02 CorrectAppID_Button_OK_FULL_"..applicationData[appNum].appHMIType[1] .."_"..BtnEventMode[BtnEvent].."_".. BtnPressMode[BtnPress].."=================================")
							
							--hmi side: send notification
							self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {	name = "OK", mode = BtnEventMode[BtnEvent], appID = tonumber(applicationData[appNum].appID) })

							--hmi side: send notification
							self.hmiConnection:SendNotification("Buttons.OnButtonPress", {	name = "OK", mode = BtnPressMode[BtnPress], appID = tonumber(applicationData[appNum].appID)})

							--mobile side: expect notification
 							SessionNumber[appNum]:ExpectNotification("OnButtonEvent", {	buttonName = "OK", buttonEventMode = BtnEventMode[BtnEvent]} )

 							--mobile side: expect notification
 							SessionNumber[appNum]:ExpectNotification("OnButtonPress", {	buttonName = "OK", buttonPressMode = BtnPressMode[BtnPress]} )

							print("Application "..applicationData[appNum].appHMIType[1] .. " has HMI level: " .. HMILevel[appNum])
 							if(appNum > 1) then
 								for notActiveApp = 1, (appNum - 1) do
 									print("Check for no notification from SDL to app "..applicationData[notActiveApp].appHMIType[1] .. " HMI level: " ..HMILevel[notActiveApp])

 									--mobile side: expect notification
 									SessionNumber[notActiveApp]:ExpectNotification("OnButtonEvent",{})
 									:Times(0)
 								
 									SessionNumber[notActiveApp]:ExpectNotification("OnButtonPress",{})
 									:Times(0)

 								end
 								commonTestCases:DelayedExp(10000)
 							end
						end
					--End Test case PositiveResponseCheck.2			
						
					--Begin Test case PositiveResponseCheck.3
					--Description: [OnButtonEvent/OnButtonPress] SDL receives notification for "OK" button 
					--             with <appID> from HMI
					--             Eventmode: BUTTONDOWN; BUTTONUP
					--             PressMode: LONG; SHORT
					--Requirement id in JIRA:  APPLINK-25480; APPLINK-25479; APPLINK-20174
					--Verification criteria:
						-- In case application is in LIMITED HMILevel and HMI sends OnButtonEvent/OnButtonPress(name= "OK") with <appID>
						-- SDL must transfer this OnButtonEvent notification to registered app in LIMITED
						Test["TC04_OnButtonEventPress_OK_with_appID_LIMITED_"..BtnEventMode[BtnEvent].."_".. BtnPressMode[BtnPress]] = function (self)
							local limitedApp = 0

							if(appNum > 1) then
								if(HMILevel[appNum -1] == "LIMITED") then

									limitedApp = appNum -1
									
									userPrint(34, "====================== Test Case 03 CorrectAppID_Button_OK_LIMITED_"..applicationData[limitedApp].appHMIType[1] .."_"..BtnEventMode[BtnEvent].."_".. BtnPressMode[BtnPress].."=================================")
								
									--hmi side: send notification
									self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {	name = "OK", mode = BtnEventMode[BtnEvent], appID = tonumber(applicationData[limitedApp].appID) })

									--hmi side: send notification
									self.hmiConnection:SendNotification("Buttons.OnButtonPress", {	name = "OK", mode = BtnPressMode[BtnPress], appID = tonumber(applicationData[limitedApp].appID) })

									--mobile side: expect notification
 									SessionNumber[limitedApp]:ExpectNotification("OnButtonEvent", {	buttonName = "OK", buttonEventMode = BtnEventMode[BtnEvent]} )

	 								--mobile side: expect notification
 									SessionNumber[limitedApp]:ExpectNotification("OnButtonPress", {	buttonName = "OK", buttonPressMode = BtnPressMode[BtnPress]} )

									print("Application "..applicationData[limitedApp].appHMIType[1] .. " has HMI level: " .. HMILevel[limitedApp])

									--mobile side: doesn't expect notification. Application in FULL
 									SessionNumber[appNum]:ExpectNotification("OnButtonEvent",{})
 									:Times(0)
 								
 									SessionNumber[appNum]:ExpectNotification("OnButtonPress",{})
 									:Times(0)
 									
 									
 									for notLimitedApp = 1, (appNum - 1) do
 										if(notLimitedApp ~= limitedApp) then
 											print("Check for no notification from SDL to app "..applicationData[notLimitedApp].appHMIType[1] .. " HMI level: " ..HMILevel[notLimitedApp])

											--mobile side: expect notification
											SessionNumber[notLimitedApp]:ExpectNotification("OnButtonEvent",{})
											:Times(0)
 								
											SessionNumber[notLimitedApp]:ExpectNotification("OnButtonPress",{})
											:Times(0)
										end
									end
									commonTestCases:DelayedExp(10000)

 								end -- if(HMILevel[appNum -1] == "LIMITED") then
 							end -- (appNum > 1) then
						end
					--End Test case PositiveResponseCheck.3

					--Begin Test case PositiveResponseCheck.4
					--Description: [OnButtonEvent/OnButtonPress] SDL receives notification for "OK" button 
					--             with <appID> from HMI
					--             Eventmode: BUTTONDOWN; BUTTONUP
					--             PressMode: LONG; SHORT
					--Requirement id in JIRA:  APPLINK-25480; APPLINK-25479; APPLINK-20174
					--Verification criteria:
						-- In case application is in BACKGROUND/NONE HMILevel and HMI sends OnButtonEvent/OnButtonPress(name= "OK") with <appID>
						-- SDL must NOT transfer this OnButtonEvent/OnButtonPress notification to registered app in BACKGROUND/NONE
						Test["TC05_OnButtonEventPress_OK_with_appID_BACKGROUND_"..BtnEventMode[BtnEvent].."_".. BtnPressMode[BtnPress]] = function (self)
							local backgroundApp = 0

							if(appNum > 1) then
								if( (HMILevel[appNum -1] == "BACKGROUND") or (HMILevel[appNum -1] == "NONE") )  then

									backgroundApp = appNum -1
									
									userPrint(34, "====================== Test Case 04 CorrectAppID_Button_OK_BACKGROUND_"..applicationData[backgroundApp].appHMIType[1] .."_"..BtnEventMode[BtnEvent].."_".. BtnPressMode[BtnPress].."=================================")
								
									--hmi side: send notification
									self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {	name = "OK", mode = BtnEventMode[BtnEvent], appID = tonumber(applicationData[backgroundApp].appID) })

									--hmi side: send notification
									self.hmiConnection:SendNotification("Buttons.OnButtonPress", {	name = "OK", mode = BtnPressMode[BtnPress], appID = tonumber(applicationData[backgroundApp].appID) })


 									for i = 1, appNum  do
										print("Check for no notification from SDL to app "..applicationData[i].appHMIType[1] .. " HMI level: " ..HMILevel[i])

										--mobile side: expect notification
										SessionNumber[i]:ExpectNotification("OnButtonEvent",{})
										:Times(0)
 								
										SessionNumber[i]:ExpectNotification("OnButtonPress",{})
										:Times(0)
									end
	
									commonTestCases:DelayedExp(10000)

 								end -- if( (HMILevel[appNum -1] == "BACKGROUND") or (HMILevel[appNum -1] == "NONE") ) 
 							end -- (appNum > 1) then
						end
					--End Test case PositiveResponseCheck.4
						
				--End Test suit PositiveResponseCheck
			---------------------------------------------------------------------------------------------

			----------------------------------------------------------------------------------------------
			----------------------------------------III TEST BLOCK----------------------------------------
			------------------------------------Negative request cases------------------------------------
			--Check of negative value of request/response parameters (mobile protocol, HMI protocol)------
			----------------------------------------------------------------------------------------------
			--Begin Test suit NegativeRequestCheck
			--End Test suit NegativeRequestCheck
			--Tests are not applicable because CRQ checks SDL behaviour according to HMI notification
			----------------------------------------------------------------------------------------------

			----------------------------------------------------------------------------------------------
			----------------------------------------IV TEST BLOCK-----------------------------------------
			---------------------------------------Result codes check-------------------------------------
			------------------Check of each resultCode + success (true, false)----------------------------
				--Begin Test suit ResultCodesCheck
				--End Test suit ResultCodesCheck
				--Tests are not applicable because CRQ checks SDL behaviour according to HMI notification
			----------------------------------------------------------------------------------------------

			----------------------------------------------------------------------------------------------
			----------------------------------------V TEST BLOCK------------------------------------------
			------------------------------------ HMI negative cases---------------------------------------
			----------------------------------incorrect data from HMI-------------------------------------  
  		--Begin Test suit HMINegativeCases
  			--Begin Test case NegativeRequestCheck.1
					--Description:  [OnButtonEvent/OnButtonPress] SDL receives notification for "OK" button 
					--             with <Invalid_appID> from HMI
					--             Eventmode: BUTTONDOWN; BUTTONUP
					--             PressMode: LONG; SHORT
					--Requirement id in JIRA: APPLINK-25511; APPLNIK-25512; APPLINK-20174
					--Verification criteria: 
						-- In case application is in FULL/LIMITED HMILevel and HMI sends OnButtonEvent/OnButtonPress(name= "OK") with <Invalid_appID>
						-- SDL must NOT transfer this OnButtonEvent/OnButtonPress notification to registered app in FULL/LIMITED
						Test["TC06_OnButtonEventPress_OK_wrong_appID"] = function (self)
							userPrint(34, "====================== Test Case 05 Wrong_appID_Button_OK_"..applicationData[appNum].appHMIType[1] .."_"..BtnEventMode[BtnEvent].."_".. BtnPressMode[BtnPress].."=================================")
							
							--hmi side: send notification
							self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {	name = "OK", mode = BtnEventMode[BtnEvent], appID = 9999999 })

							--hmi side: send notification
							self.hmiConnection:SendNotification("Buttons.OnButtonPress", {	name = "OK", mode = BtnPressMode[BtnPress], appID = 9999999 })
 							
 							for i = 1, appNum do
 								print("Check for no notification from SDL to app "..applicationData[i].appHMIType[1] .. " HMI level: " ..HMILevel[i])

 								--mobile side: expect notification
 								SessionNumber[i]:ExpectNotification("OnButtonEvent",{})
 								:Times(0)
 								
 								SessionNumber[i]:ExpectNotification("OnButtonPress",{})
 								:Times(0)
 							end
 							commonTestCases:DelayedExp(10000)
 						end
				--End Test case NegativeRequestCheck.1		

				--Begin Test case NegativeRequestCheck.2
					--Description:  [OnButtonEvent/OnButtonPress] SDL receives notification for "CUSTOM_BUTTON" button 
					--             with <Invalid_appID> from HMI
					--             Eventmode: BUTTONDOWN; BUTTONUP
					--             PressMode: LONG; SHORT
					--Requirement id in JIRA:  APPLNIK-25512
					--Verification criteria: 
						-- In case application is in FULL/LIMITED HMILevel and HMI sends OnButtonEvent/OnButtonPress(name= "CUSTOM_BUTTON") with <Invalid_appID>
						-- SDL must NOT transfer this OnButtonEvent/OnButtonPress notification to registered app in FULL/LIMITED
						Test["TC0_OnButtonEventPress_CUSTOM_BUTTON_wrong_appID"] = function (self)
							userPrint(34, "====================== Test Case 06 Wrong_appID_CUSTOM_BUTTON_"..applicationData[appNum].appHMIType[1] .."_"..BtnEventMode[BtnEvent].."_".. BtnPressMode[BtnPress].."=================================")
							
							--hmi side: send notification
							self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {	name = "CUSTOM_BUTTON", mode = BtnEventMode[BtnEvent], appID = 9999999 })

							--hmi side: send notification
							self.hmiConnection:SendNotification("Buttons.OnButtonPress", {	name = "CUSTOM_BUTTON", mode = BtnPressMode[BtnPress], appID = 9999999 })

							print("Application "..applicationData[appNum].appHMIType[1] .. " has HMI level: " .. HMILevel[appNum])
 							
 							for i = 1, appNum do
 								print("Check for no notification from SDL to app "..applicationData[i].appHMIType[1] .. " HMI level: " ..HMILevel[i])

 								--mobile side: expect notification
 								SessionNumber[i]:ExpectNotification("OnButtonEvent",{})
 								:Times(0)
 								
 								SessionNumber[i]:ExpectNotification("OnButtonPress",{})
 								:Times(0)
 							end
 							commonTestCases:DelayedExp(10000)
 						end
				--End Test case NegativeRequestCheck.2
  		--End Test suit HMINegativeCases

  	end -- for BtnPress = 1, #BtnPressMode do
	end -- for BtnEvent = 1, #BtnEventMode do		
end -- for appNum = 1, #applicationData do
  

----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------
----------------------------------------VI TEST BLOCK-----------------------------------------
--------------------------Sequence with emulating of user's action(s)-------------------------
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
  --Tests are done in scope of checking all possible combinations of ButtonEvent and ButtonPress
  --See previous tests.

----------------------------------------------------------------------------------------------
----------------------------------------VII TEST BLOCK----------------------------------------
-------------------------------------Different HMIStatus--------------------------------------
--processing of request/response in different HMIlevels, SystemContext, AudioStreamingState---
	--Tests are done in scope of checking all possible combinations of ButtonEvent and ButtonPress
  --See previous tests.
----------------------------------------------------------------------------------------------

return Test