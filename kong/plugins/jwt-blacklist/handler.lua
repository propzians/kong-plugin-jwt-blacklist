local redis = require "resty.redis"
local jwt_decoder = require "kong.plugins.jwt.jwt_parser"

local cjson = require "cjson"
local kong = kong
local type = type
local ipairs = ipairs
local error = error
local re_gmatch = ngx.re.gmatch

local JwtBlacklistHandler = {
    VERSION = "0.1.2",
    PRIORITY = 1006
}

--- Retrieve a JWT in a request.
-- Checks for the JWT in URI parameters, then in cookies, and finally
-- in the configured header_names (defaults to `[Authorization]`).
-- @param request ngx request object
-- @param conf Plugin configuration
-- @return token JWT token contained in request (can be a table) or nil
-- @return err
local function retrieve_token(conf)
    local args = kong.request.get_query()
    for _, v in ipairs(conf.uri_param_names) do
        if args[v] then
            return args[v]
        end
    end

    local var = ngx.var
    for _, v in ipairs(conf.cookie_names) do
        local cookie = var["cookie_" .. v]
        if cookie and cookie ~= "" then
            return cookie
        end
    end

    local request_headers = kong.request.get_headers()
    for _, v in ipairs(conf.header_names) do
        local token_header = request_headers[v]
        if token_header then
            if type(token_header) == "table" then
                token_header = token_header[1]
            end
            local iterator, iter_err = re_gmatch(token_header, "\\s*[Bb]earer\\s+(.+)")
            if not iterator then
                kong.log.err(iter_err)
                break
            end

            local m, err = iterator()
            if err then
                kong.log.err(err)
                break
            end

            if m and #m > 0 then
                return m[1]
            end
        end
    end
end

local function is_present(str)
    return str and str ~= "" and str ~= null
end

local sock_opts = {}

local function get_redis_connection(conf)
    kong.log.info("[[jwt-blacklist] config" .. cjson.encode(conf))

    local red = redis:new()
    red:set_timeout(conf.redis_timeout)

    sock_opts.ssl = conf.redis_ssl
    sock_opts.ssl_verify = conf.redis_ssl_verify
    sock_opts.server_name = conf.redis_server_name

    -- use a special pool name only if redis_database is set to non-zero
    -- otherwise use the default pool name host:port
    sock_opts.pool = conf.redis_database and
            conf.redis_host .. ":" .. conf.redis_port ..
                    ":" .. conf.redis_database
    local ok, err = red:connect(conf.redis_host, conf.redis_port,
            sock_opts)
    if not ok then
        kong.log.err("failed to connect to Redis: ", err)
        return nil, err
    end

    local times, err = red:get_reused_times()
    if err then
        kong.log.err("failed to get connect reused times: ", err)
        return nil, err
    end

    if times == 0 then
        if is_present(conf.redis_password) then
            local ok, err
            if is_present(conf.redis_username) then
                ok, err = red:auth(conf.redis_username, conf.redis_password)
            else
                ok, err = red:auth(conf.redis_password)
            end

            if not ok then
                kong.log.err("failed to auth Redis: ", err)
                return nil, err
            end
        end

        if conf.redis_database ~= 0 then
            -- Only call select first time, since we know the connection is shared
            -- between instances that use the same redis database

            local ok, err = red:select(conf.redis_database)
            if not ok then
                kong.log.err("failed to change Redis database: ", err)
                return nil, err
            end
        end
    end

    return red
end


local function introspect_token(conf, token)
    local res, err = require("resty.openidc").introspect(conf)
    if err then
        kong.log.info("[jwt-blacklist] introspect token fail " .. token, err)
        return false, {
            status = 401,
            message = "Token has been locked"
        }
    end
    return res
end

local function check_valid_token(conf)
    local token, err = retrieve_token(conf)
    if err then
        return error(err)
    end

    local token_type = type(token)
    if token_type ~= "string" then
        if token_type == "nil" then
            return false, {
                status = 401,
                message = "Unauthorized"
            }
        elseif token_type == "table" then
            return false, {
                status = 401,
                message = "Multiple tokens provided"
            }
        else
            return false, {
                status = 401,
                message = "Unrecognizable token"
            }
        end
    end

    -- Validate jwt token in blacklist
    if conf.token_verify then
        local red, redis_err = get_redis_connection(conf)
        if not red then
            kong.log.err("[jwt-blacklist] Could connect redis", redis_err)
            introspect_token(conf, token)
        end
        ---SISMEMBER
        local verify, q_err = red:sismember(conf.token_member, conf.token_prefix .. token)
        if q_err then
            kong.log.err("[jwt-blacklist] Could connect redis", q_err)
            introspect_token(conf, token)
        end

        if verify > 0 then
            kong.log.info("[jwt-blacklist] Token already in blacklist: " .. token)
            return false, {
                status = 401,
                message = "Token has been locked"
            }
        end
    end

    -- Validate userId in blacklist
    if conf.user_verify then
        local red, redis_err = get_redis_connection(conf)
        if not red then
            kong.log.err("[jwt-blacklist] Could connect redis", redis_err)
            introspect_token(conf, token)
        end

        -- Decode token to find out who the consumer is
        local jwt, decode_error = jwt_decoder:new(token)
        if decode_error then
            return false, { status = 401, message = "Invalid token"}
        end

        local claims = jwt.claims
        local user_id = claims[conf.user_claim_name]

        local verify, q_err = red:sismember(conf.user_member, conf.user_prefix .. user_id)
        if q_err then
            kong.log.err("[jwt-blacklist] Could connect redis", q_err)
            introspect_token(conf, token)
        end

        if verify > 0 then
            kong.log.info("[jwt-blacklist] Your account has been locked: " .. user_id)
            return false, {
                status = 401,
                message = "Your account has been locked"
            }
        end
    end

    return true

end

function JwtBlacklistHandler.access(self, conf)
    -- check if preflight request and whether it should be authenticated
    if not conf.run_on_preflight and kong.request.get_method() == "OPTIONS" then
        return
    end

    local ok, err = check_valid_token(conf)
    if not ok then
        return kong.response.exit(err.status, err.errors or {
            message = err.message
        })
    end

end

return JwtBlacklistHandler
