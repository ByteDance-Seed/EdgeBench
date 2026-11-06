# Arc Standard Library: http module
# HTTP utilities built on @ tool calls

pub fn get(url) => @GET url

pub fn post(url, body) {
  @POST url {data: body}
}

pub fn put(url, body) {
  @PUT url {data: body}
}

pub fn delete(url) => @DELETE url

pub fn fetch_all(urls) {
  map(urls, u => @GET u)
}

pub fn parse_url(url) {
  # Extract protocol, host, path from URL string
  let mut protocol = ""
  let mut rest = url

  if starts(url, "https://") {
    protocol = "https"
    rest = slice(url, 8, len(url))
  } el if starts(url, "http://") {
    protocol = "http"
    rest = slice(url, 7, len(url))
  } el {
    protocol = ""
    rest = url
  }

  # Find first / after protocol
  let parts = split(rest, "/")
  let host = head(parts)
  let path_parts = tail(parts)
  let path = if len(path_parts) > 0 { "/" ++ join(path_parts, "/") } el { "/" }

  {protocol: protocol, host: host, path: path}
}
