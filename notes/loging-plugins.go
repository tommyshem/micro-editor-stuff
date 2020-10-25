// RunPluginFn runs a given function in all plugins
// returns an error if any of the plugins had an error
func RunPluginFn(fn string, args ...lua.LValue) error {
	log.Println("[PluginCB Callback Name] >> ", fn)
	var reterr error
	for _, p := range Plugins {
		if !p.IsEnabled() {
			continue
		}
		_, err := p.Call(fn, args...)
		if err != nil && err != ErrNoSuchFunction {
			reterr = errors.New("Plugin " + p.Name + ": " + err.Error())
		}
	}
	return reterr
}

// RunPluginFnBool runs a function in all plugins and returns
// false if any one of them returned false
// also returns an error if any of the plugins had an error
func RunPluginFnBool(fn string, args ...lua.LValue) (bool, error) {
	log.Println("[PluginCB Callback Name] >> ", fn)
	var reterr error
	retbool := true
	for _, p := range Plugins {
		if !p.IsEnabled() {
			continue
		}
		val, err := p.Call(fn, args...)
		if err == ErrNoSuchFunction {
			continue
		}
		if err != nil {
			reterr = errors.New("Plugin " + p.Name + ": " + err.Error())
			continue
		}
		if v, ok := val.(lua.LBool); ok {
			retbool = retbool && bool(v)
		}
	}
	return retbool, reterr
}
