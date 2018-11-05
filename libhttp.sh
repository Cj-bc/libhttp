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
    @required [string] url
    [string] method=""
    [string] body=""
    [...rest] header

    [ -z "$url" ] && e="url not given" throw
    this req_url = $url
    this req_header = ${header[@]}
    this req_body = $body
    this req_method = $method
  }

  Http.response() {
    [string] param
    [string] opt

    case $param in
      "header" )
        if [ -z "$opt" ]; then
          @return "$(this resp_header)"
        else
          @return "$(this resp_header get $opt)"
        fi
        ;;
      "body" ) @return "$(this resp_body)";;
      "status" ) @return $(this resp_status);;
      * ) e="param not found" throw;;
    esac

#    case $param in
#      "header" )
#        if [ -z "$opt" ]; then
#          echo -E $(this resp_header)
#        else
#          echo -E $(this resp_header get $opt)
#        fi
#        ;;
#      "body" ) echo -E  $(this resp_body);;
#      "status" ) echo -E $(this resp_status);;
#      * ) e="param not found" throw;;
#    esac
  }

  # throw POST request unless this method specified
  # TODO [WIP]
  Http.post() {
    Http::is_connected || e="network not found" throw
    [[ -z "$(this req_url)" ]] && e="url not given" throw

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

    Http::is_connected || e="network not found" throw
    [[ -z "$(this req_url)" ]] && e="url not given" throw

    # construct command
    string cmd="curl --dump-header - -s -X $(this req_method) --url $(this req_url)"
    if [ "$(this req_header)" != "" ]; then
      for h in $(this req_header); do
        cmd+=" --header '${h}'"
      done
    fi
    [ "$(this req_body)" != "" ] && cmd+=" -b '$(this req_body)'"

    res=$(eval '$cmd')

    # separate and add response header/body
    map lres_header=()
    string lres_body=""
    integer lres_is_header=0
    while read -r line; do
      if [ -z "$line" ]; then
        lres_is_header=1
      fi

      if [ $lres_is_header -eq 0 ]; then
        local key=${line%%: *}
        local val=${line##*:}
        $var:lres_header set "${key}" "${val}"
      else
        lres_body+="$line\r"
      fi
    done < <(echo "$res" | sed 's///g')

    this resp_header = ${lres_header[@]}
    this resp_body = "${lres_body[@]}"
    this resp_status = ${resp_header[status]}
    @return
  }

  Http::is_connected() {
    curl -s 'example.com' >/dev/null 2>&1
    return $?
  }

  Http::__dir__() {
    compgen -c | grep 'Http[.:]' | sed 's/Http[.:]*//g'
    @return
  }
}

Type::Initialize Http
