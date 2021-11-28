local constants = require "kong.constants"
local jwt_decoder = require "kong.plugins.jwt.jwt_parser"


local fmt = string.format
local kong = kong
local type = type
local error = error
local ipairs = ipairs
local tostring = tostring
local re_gmatch = ngx.re.gmatch

local PropzyJwtBlacklistHandler = {
    VERSION = "1.0.0",
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

local function do_authentication(conf)
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

    -- Check jwt token in blacklist
    

    return true
end

function PropzyJwtBlacklistHandler.access(self, config)
    -- check if preflight request and whether it should be authenticated
    if not conf.run_on_preflight and kong.request.get_method() == "OPTIONS" then
        return
    end

    if conf.anonymous and kong.client.get_credential() then
        -- we're already authenticated, and we're configured for using anonymous,
        -- hence we're in a logical OR between auth methods and we're already done.
        return
    end

    local ok, err = do_authentication(conf)
    if not ok then
        if conf.anonymous then
            -- get anonymous user
            local consumer_cache_key = kong.db.consumers:cache_key(conf.anonymous)
            local consumer, err = kong.cache:get(consumer_cache_key, nil, kong.client.load_consumer, conf.anonymous,
                true)
            if err then
                return error(err)
            end

            set_consumer(consumer)

        else
            return kong.response.exit(err.status, err.errors or {
                message = err.message
            })
        end
    end

end

return PropzyJwtBlacklistHandler
