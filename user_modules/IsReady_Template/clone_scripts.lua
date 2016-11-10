local script = {}

	All_resultCode = { "SUCCESS", "WARNINGS", "WRONG_LANGUAGE", "RETRY", "SAVED", 	"",  "ABC",	"UNSUPPORTED_REQUEST","DISALLOWED", 
	               "USER_DISALLOWED", "REJECTED", "ABORTED", "IGNORED", "IN_USE", "VEHICLE_DATA_NOT_AVAILABLE", "TIMED_OUT", "INVALID_DATA",
 				   "CHAR_LIMIT_EXCEEDED", "INVALID_ID", "DUPLICATE_NAME", "APPLICATION_NOT_REGISTERED", "OUT_OF_MEMORY", "TOO_MANY_PENDING_REQUESTS",
 				   "GENERIC_ERROR", "TRUNCATED_DATA", "UNSUPPORTED_RESOURCE"}


	file_name = "ATF_UI_IsReady_missing_SpliRPC"
	file_path = "./test_scripts/"
	file_extension = ".lua"
	resulCode = "SUCCESS"

	--Check file existence
	local function file_exists(name)
	   	local f=io.open(name,"r")

	   	if f ~= nil then 
	   		io.close(f)
	   		return true
	   	else 
	   		return false 
	   	end
	end

	--replace result code in general file
	local function replace_resultCode(file, result)
		local patternResultCode = ".?Tested_resultCode.?=.?([^\n]*)"
		local new_ResultCode = "\nTested_resultCode = \""..result.."\" \n"

		local pattern_wrongJSON = ".?Tested_wrongJSON.?=.?([^\n]*)"
		local new_wrongJSON = "Tested_wrongJSON = false\n"

		if(result == "SUCCESS") then
			new_wrongJSON = "Tested_wrongJSON = true\n"
		end

		f = assert(io.open(file, "r"))
		fileContent = f:read("*all")
		f:close()
		
		fileContent = string.gsub(fileContent, patternResultCode, new_ResultCode)
		fileContent = string.gsub(fileContent, pattern_wrongJSON, new_wrongJSON)
		f = assert(io.open(file, "w+"))
		f:write(fileContent)
		f:close()

		
	end

	

	file_to_copy = file_path ..file_name ..file_extension
	
	
	if( file_exists(file_to_copy) == true) then
		
		for i = 1, #All_resultCode do
			resulCode = All_resultCode[i]
			
			new_file = file_path .. file_name .. "_"..resulCode..file_extension
			if(resulCode == "") then
				new_file = file_path .. file_name .. "_empty"..file_extension
			end
			print("SUCCESS = copy file: " ..new_file)
			os.execute( "cp " .. tostring(file_to_copy) .. " " .. new_file .."")
			replace_resultCode(new_file, resulCode)
		end

	else
		print("ERROR = file "..new_file.." does not exist!")
	end

return script