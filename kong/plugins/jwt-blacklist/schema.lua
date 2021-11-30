local typedefs = require "kong.db.schema.typedefs"

return {
  name = "rate-limiting",
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
        }
      },
    },
  }
}