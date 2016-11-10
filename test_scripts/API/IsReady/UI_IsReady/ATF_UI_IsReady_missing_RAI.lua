print("\27[31m SDL crushes with DCHECK. Some tests are commented. After resolving uncomment tests!\27[0m")
---------------------------------------------------------------------------------------------
-- CRQ: APPLINK-25085: [GENIVI] UI interface: SDL behavior in case HMI does not respond to 
--                     IsReady_request or respond with "available" = false
--
-- Requirement(s): APPLINK-25064:[RegisterAppInterface] SDL behavior in case HMI does NOT 
--                               respond to IsReady request
--                 APPLINK-25099:[UI Interface] HMI does NOT respond to IsReady and mobile 
--                                app sends RPC that must be splitted
--                               => only checked RPCs: GetSupportedLanguages
--                                                     GetLanguage
--                                                     GetCapabilities
--                 APPLINK-25299:[HMI_API] UI.IsReady
---------------------------------------------------------------------------------------------


TestedInterface = "UI"
Test = require('user_modules/IsReady_Template/ATF_Interface_IsReady_missing_RAI_Template')

return Test