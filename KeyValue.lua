#!/usr/bin/env tarantool

local http  = require("http.server")
local json  = require("json")
space_name = 'kv-test'

local function http_json(code, data)
    return {
            status = code,
            headers = { ['content-type'] = 'application/json' },
            body = json.encode(data)
    }
end

local function add_pair(req)
    local k = req:param('key')
    local v = req:param('value')

    if type(k) ~= 'string' or type(v) ~= 'table' then
        return http_json(400, { message = 'Bad request body.' })
    end

    if box.space[space_name]:get{ k } ~= nil then
        return http_json(409, { message = 'This key already exists.' })
    end

    box.space[space_name]:insert{ k, v }

    return http_json(200, { key = k, value = v })
end

local function update_pair(req)
    local id = req:stash('id')
    local v = req:param('value')

    if type(v) ~= 'table' then
        return http_json(400, { message = 'Bad request body.' })
    end

    pair = box.space[space_name]:get{ id }

    if pair ~= nil then
        new_pair = box.space[space_name]:update(id, { { '=', 2, v } })

        return http_json(200, { key = id, value = new_pair[2] })
    else
        return http_json(404, { message = 'Pair with this key doesn\'t exist.' })
    end
end

local function get_pair(req)
    local id = req:stash('id')

    pair = box.space[space_name]:get{ id }

    if pair ~= nil then
        return http_json(200, { key = id, value = pair[2] })
    else
        return http_json(404, { message = 'Pair with this key doesn\'t exist.' })
    end
end

local function delete_pair(req)
    local id = req:stash('id')

    pair = box.space[space_name]:get{ id }

    if pair ~= nil then
        box.space[space_name]:delete(id)

        return http_json(200, { message = 'Deleted.' })
    else
        return http_json(404, { message = 'Pair with this key doesn\'t exist' })
    end
end


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

local httpd = http.new("0.0.0.0", 8888, { log_requests = true })

httpd:route({ path = '/kv', method = 'POST' },
    add_pair)

httpd:route({ path = '/kv/:id', method = 'PUT' },
    update_pair)

httpd:route({ path = '/kv/:id', method = 'GET' },
    get_pair)

httpd:route({ path = '/kv/:id', method = 'DELETE' },
    delete_pair)

httpd:start()
