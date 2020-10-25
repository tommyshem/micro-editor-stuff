VERSION = "0.2.0"
-- Imports
local micro = import("micro")
local buffer = import("micro/buffer")
local config = import("micro/config")
local util = import("micro/util")
local shell = import("micro/shell")
local runtime = import("runtime")

-- Micro Editor options for this rust plugin

config.RegisterCommonOption("rust-plugin", "onsave-fmt", true) -- Toggle format checking on/off 
config.RegisterCommonOption("rust-plugin", "rustfmt-backup", false) -- use rustfmt backup file option
config.RegisterCommonOption("rust-plugin", "linter-clippy", false) -- use clippy as linter on save
config.RegisterCommonOption("rust-plugin", "linter-cargo-check", false) -- use cargo check as linter on save
config.RegisterCommonOption("rust-plugin", "onsave-build", false) -- Toggle build on/off
config.RegisterCommonOption("rust-plugin", "tool-cargo-rustc", false) -- use cargo=true or rustc=false option to build

-- Micro editor calls this function on startup
function init()

    config.AddRuntimeFile("rust", config.RTHelp, "help/rust-plugin.md")

    -- Micro Editor binkeys for this plugin
    -- config.TryBindKey("F5", "RustInfo", false)

    -- Micro Editor commands added from this plugin
    config.MakeCommand("rustfmt", rustfmt, config.NoComplete)
    config.MakeCommand("cargofmt", cargofmt, config.NoComplete)
    config.MakeCommand("cargocheck", cargocheck, config.NoComplete)
    config.MakeCommand("cargoclippy", cargoclippy, config.NoComplete)
    config.MakeCommand("rustc", rustc, config.NoComplete)
    config.MakeCommand("rustInfo", RustInfo, config.NoComplete)

end

-- Micro editor Callback function when the file is saved
function onSave(bp)
    micro.Log("rust-plugin -> function onSave")
    -- check if the file ssved is a rust file
    if bp.Buf:FileType() == "rust" then
        -- check if to format the code
        if bp.Buf.Settings["rust-plugin.onsave-fmt"] then
            micro.Log("rust-plugin -> rust-plugin.onsave-fmt = true")
            if bp.Buf.Settings["rust-plugin.tool-cargo-rustc"] then
                -- true use cargo false use rust
                micro.Log("rust-plugin -> rust-plugin.tool-cargo-rustc = true")
                cargofmt(bp) -- lint project files
            else
                micro.Log("rust-plugin -> rust-plugin.tool-cargo-rustc = false")
                rustfmt(bp) -- lint file only
            end
        end

        -- check option if to use a linter
        if bp.Buf.Settings["rust-plugin.linter-clippy"] then
            micro.Log("rust-plugin -> rust-plugin.linter-clippy = true")
            cargoclippy(bp)
        end
        -- check option if to use cargo check as a linter
        if bp.Buf.Settings["rust-plugin.linter-cargo-check"] then
            micro.Log("rust-plugin -> rust-plugin.linter-cargo-check = true")
            cargocheck(bp)
        end

        -- check option if to build the code
        if bp.Buf.Settings["rust-plugin.onsave-build"] then
            micro.Log("rust-plugin -> rust-plugin.onsave-build = true")
            rustc() end
    end
end

-- cargocheck() is used for checking current project files in Micro editor
function cargocheck(bp)
    micro.Log("rust-plugin function cargocheck")
    bp:Save()
    local file = bp.Buf.Path
    local dir = basename(file)
    bp.Buf:ClearMessages("rust-plugin")
    shell.JobSpawn("cargo", -- command to run
                    {"check", "--message-format", "short"}, -- command args
                    nil,  -- callback function for stdout
                    out,  -- callback function for stderr
                    out,  -- callback function for command output
                    bp)  -- user args
    bp.Buf:ReOpen()
end

-- cargofmt() is used for formating current project in Micro editor
function cargofmt(bp)
    micro.Log("rust-plugin -> function cargofmt")
    if bp.Buf.Settings["rust-plugin.backup"] then
        micro.Log("rust-plugin -> shell command run cargo-fmt --backup")
        local results, error = shell.RunCommand("cargo-fmt -- --backup")
        bp.Buf:ReOpen()
    else
        micro.Log("rust-plugin -> shell command run cargo-fmt")
        local results, error = shell.RunCommand("cargo-fmt")
        bp.Buf:ReOpen()
    end
end

-- cargoclippy() is used for checking current file in Micro editor
-- clippy report is in the log e.g In Micro Editor ctrl e log
function cargoclippy(bp)
    micro.Log("rust-plugin -> function cargoclippy " .. bp.Buf.Path)
    shell.JobSpawn("cargo",  -- command to run
                    {"clippy", "--message-format", "short"},  -- command args
                    nil,  -- callback function for stdout
                    out,  -- callback function for stderr
                    out,  -- callback function for command output
                    bp)  -- user args
end

-- rustc() is used for checking and building current file in Micro editor
function rustc(bp)
    micro.Log("rust-plugin -> function rustc --error-format short" .. bp.Buf.Path)
    shell.JobSpawn("rustc", -- command
                    {"--error-format", "short", bp.Buf.Path}, -- command args
                     nil,  -- callback function for stdout
                     LogStderr, --  callback function for stderr
                     out,  -- callback function for command output
                     bp)  -- user args
end

-- rustfmt() is used for formating the current file
function rustfmt(bp)
    micro.Log("rust-plugin -> function rustfmt") -- debug function info
    if bp.Buf.Settings["rust-plugin.backup"] then
        micro.Log("rust-plugin -> rustfmt --backup " .. bp.Buf.Path) -- debug path info
        local results, error = shell.RunCommand(
                                   "rustfmt --backup " .. bp.Buf.Path)
        bp.Buf:ReOpen()
    else
        micro.Log("rust-plugin -> rustfmt " .. bp.Buf.Path) -- debug path info
        local results, error = shell.RunCommand(
                                   "rustfmt --backup " .. bp.Buf.Path)
        bp.Buf:ReOpen()
    end
end

-- RustInfo displays info to the log buffer (ctrl e log)
function RustInfo(bp)
    micro.InfoBar():Message(
        "To view the rust info, open the log page. [Ctl+e log]")
    buffer.Log("\nrust-plugin Optons Info\n")
    buffer.Log("=======================")
    LogOptionBuffer(bp, "onsave-fmt")
    LogOptionBuffer(bp, "rustfmt-backup")
    LogOptionBuffer(bp, "linter-clippy")
    LogOptionBuffer(bp, "linter-cargo-check")
    LogOptionBuffer(bp, "onsave-build")
    LogOptionBuffer(bp, "tool-cargo-rustc")
    buffer.Log("\n\nRust Tools")
    LogCommand("cargo")
    LogCommand("rustc")
    LogCommand("rustfmt")
    LogCommand("cargo clippy")
end

-- Display error in Log.txt if micro editor was passed --debug flag and display
-- the error in statusbar
function LogStderr(err)
    micro.Log("rust-plugin -> function LogStderr error message below")
    micro.Log(err)
    micro.Log("rust-plugin -> error message finished")
    micro.InfoBar():Message(err)
end

-- run commad in shell with debuging logging info
function LogRunShellCommand(runcommand)
    micro.Log("rust-plugin -> function LogRunShellCommand command = " ..
                  runcommand)
    local results, error = shell.RunCommand(runcommand)
    if results == nil then
        micro.Log("rust-plugin -> LogRunShellCommand results = nil")
    elseif results == "" then
        micro.Log("rust-plugin -> LogRunShellCommand results = empty string")
    else
        micro.Log("rust-plugin -> LogRunShellCommand results = " .. results)
    end
    if error ~= nil then
        micro.Log("rust-plugin -> LogRunShellCommand error = ")
        micro.Log(error)
        micro.InfoBar():Error(error)
    end
    return results
end

-- used in RustInfo function
function LogOptionBuffer(bp, option)
    if bp.Buf.Settings["rust-plugin." .. option] then
        buffer.Log("\nrust-plugin." .. option .. " = true")
    else
        buffer.Log("\nrust-plugin." .. option .. " = false")
    end
end

function LogCommand(command)
    local version, err = shell.RunCommand(command .. " --version")
    if err ~= nil then
        micro.InfoBar():Error(err)
        return
    end
    if version ~= nil then
        buffer.Log("\n" .. command .. " version: = " .. version)
    end
end

function out(output, args)
    local bp = args[1]
    micro.Log("rust-plugin -> function out")
    if output == nil then
        micro.Log("output = nil")
        return
    end
    micro.Log("Output = ", output)
    local lines = split(output, "\n")
    for _, line in ipairs(lines) do
        -- Trim whitespace
        line = line:match("^%s*(.+)%s*$")
        if string.find(line, "^.*.rs:.*") then --
            micro.Log("Line = " .. line)
            local file, linenumber, colnumber, message =
                string.match(line, "^(.-):(%d*):(%d):(.*)")
            if basename(bp.Buf.Path) == basename(file) then
                local msg = buffer.NewMessageAtLine("rust-plugin", -- linter text
                                                    message,  -- linter message
                                                    tonumber(linenumber),  -- line number
                                                    buffer.MTError)  -- type of error
                bp.Buf:AddMessage(msg)
            end
        end
    end
end

-- split string into lines
function split(str, sep)
    micro.Log("rust-plugin -> function splitn str = " .. str .. " sep = " .. sep)
    local result = {}
    local regex = ("([^%s]+)"):format(sep)
    for each in str:gmatch(regex) do table.insert(result, each) end
    return result
end

function basename(file)
    if file ~= nil then
        micro.Log("rust-plugin -> function basename file = " .. file)
        else
            micro.Log("rust-plugin -> function basename file = nil")
                return ""
    end
    local sep = "/"
    if runtime.GOOS == "windows" then sep = "\\" end
    local name = string.gsub(file, "(.*" .. sep .. ")(.*)", "%2")
    micro.Log(name)
    return name
end

-- Returns the basename of a path (aka a name without leading path)
local function get_basename(path)
    if path == nil then
        micro.Log("Bad path passed to get_basename")
        return nil
    else
        -- Get Go's path lib for a basename callback
        local golib_path = import("path")
        return golib_path.Base(path)
    end
end

