local json = require("json")

-- KeyValue Database
local kv_storage = {

	set_storage = function(self, storage)
		self.s = storage
		self.index = storage.index.kv_index
	end,

	insert = function(self, key, value)
		if (#(self.index:select(key)) ~= 0)
			return false
		end
		self.s:insert{nil, key, value}
		return true
	end,

	get_value = function(self, key, value)
		return self.index:select(key)[1]["value"]
	end,

	delete = function(self, key)
		if (not #(self.index:select(key)) ~= 0)
			return false
		end
		self.s:delete(self.index:select(key)[1]["id"])
		return true
	end,

	update = function(self, key, value)
		if (not #(self.index:select(key)) ~= 0)
			return false
		end
		self.s:update(self.index:select(key)[1]["id"], {{'=', 3, value}})
		return true
	end
}

kv_storage.__index = kv_storage
kv_storage:set_storage(box.space.storage)

local function delete_excess(str)
	if (str == nil) then
		return nil
	end
	local start, finish = string.find(str, "/[^/]*$")
	return string.sub(str, start + 1, finish)
end

local methods_library = {
	post = function(req)
		-- take the body from request
		local body = req:json()
		-- check body
		if (body.key == nil or body.value == nil) then
			return {status = 400}
		end
		-- insert body
		if (kv_storage:insert(body.key, json.encode(body.value))) then
			return {status = 200}
		else
			return {status = 409}
		end
	end,

	put = function(req)
		local key = delete_excess(req.path)
		-- take the body from request
		local body = req:json()
		-- check body
		if (body.value == nil or #key == 0) then
			return {status = 400}
		end
		-- update body
		if (kv_storage:update(key, json.encode(body.value))) then
			return {status = 200}
		else
			return {status = 404}
		end

	end,

	delete = function(req)
		key = delete_excess(req.path)
		-- check empty
		if (#key == 0) then
			return {status = 400}
		end
		-- delete
		if (kv_storage:delete(key)) then
			return {status = 200}
		else
			return {status = 404}
		end
	end,

	get = function(req)
		key = delete_excess(req.path)
		-- check empty
		if (#key == 0) then
			return {status = 400}
		end
		-- if not empty then get
		if (#(self.index:select(key)) ~= 0) then
			return {status = 200, body = kv_storage:get_value(key)}
		else
			return {status  = 404}
		end
	end
}

-- Creating a server
-- server = require('http.server').new(host, port[, { options } ])
local server = require("http.server").new("0.0.0.0", 8888, { log_requests = true })

-- from tarantool web-site
box.cfg({listen = 3301})
box.once("setup", function()
	s = box.schema.space.create("storage")
	box.schema.sequence.create("AutoIncr")
	s:format({{name = "id", type = "unsigned"}, {name = "key", type = "string"}, {name = "value", type = "string"}})
	s:create_index("primary", {
		sequence = "AutoIncr",
		type = "hash",
		parts = {"id"}
	})
	s:create_index("kv_index", {
		type = "hash",
		parts = {"key"}
	})
	end
)

server:route({path = "/kv", method = "POST"}, methods_library.post)
server:route({path = "/kv/.*", method = "PUT"}, methods_library.put)
server:route({path = "/kv/.*", method = "DELETE"}, methods_library.delete)
server:route({path = "/kv/.*", method = "GET"}, methods_library.get)
server:start()
