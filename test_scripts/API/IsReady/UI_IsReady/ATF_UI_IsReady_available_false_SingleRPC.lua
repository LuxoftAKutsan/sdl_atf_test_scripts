---------------------------------------------------------------------------------------------
-- CRQ: APPLINK-25085: [GENIVI] UI interface: SDL behavior in case HMI does not respond to 
--                     IsReady_request or respond with "available" = false
--
-- Requirement(s): APPLINK-25045:[UI Interface] Conditions for SDL to respond 
--                               'UNSUPPORTED_RESOURCE, success:false' to mobile app
--                 APPLINK-25299:[HMI_API] UI.IsReady
---------------------------------------------------------------------------------------------


TestedInterface = "UI"

Test = require('user_modules/IsReady_Template/ATF_Interface_IsReady_available_false_SingleRPC_Template')

return Test