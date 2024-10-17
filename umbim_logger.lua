

-- Configuration
local command_arguments = {"caps", "home", "registration", "subscriber", "attach", "config", "radio"}
local umbim_command = "umbim -t 6 -n -d /dev/cdc-wdm0"
local log_file = "mbim_data_" .. os.date("%Y-%m-%d") .. ".log"
local separator = "|"

-- Function to extract key from a line
local function extract_key(line)
  for key in string.gmatch(line, "(%w+):") do
    return key
  end
  return nil
end

-- Function to extract value from a line
local function extract_value(line)
  local _, _, value = string.find(line, ":(.*)")
  return value and string.match(value, "%S.*") or nil
end

-- Function to get the previous value from the log file
local function get_previous_value(key, argument)
  local cmd = "grep '" .. argument .. "|" .. key .. "' " .. log_file .. " | tail -n 1"
  local handle = io.popen(cmd)
  local output = handle:read("*a")
  handle:close()
  if output then
    local _, _, previous_value = string.find(output, separator .. "(.*)")
    return previous_value
  end
  return nil
end

-- Main loop
while true do
  for _, argument in ipairs(command_arguments) do
    local cmd = umbim_command .. " " .. argument
    local handle = io.popen(cmd)
    local output = handle:read("*a")
    handle:close()

    for line in string.gmatch(output, "[^\n]+") do
      local key = extract_key(line)
      if key then
        local new_value = extract_value(line)
        local previous_value = get_previous_value(key, argument)

        if not previous_value or new_value ~= previous_value then
          local timestamp = os.date("!%Y-%m-%dT%H:%M:%S%z")
          local log_entry = timestamp .. separator .. argument .. separator .. key .. separator .. new_value
          local file = io.open(log_file, "a")
          file:write(log_entry .. "\n")
          file:close()
        end
      end
    end
  end

  os.execute("sleep 60") -- Wait for 60 seconds
end
