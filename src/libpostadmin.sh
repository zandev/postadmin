
    log_debug() {
      if $debug; then
        echo "$@" >> "$debug_file"
      fi
    }

    log_verbose() {
      if $verbose; then
        echo "$@"
      fi
    }

    extract_config_vars() {
      awk '/##BEGIN CONFIG VARS/{f=1}f{print}/##END CONFIG VARS/{exit}' "$script_dir/$script_name"\
    | egrep '^ *[a-z0-9_]+='\
    | sed 's/^\s*\([a-z0-9_]\+\)=.*$/\1/'
    }

    print_vars() {
      for var in $@; do
        value=$(echo ${!var} | sed 's/^ //')
        if [[ "$var" =~ _query$ ]]; then
          echo $var=\"$value\" # wrap sql queries in double quotes
        else
          echo $var=$value
        fi
      done
    }

    show_help() {
      echo "
USAGE 
    $script_name [action] [command] [options] args...
WHERE
    action is one  of: $actions
    command is one of: $commands

For more specific help, type:
    $script_name [action] [command] --help
"
    }

    show_usage() {
      echo USAGE
      while read line; do
        echo -n '   '
        echo "$line"
      done < <(echo "$@")
      exit 1
    }

    require_var() {
      local var="$1"
      if [ -z "${!var}" ]; then
        log_debug "$var is not declared: "
        echo "$2"
        exit 1
      fi
    }

    validate_regex() {
      if ! [[ "$1" =~ ^$2$ ]]; then 
        echo "$3 '$1' does not match against the regular expression $2"
        exit 1
      fi
    }

    is_integer() {
      if [ "$(echo "$1" | grep "^[[:digit:]]\+$")" ]; then
        return 0
      else
        return 1
      fi
    }

    random_string() {
      if is_integer "$1"; then
        cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w "$1" | head -n 1
      else
        echo random_string: Invalid parameter '$1'
        exit 1
      fi
    }

    md5crypt_pwd() {
      echo "$1" | openssl passwd -1 -stdin -salt "$2"
    }

    rm_dir() {
      local basedir="$1"
      local dir="$2"
      local targetdir=$(echo "$basedir/$dir" | sed 's@^//@/@')

      if [ -z "$basedir" ]; then
        echo No base directory provided
        exit 1
      fi

      if [ -z "$dir" ]; then
        echo No target directory supplied
        exit 1
      fi

      if [ $(basename "$dir") != $dir ]; then
        echo "'$2' should be a leaf directory, eg: mydir, and not base/mydir"
        exit 1
      fi
      
      for d in "$basedir" "$targetdir"; do
        if [ ! -d "$d" ]; then
          echo Directory "$d" does not exist in the filesystem
          exit 1
        fi
      done

      if [ $(echo "$targetdir" | sed 's/\\ /_/g' | tr '/' ' ' | wc -w) = 1 ]; then
        echo "You silly boy! Do you really think I'd let you delete directory $targetdir?"
        exit 1
      fi
      
      rm -rf "$targetdir"
    }

    ask_help() {
      [[ "$1" == '--help' ]]
      return "$?"
    } 

    substitute_tokens() {
      local string="$1"; shift
      local vars="$@"
      for var in $vars; do
        local token=%"$var"%
        local value="${!var}"
        string=${string//"$token"/"$value"}
      done
      echo "$string"
    }

    domain_name() {
      echo "$1" | awk -F@ '{print $NF}'
    }

    localpart() {
      local domain=$(domain_name "$1")
      echo "${1%@$domain}"
    }

    # Sql queries
    db_query() {
      if [ -z "$@" ]; then
        echo "db_query: query is empty"
        exit 1
      fi
      query=$(substitute_tokens "$@" "$config_vars")
      local cmd=$(substitute_tokens "$sql_cmd" "$config_vars query")

      log_debug "$cmd" >> "$debug_file"

      eval $cmd
    }
  
    domain_id() {
      db_query "${domain_id_query//%domain%/$1};"
    }

    user_id_by_email() {
      db_query "${user_id_query//%email%/$1};"
    }

    user_id_by_username() {
      db_query "${user_id_by_username_query//%username%/$1};"
    }

    alias_id() {
      source_email="$1"
      destination_email="$2"
      local alias_query=$(substitute_tokens "$alias_id_query" source_email destination_email)
      echo $(db_query "$alias_query")
    }
