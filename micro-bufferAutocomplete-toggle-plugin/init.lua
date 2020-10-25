local config = import("micro/config")

-- callback from micro editor when the tab key is pressed before micro editor
config.RegisterCommonOption("bufferAuto", "completeON", false) -- Toggle buffer autocomplete checking on/off

function preAutocomplete(bp)
	if bp.Buf.Settings["bufferAuto.completeON"]  then
		return true
	else
		return false -- false = plugin handled autocomplete : true = plugin not handled autocomplete
end
end