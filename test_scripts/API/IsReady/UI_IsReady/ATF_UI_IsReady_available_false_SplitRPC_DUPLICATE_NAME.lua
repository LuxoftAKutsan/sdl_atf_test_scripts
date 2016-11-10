---------------------------------------------------------------------------------------------
-- CRQ: APPLINK-25085: [GENIVI] UI interface: SDL behavior in case HMI does not respond to 
--                     IsReady_request or respond with "available" = false
--
-- Requirement(s): APPLINK-25100 [UI Interface] UI.IsReady(false) -> HMI respond with 
--                                errorCode to splitted RPC 
--                 APPLINK-25102 [UI Interface] UI.IsReady(false) -> HMI respond with 
--                                successfull resultCode to splitted RPC 
--                 APPLINK-25299:[HMI_API] UI.IsReady
---------------------------------------------------------------------------------------------


TestedInterface = "UI"
Tested_resultCode = "DUPLICATE_NAME" 
Tested_wrongJSON = false


Test = require('user_modules/IsReady_Template/ATF_Interface_IsReady_available_false_SplitRPC_Template')

return Test