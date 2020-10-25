-- snippet plugin version number
VERSION = "0.2.0"

-- debug module
require "debug"

-- micro editor imports
local micro = import("micro")
local buffer = import("micro/buffer")
local config = import("micro/config")
local util = import("micro/util")

-- Snippet Table Layout
-- Snippets Table
--      --> Snippet Table
--                --> Location Table
local snippets = {}
local Snippet = {}
Snippet.__index = Snippet
local Location = {}
Location.__index = Location

-- variables for this plugin
local curFileType = ""
local RTSnippets = config.NewRTFiletype()
local currentSnippet = nil

-- ------- Location Class --------------------------------------------------------------

-- Location.new creates a new location
-- @param index integer pass in the index
-- @param placeholder pass in the place holder
-- @param snippet pass in the snippet table
-- @return Location metatable
function Location.new(index, ph, snippet)
    debug1("Location.new(index, ph, snip) index = ", index)
    -- debugt("Location.new(index, ph, snip) ph = ", ph)
    -- debugt("Location.new(index, ph, snippet) snippet = ", snippet)

    --@table Location
    -- @field index is the index
    -- @field ph is the place holder in the snippet code
    -- @field snippet table
    local self = setmetatable({}, Location)
    self.index = index
    self.ph = ph
    self.snippet = snippet
    return self
end

-- offset of the location relative to the snippet start
function Location.offset(self)
    debug("Location.offset(self)")
    local add = 0
    for i = 1, #self.snippet.locations do
        local loc = self.snippet.locations[i]
        debug1("loc = ", loc)
        if loc == self then break end

        local val = loc.ph.value
        debug1("Location.offset -> Val = ", val)
        if val then add = add + val:len() end
    end
    return self.index + add
end

-- Location.startPos gets the start position
function Location.startPos(self)
    -- debugt("Location.startPos(self) = ",self)
    local loc = self.snippet.startPos
    return loc:Move(self:offset(), self.snippet.view.buf)
end

-- returns the length of the location (but at least 1)
function Location.len(self)
    debug("Location.len(self)")
    local len = 0
    if self.ph.value then len = self.ph.value:len() end
    if len <= 0 then len = 1 end
    return len
end

function Location.endPos(self)
    debug("Location.endPos(self)")
    local start = self:startPos()
    return start:Move(self:len(), self.snippet.view.buf)
end

-- check if the given loc is within the location
function Location.isWithin(self, loc)
    debug("Location.isWithin(self, loc)")
    return loc:GreaterEqual(self:startPos()) and loc:LessEqual(self:endPos())
end

-- Location.focus
-- @param self Location table
function Location.focus(self)
    debug("Location.focus(self)")
    local view = self.snippet.view
    local startP = self:startPos():Move(-1, view.Buf)
    local endP = self:endPos():Move(-1, view.Buf)
    debug1("Location.focus -> startP = ",startP)
    debug1("Location.focus -> endP = ",endP)

    if view.Cursor:LessThan(startP) then
        while view.Cursor:LessThan(startP) do view.Cursor:Right() end
    elseif view.Cursor:GreaterEqual(endP) then
        while view.Cursor:GreaterEqual(endP) do view.Cursor:Left() end
    end

    if self.ph.value:len() > 0 then
        view.Cursor:SetSelectionStart(startP)
        view.Cursor:SetSelectionEnd(endP)
    else
        view.Cursor:ResetSelection()
    end
end

function Location.handleInput(self, ev)
    debug("Location.handleInput(self, ev)")
    if ev.EventType == 1 then
        -- TextInput
        if util.String(ev.Deltas[1].Text) == "\n" then
            Accept()
            return false
        else
            local offset = 1
            local sp = self:startPos()
            while sp:LessEqual(-ev.Deltas[1].Start) do
                sp = sp:Move(1, self.snippet.view.Buf)
                offset = offset + 1
            end

            self.snippet:remove()
            local v = self.ph.value
            if v == nil then v = "" end

            self.ph.value = v:sub(0, offset - 1) ..
                                util.String(ev.Deltas[1].Text) .. v:sub(offset)
            self.snippet:insert()
            return true
        end
    elseif ev.EventType == -1 then
        -- TextRemove
        local offset = 1
        local sp = self:startPos()
        while sp:LessEqual(-ev.Deltas[1].Start) do
            sp = sp:Move(1, self.snippet.view.Buf)
            offset = offset + 1
        end

        if ev.Deltas[1].Start.Y ~= ev.Deltas[1].End.Y then return false end

        self.snippet:remove()

        local v = self.ph.value
        if v == nil then v = "" end

        local len = ev.Deltas[1].End.X - ev.Deltas[1].Start.X

        self.ph.value = v:sub(0, offset - 1) .. v:sub(offset + len)
        self.snippet:insert()
        return true
    end

    return false
end

-- -------- Snippet Class --------------------------------------------------------------

-- Snippet.__tostring returns table in a string format
-- @param self Snippet table
-- @return string of the snippet table or "" if no table data
function Snippet.__tostring(self)
    debug(">> Snippet.__tostring")
    -- TODO finsih off table output as a string
    local snippetString = ""
    if self.code ~= nil then
        snippetString = "\nSnippet table \n" .. "self.code = " .. self.code
    end
    debug("<< Snippet.__tostring")
    return snippetString
end

-- Snippet.new creates a new blank snippet table
-- @return Snippet metattable
function Snippet.new()
    debug(">> Snippet.new()")
    local self = setmetatable({}, Snippet)
    self.code = ""
    debug("<< Snippet.new()")
    return self
end

-- Snippet.AddCodeLine adds lines of code to the snippet table
-- @param self
-- @param line
function Snippet.AddCodeLine(self, line)
    -- debugt("Snippet.AddCodeLine(self,line) self = " , self)
    debug1(">> Snippet.AddCodeLine(self, line) line = ", line)
    if self.code ~= "" then self.code = self.code .. "\n" end
    self.code = self.code .. line
    debug("<< Snippet.AddCodeLine")
end

-- Snippet.Prepare is used for adding placeholders and locations if needed
function Snippet.Prepare(self)
    debug(">> Snippet.Prepare(self)")
    if not self.placeholders then
        self.placeholders = {}
        self.locations = {}
        local count = 0
        local pattern = "${(%d+):?([^}]*)}"
        while true do
            local num, value = self.code:match(pattern)
            if not num then break end
            count = count + 1
            num = tonumber(num)
            local index = self.code:find(pattern)
            self.code = self.code:gsub(pattern, "", 1)
            debug1("Snippet.Prepare -> index = ", index)
            debug1("Snippet.Prepare -> snippet.code = ",self.code)

            local placeHolders = self.placeholders[num]
            if not placeHolders then
                placeHolders = {num = num}
                self.placeholders[#self.placeholders + 1] = placeHolders
            end
            self.locations[#self.locations + 1] =
                Location.new(index, placeHolders, self)
            debug1("location total = ", #self.locations)
            if value then placeHolders.value = value end
        end
    end
    debug("<< Snippet.Prepare")
end

-- Snippet.clone
function Snippet.clone(self)
    debug(">> Snippet.clone(self)")
    local result = Snippet.new()
    result:AddCodeLine(self.code)
    result:Prepare()
    debug("<< Snippet.clone")
    return result
end

-- Snippet.str returns a snippet string with location markers removed
-- @param self snippet table
-- @return string snippet string with locations markers removed
function Snippet.str(self)
    debug(">> Snippet.str(self)")
    local res = self.code
    for i = #self.locations, 1, -1 do
        local loc = self.locations[i]
        res = res:sub(0, loc.index - 1) .. loc.ph.value .. res:sub(loc.index)
    end
    debug("<< Snippet.str")
    return res
end

-- Snippet.findLocation
-- @param self
-- @param loc
-- @return location table or nil
function Snippet.findLocation(self, loc)
    debug1(">> Snippet.findLocation(self, loc) loc = ", loc)
    for i = 1, #self.locations do
        if self.locations[i]:isWithin(loc) then
            debug("<< Snippet.findLocation")
            return self.locations[i]
         end
    end
    debug("<< Snippet.findLocation")
    return nil
end

-- Snippet.remove from micro editor buffer
-- @param self Snippet table
function Snippet.remove(self)
    debug(">> Snippet.remove(self)")
    local endPos = self.startPos:Move(self:str():len(), self.view.Buf)
    self.modText = true
    self.view.Cursor:SetSelectionStart(self.startPos)
    self.view.Cursor:SetSelectionEnd(endPos)
    self.view.Cursor:DeleteSelection()
    self.view.Cursor:ResetSelection()
    self.modText = false
    debug("<< Snippet.remove")
end

-- Snippet.insert will insert the code snippet into micro editor buffer
-- @param self Snippet table
function Snippet.insert(self)
    debug(">> Snippet.insert(self)")
    self.modText = true
    self.view.Buf:insert(self.startPos, self:str())
    self.modText = false
    debug1("<< Snippets.insert -> snippet Table = ",tostring(self))
end

-- Snippet.focusNext
-- @param self Snippet table
function Snippet.focusNext(self)
    debug("Snippet.focusNext(self)")
    if self.focused == nil then
        self.focused = 0
    else
        self.focused = (self.focused + 1) % #self.placeholders
    end

    local ph = self.placeholders[self.focused + 1]

    for i = 1, #self.locations do
        if self.locations[i].ph == ph then
            self.locations[i]:focus()
            return
        end
    end
end

-- -------- Utils -----------------------------------------------------------------------

-- CursorWord checks the micro editor buffer word from the left of the cursor
-- and returns the word if there is one.
-- @param bp buffer pane passed from micro editor
-- @return result string of the word fromthe buffer or "" if no word found
local function CursorWord(bp)
    debug1(">> CursorWord(bp)", bp)
    local c = bp.Cursor
    local x = c.X - 1 -- start one rune before the cursor
    local result = ""
    while x >= 0 do
        local r = util.RuneStr(c:RuneUnder(x))
        if (r == " " or r == "\t") then -- IsWordChar(r) then
            break
        else
            result = r .. result
        end
        x = x - 1
    end
    debug("<< CursorWord(bp)")
    return result
end

-- LoadSnippets reads the snippets from the correct
-- filetype if any snippets are avaible
-- @param filetype string filetype to search for snippets eg rust will
-- look for rust snippets
-- @return snippets table
local function LoadSnippets(filetype)
    debug1(">> LoadSnippets(filetype)", filetype)
    local snippets = {}
    local allSnippetFiles = config.ListRuntimeFiles(RTSnippets)
    local exists = false
    -- check snippet files for the correct filetype
    for i = 1, #allSnippetFiles do
        if allSnippetFiles[i] == filetype then
            exists = true
            break
        end
    end

    if not exists then
        micro.InfoBar():Error("No snippets file for \"" .. filetype .. "\"")
        debug("<< LoadSnippets(filetype)")
        return snippets
    end

    local snippetFile = config.ReadRuntimeFile(RTSnippets, filetype)

    local curSnip = nil
    local lineNo = 0
    for line in string.gmatch(snippetFile, "(.-)\r?\n") do
        lineNo = lineNo + 1
        if string.match(line, "^#") then
            -- comment
        elseif line:match("^snippet") then
            curSnip = Snippet.new()
            for snipName in line:gmatch("%s(.+)") do -- %s space  .+ one or more non-empty sequence 
                snippets[snipName] = curSnip
            end
        else
            local codeLine = line:match("^\t(.*)$")
            if codeLine ~= nil then
                curSnip:AddCodeLine(codeLine)
            elseif line ~= "" then
                micro.InfoBar():Error("Invalid snippets file (Line #" ..
                                          tostring(lineNo) .. ")")
            end
        end
    end
    debugt("<< LoadSnippets(filetype) snippets = ", snippets)
    return snippets
end

-- EnsureSnippets checks the filetype from micro editor buffer and
-- then try to load snippets for that file type
-- @param bp buffer pane from micro editor
-- @return true = snippets loaded for the filetype
--        false = no snippets loaded
local function EnsureSnippets(bp)
    debug("<< EnsureSnippets()")
    local filetype = bp.Buf.Settings["filetype"]
    if curFileType ~= filetype then
        snippets = LoadSnippets(filetype)
        curFileType = filetype
    end
    if next(snippets) == nil then return false end
    debug(">> EnsureSnippets()")
    return true
end

-- Insert snippet if found.
-- @param bp micro editor buffer pane
-- @param args snippet name passed in by command mode or
-- if No name is passed in then it will check the text left of the cursor
-- @param prompt
function Insert(bp, args, prompt)
    debug(">> Insert(bp, args, prompt)")
    local snippetName = nil
    if args ~= nil and #args > 0 then snippetName = args[1] end
    debug1("snippetName passed in = ", snippetName)

    local c = bp.Cursor
    local buf = bp.Buf
    local xy = buffer.Loc(c.X, c.Y)
    -- check if a snippet name was passed in
    local noArg = false
    if not snippetName then
        snippetName = CursorWord(bp)
        debug1("snippetName from cursor position = ",snippetName)
        noArg = true
    end
    -- check filetype and load snippets
    local result = EnsureSnippets(bp)
    -- if no snippets return early
    if (result == false) then return end

    -- curSn cloned into currentSnippet if snippet found
    local curSn = snippets[snippetName]
    if curSn then
        currentSnippet = curSn:clone()
        currentSnippet.view = bp
        -- remove snippet keyword from micro buffer before inserting snippet
        if noArg then
            currentSnippet.startPos = xy:Move(-snippetName:len(), buf)

            currentSnippet.modText = true

            c:SetSelectionStart(currentSnippet.startPos)
            c:SetSelectionEnd(xy)
            c:DeleteSelection()
            c:ResetSelection()

            currentSnippet.modText = false
        else
            -- no need to remove snippet keyword from buffer as run from command mode
            currentSnippet.startPos = xy
        end
        -- insert snippet to micro buffer
        currentSnippet:insert()
        micro.InfoBar():Message("Snippet Inserted \"" .. snippetName .. "\"")

        -- Placeholders
        if #currentSnippet.placeholders == 0 then
            local pos = currentSnippet.startPos:Move(currentSnippet:str():len(),
                                                     bp.Buf)
            while bp.Cursor:LessThan(pos) do bp.Cursor:Right() end
            while bp.Cursor:GreaterThan(pos) do bp.Cursor:Left() end
        else
            currentSnippet:focusNext()
        end
    else
        -- Snippet not found
        micro.InfoBar():Message("Unknown snippet \"" .. snippetName .. "\"")
    end
    debug("<< Insert()")
end

-- Next snippet place holder
function Next()
    debug(">> Next()")
    if currentSnippet then currentSnippet:focusNext() end
    debug("<< Next()")
end

-- Accept snippet and stop place holder jumping
function Accept()
    debug(">> Accept()")
    currentSnippet = nil
    debug("<< Accept()")
end

-- Cancel the snippet and remove from the buffer
function Cancel()
    debug(">> Cancel()")
    if currentSnippet then
        currentSnippet:remove()
        Accept()
    end
    debug("<< Cancel()")
end

-- StartsWith
-- @param String
-- @param Start
local function StartsWith(String, Start)
    debug(">> StartWith(String, Start)")
    debug1("StartsWith(String,Start) String ", String)
    debug1("StartsWith(String,Start) start ", Start)
    String = String:upper()
    Start = Start:upper()
    debug("<< StartWith(String, Start)")
    return string.sub(String, 1, string.len(Start)) == Start
end

-- Used for auto complete in the command prompt
-- @param input
function findSnippet(input)
    debug1(">> findSnippet(input)", input)
    local result = {}
    -- TODO: pass bp
    EnsureSnippets()

    for name, v in pairs(snippets) do
        if StartsWith(name, input) then table.insert(result, name) end
    end
    debug("<< findSnippet(input)")
    return result
end

-- -------- Micro editor callbacks ----------------------------------------------------

-- callback from micro editor when the tab key is pressed before micro editor has dealt with the autocomplete
-- @param bp buffer pane from micro editor
-- @return tells micro editor false = plugin handling autocomplete no action needed from micro editor
--                            true = plugin not handling autocomplete so micro editor needs to handle it
function preAutocomplete(bp)
    debug(">> preAutocomplete called from micro editor")
--    micro.InfoBar():YNPrompt("Insert snippet Y/N ", function(boolResult)
--        if (boolResult == true) then
--            debug1("preAutocomplete ","result = Yes")
--        else
--            debug1("preAutocomplete ","result = No")
--        end
--    end)
    debug("<< preAutocomlete called from micro edior")
    return true -- false = plugin handled autocomplete : true = plugin not handled autocomplete
end

-- callback from micro editor when the tab key is pressed and micro editor has dealt with before calling this function
-- @param bp buffer pane from micro editor
-- @return boolean tells micro editor false = plugin hadling autocomplete no action needed from micro editor
--                                     true = plugin not handled autocomplete
function onAutocomplete(bp)
    debug(">> onAutocomplete called from micro editor")
    debug("<< onAutocomplete called from micro editor")
    return true
end

-- callback from micro editor when a key is pressed
-- @param sb shared buffer from micro editor
-- @param ev event from micro editor
-- @return boolean tells micro editor false =
--                                     true =
function onBeforeTextEvent(sb, ev)
    -- debug1(">> onBeforeTextEvent(ev)", ev)
    if currentSnippet ~= nil and currentSnippet.view.Buf.SharedBuffer == sb then
        if currentSnippet.modText then
            -- text event from the snippet. simply ignore it...
            return true
        end

        local locStart = nil
        local locEnd = nil

        if ev.Deltas[1].Start ~= nil and currentSnippet ~= nil then
            locStart = currentSnippet:findLocation(
                           ev.Deltas[1].Start:Move(1, currentSnippet.view.Buf))
            locEnd = currentSnippet:findLocation(ev.Deltas[1].End)
        end
        if locStart ~= nil and
            ((locStart == locEnd) or
                (ev.Deltas[1].End.Y == 0 and ev.Deltas[1].End.X == 0)) then
            if locStart:handleInput(ev) then
                currentSnippet.view.Cursor:Goto(-ev.C)
                return false
            end
        end
        Accept()
        -- debug("<< onBeforeTextEvent(sb, ev)")
    end

    return true

end

-- micro editor calls this function when the plugin is first loaded
function init()
    -- Insert a snippet
    config.MakeCommand("snippetinsert", Insert, config.NoComplete) -- TODO autocomplete like version 1
    -- Mark next placeholder
    config.MakeCommand("snippetnext", Next, config.NoComplete)
    -- Cancel current snippet (removes the text)
    config.MakeCommand("snippetcancel", Cancel, config.NoComplete)
    -- Acceptes snipped editing
    config.MakeCommand("snippetaccept", Accept, config.NoComplete)
    --
    config.AddRuntimeFile("snippets", config.RTHelp, "help/snippets.md")
    config.AddRuntimeFilesFromDirectory("snippets", RTSnippets, "snippets","*.snippets")
    config.AddRuntimeFile("snippets", config.RTSyntax, "snippets.yaml")
    -- Adds key bindings to micro editor
    config.TryBindKey("Alt-w", "lua:snippets.Next", false)
    config.TryBindKey("Alt-a", "lua:snippets.Accept", false)
    config.TryBindKey("Alt-s", "lua:snippets.Insert", false)
    config.TryBindKey("Alt-d", "lua:snippets.Cancel", false)
end
