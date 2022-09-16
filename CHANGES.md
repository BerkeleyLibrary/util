# 0.1.5 (next)

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
