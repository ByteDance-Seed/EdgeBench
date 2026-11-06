# Arc Standard Library: net module
# Networking utilities

# --- URL ---

pub fn url_parse(url) => net_url_parse(url)
pub fn url_encode(text) => net_url_encode(text)
pub fn url_decode(text) => net_url_decode(text)

# --- Query String ---

pub fn parse_query(query_string) => net_query_parse(query_string)
pub fn build_query(params_map) => net_query_stringify(params_map)

# --- IP ---

pub fn ip_is_valid(addr) => net_ip_is_valid(addr)
