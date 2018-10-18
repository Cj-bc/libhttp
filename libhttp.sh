import class exception

class:Http() {
}

Http.post() {
  [string] url
  [array] header = ()
  [string] body = ""
  [string] method = "POST"

  if [[ -z "${url}" ]]; then
    e="url not given" throw
  fi

  # construct command
  local command = "curl --dump-header - -s -X ${method} --url ${url} -b '${body}'"
  for h in header; do
    command+=" --header '${h}'"
  done

  eval "$command"
}


Http.get() {
  [string] url
  [array] header = ()
  [string] body = ""
  [string] method = "GET"

  if [[ -z "${url}" ]]; then
    e="url not given" throw
  fi

  # construct command
  local command = "curl --dump-header - -s -X ${method} --url ${url} -b '${body}'"
  for h in header; do
    command+=" --header '${h}'"
  done

  res=$(eval "$command")

  # add header
  local -A header=()
  while read -r line; do
    if [ -z "$line" ]; then
      break
    fi
    key=${line%%: *}
    val=${line##*:}

    header=("${header[@]}" [${header}=${val}] )
  done < <(echo "res" | sed 's///g')
}

Type::InitializeStatic Http
