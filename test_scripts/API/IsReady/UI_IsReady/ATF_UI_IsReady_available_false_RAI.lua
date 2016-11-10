print("\27[31m SDL crushes with DCHECK. Some tests are commented. After resolving uncomment tests!\27[0m")
---------------------------------------------------------------------------------------------
-- CRQ: APPLINK-25085: [GENIVI] UI interface: SDL behavior in case HMI does not respond to 
--                     IsReady_request or respond with "available" = false
--
-- Requirement(s): APPLINK-25046: [RegisterAppInterface] SDL behavior in case <Interface> 
--                                is not supported by system
--                 APPLINK-25102: [UI Interface] UI.IsReady(false) -> HMI respond with 
--                                successfull resultCode to splitted RPC
--                                 => only checked RPCs: GetSupportedLanguages
--                                                       GetLanguage
--                                                       GetCapabilities
--
--                 APPLINK-25299: [HMI_API] UI.IsReady
---------------------------------------------------------------------------------------------


TestedInterface = "UI"
Test = require('user_modules/IsReady_Template/ATF_Interface_IsReady_available_false_RAI_Template')

return Test