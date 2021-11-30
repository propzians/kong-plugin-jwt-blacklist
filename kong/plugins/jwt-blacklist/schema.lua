local typedefs = require "kong.db.schema.typedefs"

return {
    name = "jwt-blacklist",
    fields = {
        { protocols = typedefs.protocols_http },
        { config = {
            type = "record",
            fields = {
                { redis_host = typedefs.host },
                { redis_port = typedefs.port({ default = 6379 }), },
                { redis_password = { type = "string", len_min = 0 }, },
                { redis_username = { type = "string" }, },
                { redis_ssl = { type = "boolean", required = true, default = false, }, },
                { redis_ssl_verify = { type = "boolean", required = true, default = false }, },
                { redis_server_name = typedefs.sni },
                { redis_timeout = { type = "number", default = 2000, }, },
                { redis_database = { type = "integer", default = 0 }, },
                { token_member = { type = "string", default = "keycloak:token:blacklist" }, },
                { token_prefix = { type = "string", default = "token_" }, },
                { token_verify = { type = "boolean", required = true, default = true }, },
                { user_member = { type = "string", default = "keycloak:user:blacklist" }, },
                { user_prefix = { type = "string" , default = "user_"}, },
                { user_verify = { type = "boolean", required = true, default = true }, },
                { user_claim_name = { type = "string" , default = "sub"}, },
                { run_on_preflight = { type = "boolean", required = true, default = true }, },
                { uri_param_names = {
                    type = "set",
                    elements = { type = "string" },
                    default = { "jwt" },
                }, },
                { cookie_names = {
                    type = "set",
                    elements = { type = "string" },
                    default = {}
                }, },
                { header_names = {
                    type = "set",
                    elements = { type = "string" },
                    default = { "authorization" },
                }, },
                { client_id = { type = "string" , required = true}, },
                { client_secret = { type = "string" , required = true}, },
                { introspection_endpoint = { type = "string" , required = true}, },
            }
        },
        },
    }
}