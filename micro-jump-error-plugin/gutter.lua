local shell = import("micro/shell")
local buffer = import("micro/buffer")
local config = import("micro/config")
local util = import("micro/util")
local micro = import("micro")

-- Micro editor calls this when the plugin is first loaded
function init()
    -- commands
    config.MakeCommand("gutterInfo", debugInfo, config.NoComplete)
    config.MakeCommand("gutterUp", up, config.NoComplete)
    config.MakeCommand("gutterDown", down, config.NoComplete)
    config.MakeCommand("gutterStart", start, config.NoComplete)
    config.MakeCommand("gutterProblems", problemsWindow, config.NoComplete)
    -- help file
    config.AddRuntimeFile("gutter-plugin", config.RTHelp,
                          "help/gutter-plugin.md")
    -- key bindings 
    config.TryBindKey("Alt-w", "lua:gutter.up", false)
    config.TryBindKey("Alt-s", "lua:gutter.down", false)
    config.TryBindKey("Alt-d", "lua:gutter.debugInfo", false)
    config.TryBindKey("Alt-a", "lua:gutter.start", false)
end

-- Jump to the first error
function start(bufpane)
    local msg = bufpane.Buf.Messages
    -- local cursorx = cursor.Loc.X  -- used for when there is more than 1 error message per line
    local jump = false
    local jumpx = 0
    local jumpy = 0

    if msg ~= nil then
        -- loop through the gutter error messages
        for count = 1, #msg do
            -- local x = msg[count].Start.X  -- get the message start x location (across) used for when there is more than 1 error message per line
            local y = msg[count].Start.Y -- get the message start y location

            if jump == true then if y < jumpy then jumpy = y end end

            if jump == false then
                jumpy = y
                jump = true
            end

        end
    end
    -- jump and update cursor location
    if jump == true then
        local loc = buffer.Loc(jumpx, jumpy)
        local cursor = bufpane.buf:GetActiveCursor()
        cursor:GotoLoc(loc)
        bufpane:Relocate()
    end
end

-- Jump up to the previous error
function up(bufpane)
    local msg = bufpane.Buf.Messages
    local cursor = bufpane.buf:GetActiveCursor()
    -- local cursorx = cursor.Loc.X  -- used for when there is more than 1 error message per line
    local cursory = cursor.Loc.Y
    local jump = false
    local jumpx = 0
    local jumpy = 0

    if msg ~= nil then
        for count = 1, #msg do
            -- local x = msg[count].Start.X  -- get the message start x location (across) used for when there is more than 1 error message per line
            local y = msg[count].Start.Y -- get the message start y location 
            -- Check that the message location is less than the current cursor position
            if y < cursory then
                if jump == true then
                    if y > jumpy then jumpy = y end
                end

                if jump == false then
                    jumpy = y
                    jump = true
                end

            end
        end
    end

    if jump == true then
        local loc = buffer.Loc(jumpx, jumpy)
        cursor:GotoLoc(loc)
        bufpane:Relocate()
    end
end

-- Jump to the next error
function down(bufpane)
    local msg = bufpane.Buf.Messages
    local cursor = bufpane.buf:GetActiveCursor()
    -- local cursorx = cursor.Loc.X  -- used for when there is more than 1 error message per line
    local cursory = cursor.Loc.Y
    local jump = false
    local jumpx = 0
    local jumpy = 0

    if msg ~= nil then
        for count = 1, #msg do
            -- local x = msg[count].Start.X  -- get the message start x location (across) used for when there is more than 1 error message per line
            local y = msg[count].Start.Y -- get the message start y location
            -- Check that the message location is greater than the current cursor position
            if y > cursory then
                if jump == true then
                    if y < jumpy then jumpy = y end
                end

                if jump == false then
                    jumpy = y
                    jump = true
                end

            end
        end
    end

    if jump == true then
        local loc = buffer.Loc(jumpx, jumpy)
        cursor:GotoLoc(loc)
        bufpane:Relocate()
    end
end

-- degbugInfo prints out in the buffer log the error messages contents
-- Message struct layout from micro editor
--	Msg string  -- The message itself
--	Start, End Loc -- Start and End locations for the message
--	Kind MsgType int -- The kind stores the message type Info = 0 Warning = 1 Error = 2
--	Owner string -- the owner of the message
function debugInfo(bufpane)
    -- local bufpane = micro.CurPane() -- used if bufpane not passed into the function
    local msg = bufpane.Buf.Messages
    local cursor = bufpane.buf:GetActiveCursor()
    if msg ~= nil then
        for count = 1, #msg do
            local loc = buffer.Loc(msg[count].Start.X, msg[count].Start.Y)
            cursor:GotoLoc(loc)
            buffer.Log("-----------------Gutter Error Message ---------------\n")
            buffer.Log("Owner      -> " .. msg[count].Owner .. "\n") -- string
            buffer.Log("Message    -> " .. msg[count].Msg .. "\n") -- string
            buffer.Log("Start Down -> " .. msg[count].Start.Y + 1 ..
                           "  Start Across -> " .. msg[count].Start.X + 1 ..
                           "\n") -- start y add +1 so it matches cursor displayed on the editor status line
            buffer.Log("End Down   -> " .. msg[count].End.Y + 1 ..
                           "  End Across   -> " .. msg[count].End.X + 1 .. "\n") -- end y add +1 so it matches cursor displayed on the editor status line
            buffer.Log("Kind Type  -> " .. msg[count].Kind .. "\n") -- 	Info = 0 Warning = 1 Error = 2

        end
    end

end

function problemsWindow(bufpane)
    micro.CurPane():HSplitIndex(buffer.NewBuffer("", "Problems"), true)
    -- Save the new bufpane so we can access it later
    problems_BufPane = micro.CurPane()

    -- Set the width of problems_BufPane to 30%
    problems_BufPane:ResizePane(30)
    -- Set the type to an unsavable, read-only buffer
    problems_BufPane.Buf.Type.Kind = buffer.BTScratch
    -- For some reason, you still need these even with a scratch type...
    problems_BufPane.Buf.Type.Readonly = true
    problems_BufPane.Buf.Type.Scratch = true

    -- Set the various display settings, but only on our bufpane by using SetOption on the treevew buffer
    -- NOTE: Micro requires the true/false to be a string
    -- Softwrap long strings (the file/dir paths)
    problems_BufPane.Buf:SetOption("softwrap", "true")
    -- No line numbering
    problems_BufPane.Buf:SetOption("ruler", "false")
    -- Is this needed with new non-savable settings from being "vtLog"?
    problems_BufPane.Buf:SetOption("autosave", "false")
    -- Don't show the statusline to differentiate the view from normal views
    problems_BufPane.Buf:SetOption("statusline", "false")
    
end
