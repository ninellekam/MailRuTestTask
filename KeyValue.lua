#!/usr/bin/env tarantool

local http  = require("http.server")
local json  = require("json")
space_name = 'kv-test'

box.cfg {
	log = 'kv.log',
	log_format='json'
}

box.schema.space.create(space_name, { if_not_exists = true })
pk = box.space[space_name]:create_index('primary', {
	if_not_exists = true,
	unique = true,
	parts = { 1, 'string' }
})

local function http_json(code, data)
	return {
			status = code,
			headers = { ['content-type'] = 'application/json' },
			body = json.encode(data)
	}
end

local kv_storage = {
	post = function(req)
		local key = req:param('key')
		local value = req:param('value')

		if type(key) ~= 'string' or type(value) ~= 'table' then
			return http_json(400, { message = 'Bad request body.' })
		end

		if box.space[space_name]:get{ key } ~= nil then
			return http_json(409, { message = 'This key already exists.' })
		end

		box.space[space_name]:insert{ key, value }

		return http_json(200, { key = key, value = value })
	end,

	put = function(req)
		local id = req:stash('id')
		local value = req:param('value')

		if type(value) ~= 'table' then
			return http_json(400, { message = 'Bad request body.' })
		end

		pair = box.space[space_name]:get{ id }

		if pair ~= nil then
			new_pair = box.space[space_name]:update(id, { { '=', 2, value } })

			return http_json(200, { key = id, value = new_pair[2] })
		else
			return http_json(404, { message = 'Pair with this key doesn\'t exist.' })
		end
	end,

	delete = function(req)
		local id = req:stash('id')

		pair = box.space[space_name]:get{ id }

		if pair ~= nil then
			box.space[space_name]:delete(id)
			return http_json(200, { message = 'Deleted.' })
		else
			return http_json(404, { message = 'Pair with this key doesn\'t exist' })
		end
	end,

	get = function(req)
		local id = req:stash('id')
		pair = box.space[space_name]:get{ id }

		if pair ~= nil then
			return http_json(200, { key = id, value = pair[2] })
		else
			return http_json(404, { message = 'Pair with this key doesn\'t exist.' })
		end
	end
}

local server = http.new("0.0.0.0", 8888, { log_requests = true })

server:route({ path = '/kv', method = 'POST' }, kv_storage.post)
server:route({ path = '/kv/:id', method = 'PUT' }, kv_storage.put)
server:route({ path = '/kv/:id', method = 'GET' }, kv_storage.get)
server:route({ path = '/kv/:id', method = 'DELETE' }, kv_storage.delete)
server:start()
