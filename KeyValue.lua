-- local server = require("http.server").new(nil, 8080)

-- Creating a server
-- server = require('http.server').new(host, port[, { options } ])
local server = require("http.server").new("0.0.0.0", 8888, { log_requests = true })
local json = require("json")

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

-- KeyValue Database
local kv_storage = {

	set_storage = function(self, storage)
		self.s = storage
		self.index = storage.index.kv_index
	end,

	has_key = function(self, key)
		return #(self.index:select(key)) ~= 0
	end,

	insert = function(self, key, value)
		if (self:has_key(key)) then
			return false
		end
		self.s:insert{nil, key, value}
		return true
	end,

	get_value = function(self, key, value)
		return self.index:select(key)[1]["value"]
	end,

	delete = function(self, key)
		if (not self:has_key(key)) then
			return false
		end
		self.s:delete(self.index:select(key)[1]["id"])
		return true
	end,

	update = function(self, key, value)
		if (not self:has_key(key)) then
			return false
		end
		self.s:update(self.index:select(key)[1]["id"], {{'=', 3, value}})
		return true
	end
}





kv_storage.__index = kv_storage
kv_storage:set_storage(box.space.storage)


local function get_suff(str)
	if (str == nil) then
		return nil
	end
	local start, finish = string.find(str, "/[^/]*$")
	return string.sub(str, start + 1, finish)
end


local handler_collection = {
	post = function(req)
		local body = req:json()
		if (body.key == nil or body.value == nil) then
			return {status = 400}
		end
		if (kv_storage:insert(body.key, json.encode(body.value))) then
			return {status = 200}
		else
			return {status = 409}
		end
	end,

	put = function(req)
		local key = get_suff(req.path)
		local body = req:json()
		if (body.value == nil or #key == 0) then
			return {status = 400}
		end
		if (kv_storage:update(key, json.encode(body.value))) then
			return {status = 200}
		else
			return {status = 404}
		end

	end,

	delete = function(req)
		key = get_suff(req.path)
		if (#key == 0) then
			return {status = 400}
		end
		if (kv_storage:delete(key)) then
			return {status = 200}
		else
			return {status = 404}
		end
	end,

	get = function(req)
		key = get_suff(req.path)
		if (#key == 0) then
			return {status = 400}
		end
		if (kv_storage:has_key(key)) then
			return {status = 200, body = kv_storage:get_value(key)}
		else
			return {status  = 404}
		end
	end
}

server:route({path = "/kv", method = "POST"}, handler_collection.post)
server:route({path = "/kv/.*", method = "PUT"}, handler_collection.put)
server:route({path = "/kv/.*", method = "DELETE"}, handler_collection.delete)
server:route({path = "/kv/.*", method = "GET"}, handler_collection.get)
server:start()


-- #!/usr/bin/env tarantool

-- local http  = require("http.server")
-- local json  = require("json")
-- space_name = 'kv-test'

-- local function http_json(code, data)
--     return {
--             status = code,
--             headers = { ['content-type'] = 'application/json' },
--             body = json.encode(data)
--     }
-- end

-- local function add_pair(req)
--     local k = req:param('key')
--     local v = req:param('value')

--     if type(k) ~= 'string' or type(v) ~= 'table' then
--         return http_json(400, { message = 'Bad request body.' })
--     end

--     if box.space[space_name]:get{ k } ~= nil then
--         return http_json(409, { message = 'This key already exists.' })
--     end

--     box.space[space_name]:insert{ k, v }

--     return http_json(200, { key = k, value = v })
-- end

-- local function update_pair(req)
--     local id = req:stash('id')
--     local v = req:param('value')

--     if type(v) ~= 'table' then
--         return http_json(400, { message = 'Bad request body.' })
--     end

--     pair = box.space[space_name]:get{ id }

--     if pair ~= nil then
--         new_pair = box.space[space_name]:update(id, { { '=', 2, v } })

--         return http_json(200, { key = id, value = new_pair[2] })
--     else
--         return http_json(404, { message = 'Pair with this key doesn\'t exist.' })
--     end
-- end

-- local function get_pair(req)
--     local id = req:stash('id')

--     pair = box.space[space_name]:get{ id }

--     if pair ~= nil then
--         return http_json(200, { key = id, value = pair[2] })
--     else
--         return http_json(404, { message = 'Pair with this key doesn\'t exist.' })
--     end
-- end

-- local function delete_pair(req)
--     local id = req:stash('id')

--     pair = box.space[space_name]:get{ id }

--     if pair ~= nil then
--         box.space[space_name]:delete(id)

--         return http_json(200, { message = 'Deleted.' })
--     else
--         return http_json(404, { message = 'Pair with this key doesn\'t exist' })
--     end
-- end


-- box.cfg {
--     log = 'kv.log',
--     log_format='json'
-- }

-- box.schema.space.create(space_name, { if_not_exists = true })
-- pk = box.space[space_name]:create_index('primary', {
--     if_not_exists = true,
--     unique = true,
--     parts = { 1, 'string' }
-- })

-- local httpd = http.new("0.0.0.0", 8888, { log_requests = true })

-- httpd:route({ path = '/kv', method = 'POST' },
--     add_pair)

-- httpd:route({ path = '/kv/:id', method = 'PUT' },
--     update_pair)

-- httpd:route({ path = '/kv/:id', method = 'GET' },
--     get_pair)

-- httpd:route({ path = '/kv/:id', method = 'DELETE' },
--     delete_pair)

-- httpd:start()
