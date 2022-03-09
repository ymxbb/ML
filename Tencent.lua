-- file: lua/backend-http.lua

local http = require 'http'
local backend = require 'backend'

local char = string.char
local byte = string.byte
local find = string.find
local sub = string.sub

local ADDRESS = backend.ADDRESS
local PROXY = backend.PROXY
local SUPPORT = backend.SUPPORT
local SUCCESS = backend.RESULT.SUCCESS
local HANDSHAKE = backend.RESULT.HANDSHAKE

local ctx_uuid = backend.get_uuid
local ctx_proxy_type = backend.get_proxy_type
local ctx_address_type = backend.get_address_type
local ctx_address_host = backend.get_address_host
local ctx_address_bytes = backend.get_address_bytes
local ctx_address_port = backend.get_address_port
local ctx_write = backend.write
local ctx_free = backend.free
local ctx_debug = backend.debug

local flags = {}
local kHttpHeaderSent = 1
local kHttpHeaderRecived = 2

function wa_lua_on_flags_cb(ctx)
    return 0
end

function wa_lua_on_handshake_cb(ctx)
    local uuid = ctx_uuid(ctx)

    if flags[uuid] == kHttpHeaderRecived then
        return true
    end

    if flags[uuid] ~= kHttpHeaderSent then
        local host = ctx_address_host(ctx)
        local port = ctx_address_port(ctx)
        local res = 'CONNECT ' .. host .. ':' .. port .. ' HTTP/1.1\r\nQ-GUID:f73c19461ec55c0b4de52d39377988cb\r\nQ-Token: 8a991145b87404c44ba40694833403e4a84c534fbade7f6ee915d0d708df73663814818b479788bb94d20f5f4c6d2153\r\n' ..
                    'Host: ' .. host ..'\r\n' ..
                    'Proxy-Connection: Keep-Alive\r\n\r\n'
        ctx_write(ctx, res)
        flags[uuid] = kHttpHeaderSent
    end

    return false
end

function wa_lua_on_read_cb(ctx, buf)
    local uuid = ctx_uuid(ctx)
    ctx_debug('wa_lua_on_read_cb')
    ctx_debug(buf)
    if flags[uuid] == kHttpHeaderSent then
        flags[uuid] = kHttpHeaderRecived
        return HANDSHAKE, nil
    end
    return SUCCESS, buf
end

function wa_lua_on_write_cb(ctx, buf)
    ctx_debug('wa_lua_on_write_cb')
    ctx_debug(buf)
    return SUCCESS, buf
end

function wa_lua_on_close_cb(ctx)
    local uuid = ctx_uuid(ctx)
    flags[uuid] = nil
    ctx_free(ctx)
    return SUCCESS
end
