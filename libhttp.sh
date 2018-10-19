#!/usr/bin/env bash
source "$( cd "${BASH_SOURCE[0]%/*}" && pwd )/lib/oo-bootstrap.sh"

import util/variable util/class util/exception util/namedParameters

class:Http() {
  private string req_url
  private array req_header
  private string req_body
  private string req_method

  private map resp_header
  private string resp_body
  private integer resp_status

  # initialize Http object
  Http.__init__() {
    [string] url
    [array] header=()
    [string] body=""
    [string] method=""

    [ -z "$url" ] && e="url not given" throw
    this req_url = $url
    this req_header = $header
    this req_body = $body
    this req_method = $method
  }

  # throw POST request unless this method specified
  # TODO [WIP]
  Http.post() {
    if [[ -z "${url}" ]]; then
      e="url not given" throw
    fi

    # construct command
    local command = "curl --dump-header - -s -X ${method} --url ${url}"
    if [ "$header" != "" ]; then
      for h in header; do
        command+=" --header '${h}'"
      done
    fi
    [ "$body" != "" ] && command+=" -b '${body}'"

    res=$($command)
  }

  # current usage:
  # eval "<variable>=$(Http.get <url>)"
  # throw HTTP GET Request
  Http.get() {
    [[ -z "$(this url)" ]] && e="url not given" throw

    # construct command
    string cmd="curl --dump-header - -s -X $(this req_method) --url $(this req_url)"
    if [ "$(this req_header)" != "" ]; then
      for h in $(this req_header); do
        cmd+=" --header '${h}'"
      done
    fi
    [ "$(this req_body)" != "" ] && cmd+=" -b '$(this req_body)'"

    res=$(eval '$cmd')

    # separate and add header/body
    map lres_header=()
    string lres_body=""
    integer lres_is_header=0
    while read -r line; do
      if [ -z "$line" ]; then
        lres_is_header=1
      fi

      if [ $lres_is_header -eq 0 ]; then
        key=${line%%: *}
        val=${line##*:}
        lres_header[${key}]=${val}
      else
        lres_body+="$line "
      fi
    done < <(echo "$res" | sed 's///g')

    this resp_header = $lres_header
    this resp_body = $lres_body
    this resp_status = ${resp_header[status]}
    @return
  }

  Http::is_connected() {
    curl -s 'example.com' >/dev/null 2>&1
    return $?
  }

}

Type::Initialize Http
