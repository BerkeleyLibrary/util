# 0.1.7 (next)

- Allow passing `log: false` to `Requester` methods (and corresponding `URIs` convenience
  methods) to suppress logging of each request URL and response code.
- Allow constructing `Requester` instances with delayed execution
- Fix documentation for `get_response` and `head_response` in `URIs` and `Requester`

# 0.1.6 (2023-03-09)

- Fix issue in `Requester` where query parameters would not be appended properly
  to URLs that already included a query string.
- Fix issue in `URIs#append` (and `Appender`) where `?` would not be accepted in
  query strings or fragments, contrary to RFC 3986 §3.
- Fix documentation for `Arrays#find_indices`.
- Fix issue where `Arrays#find_index` would raise a confusing `NameError`
  instead of a helpful `ArgumentError` if passed too many arguments.

# 0.1.5 (2022-09-16)

- Adds `URIs#path_escape` to escape URL path segments
- Adds `URIs#head` and `URIs#head_response`, to make a HEAD request and return the HTTP status code 
  and raw response object, respectively
- Clarifies documentation for `URIs#get` and `URIs#get_response` regarding unsuccessful requests

# 0.1.4 (2022-07-20)

- Adds `URIs#safe_parse_uri`, which returns `nil` for invalid URLs (unlike `URIs#uri_or_nil`, which
  raises `URI::InvalidURIError` for non-nil, non-parseable URLs)
- Updates documentation for `URIs#uri_or_nil` and `Validator#uri_or_nil` to clarify that
  `nil` is an acceptable argument.

# 0.1.3 (2022-05-11)

- Adds `URIs#get_response`, which returns a complete `RestClient::Response` rather than just
  the response body.

# 0.1.2 (2022-05-05)

- Adds `BerkeleyLibrary::Files`, which contains file and IO utility methods

# 0.1.1 (2021-09-23)

- `URIs#append` now handles bare URLs with empty paths, with the caveat that
  a root path `/` will always be added, even if there are no path elements to append.

# 0.1.0 (2021-09-23)

- Initial extraction of code from [`berkeley_library/tind`](https://github.com/BerkeleyLibrary/tind).
