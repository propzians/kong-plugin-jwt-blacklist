local constants = require "kong.constants"
local jwt_decoder = require "kong.plugins.jwt.jwt_parser"
local redis = require "resty.redis"

local fmt = string.format
local kong = kong
local type = type
local error = error
local ipairs = ipairs
local tostring = tostring
local re_gmatch = ngx.re.gmatch

local JwtBlacklistHandler = {
    VERSION = "0.1.0",
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

    local request_headers = kong.request.get_headers()
    local token_header = request_headers["Authorization"]
    local iterator, iter_err = re_gmatch(token_header, "\\s*[Bb]earer\\s+(.+)")
    if not iterator then
        kong.log.err(iter_err)
    end

    local m, err = iterator()
    if err then
        kong.log.err(err)
    end

    if m and #m > 0 then
        return m[1]
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
            kong.log.err("[jwt-blacklist] token type nill")
            return false, {
                status = 401,
                message = "Unauthorized"
            }
        elseif token_type == "table" then
            kong.log.err("[jwt-blacklist] token type table")
            return false, {
                status = 401,
                message = "Multiple tokens provided"
            }
        else
            kong.log.err("[jwt-blacklist] Unrecognizable token")
            return false, {
                status = 401,
                message = "Unrecognizable token"
            }
        end
    end

    -- Check jwt token in blacklist
    -- Init Redis connection
    kong.log.info("[jwt-blacklist] Begin check jwt blacklist")

    local red = redis:new()
    red:set_timeout(20000)

    -- Connet to redis
    local ok, err = red:connect("host.docker.internal", 6379)
    if not ok then
        kong.log.err("[jwt-blacklist] Could connect redis")
        return kong.response.exit(503, "Service Temporarily Unavailable")
    end

    kong.log.err("[jwt-blacklist] Token " .. token)
    
    local verify, err = red:exists(token)
    kong.log.err("[jwt-blacklist] existed " .. verify)
    if err then
        kong.log.err("[jwt-blacklist] Could connect redis")
        return kong.response.exit(503, "Service Temporarily Unavailable") -- TODO: add fallback
    end

    if verify > 0 then
        kong.log.err("[jwt-blacklist] Token already in blacklist")
        return false, {
            status = 401,
            message = "Token already in blacklist"
        }
    end

    return true

end

function JwtBlacklistHandler.access(self, conf)
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
        return kong.response.exit(err.status, err.errors or {
            message = err.message
        })
    end

end

return JwtBlacklistHandler
