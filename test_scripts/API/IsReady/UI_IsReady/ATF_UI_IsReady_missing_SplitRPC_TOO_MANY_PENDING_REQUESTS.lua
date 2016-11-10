---------------------------------------------------------------------------------------------
-- CRQ: APPLINK-25085: [GENIVI] UI interface: SDL behavior in case HMI does not respond to 
--                     IsReady_request or respond with "available" = false
--
-- Requirement(s): APPLINK-25099:[UI Interface] HMI does NOT respond to IsReady and 
--                               mobile app sends RPC that must be splitted
--                 APPLINK-25299:[HMI_API] UI.IsReady
---------------------------------------------------------------------------------------------


TestedInterface = "UI"
Tested_resultCode = "TOO_MANY_PENDING_REQUESTS" 
Tested_wrongJSON = false


Test = require('user_modules/IsReady_Template/ATF_Interface_IsReady_missing_SplitRPC_Template')

return Test