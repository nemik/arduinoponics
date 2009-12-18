module("luci.controller.sensorsapp.sensors", package.seeall)

function index()
	entry({"sensors"}, call("action_index"), "Sensors", 20).dependent=false
	entry({"sensors","ajax","get_light"}, call("ajax_light")).dependent=false
	entry({"sensors","ajax","get_analogs"}, call("ajax_analogs")).dependent=false
	entry({"sensors","ajax","pin"}, call("ajax_pin")).dependent=false
	entry({"sensors","ajax","toggle_lights"}, call("ajax_toggle_lights")).dependent=false
end

function get_analogs_x()
	out = {}
	o = ""
	for i = 0,5 do
		file_name = "/tmp/sensors/"..i
		light_file=io.open(file_name,"r")
		--out.insert(i, light_file:read())
		o = o .. light_file:read()
		if i < 5 then
			o = o .. "|"
		end
		light_file:close()
	end
	return o
end

function get_analog_pin(pin)
	fname = "/tmp/sensors/"..pin
	file=io.open(fname,"r")
	value = file:read()
	file:close()
	return value
end

function get_analogs()
	file=io.open("/tmp/sensors/analogs","r")
	analogs = file:read()
	file:close()
	return analogs
end

function get_light()
	light_file=io.open("/tmp/sensors/light","r")
	light = light_file:read() 
	light_file:close()
	return light
end

function ajax_pin()
	pin = luci.http.formvalue("pin", false)
	luci.http.prepare_content("text/plain")
	luci.http.write(get_analog_pin(pin))
end

function ajax_analogs()
	luci.http.prepare_content("text/plain")
	--luci.http.write(get_analogs_x())
	luci.http.write(get_analogs())
end

function ajax_toggle_lights()
        f = io.open("/tmp/sensors/light","w+")
        f:write('1')
        f:close()
	luci.http.prepare_content("text/plain")
	luci.http.write("toggled!")
end

function ajax_light()
	luci.http.prepare_content("text/plain")
	luci.http.write(get_light())
end

function action_index()
	local current_light = get_analog_pin(0)
	local current_temp = get_analog_pin(1)
	luci.template.render("sensorsapp/index", {current_light=current_light, current_temp = current_temp})
end
