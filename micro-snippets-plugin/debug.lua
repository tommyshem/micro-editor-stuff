-- micro editor imports
local micro = import("micro")
local buffer = import("micro/buffer")
local config = import("micro/config")
local util = import("micro/util")

-- debugflag boolean true = debug printing on
--                 false = debug is turned off
local debugflag = true
local pluginName = "snippets-plugin"
-- Debug functions below
-- debug1 is for logging functionName and 1 argument passed
-- @param functionName string pass in function name
-- @param argument any varaiable needs debuging
function debug1(functionName, argument)
    if debugflag == false then return end
    if argument == nil then
        micro.Log(pluginName .. " -> function " .. functionName .. " = nil")
    elseif argument == "" then
        micro.Log(pluginName .. " -> function " .. functionName ..
                      " = empty string")
    else
        micro.Log(pluginName .. " -> function " .. functionName .. " = " ..
                      tostring(argument))
    end
end

-- debug is for logging functionName only
-- @param functionName string pass in function name
function debug(functionName)
    if debugflag == false then return end
    micro.Log(pluginName .. " -> function " .. functionName)
end



-- dump table
function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

-- used by debugt function
-- @param tbl pass in a table
-- @param indent integer spacing for the output
function tprint(tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        local formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            micro.Log(formatting .. "Table ->")
            tprint(v, indent + 1)
        elseif type(v) == nil then
            micro.Log(formatting .. " nil")
        else
            micro.Log(formatting .. tostring(v))
        end
    end
end

-- debug is for logging functionName and table
-- @param functionName string pass in function name
-- @param tablepassed table which needs debuging
function debugt(functionName, tablepassed)
    if debugflag == false then return end
    micro.Log(pluginName .. " -> function " .. functionName)
    tprint(tablepassed)
    --	if (tablepassed == nil) then return end
    --	for key,value in pairs(tablepassed) do 
    --		micro.Log("key - " .. tostring(key) .. "value = " .. tostring(value[1]) )
    --	end
end

-- checkTableisEmpty checks table passed in is empty
-- @param mytable table pass in any table to check is empty
-- @return boolean true = table is empty
--                false = table is not empty
function checkTableisEmpty(myTable)
    if next(myTable) == nil then
        -- myTable is empty
        return true
    else
        return false
    end
end

-- tableprint
-- @param tbl table pass in a simple index table to debug
function tablePrint(tbl)
    for index = 1, #tbl do
        micro.Log(tostring(index) .. " = " .. tostring(tbl[index]))
    end
end
