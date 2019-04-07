# FUNCTIONS

# Follow along:
# https://github.com/bajr/bbc2019_bash

# In true Beaver BarCamp tradition, everything here was prepared today;
# so I probably missed some things

# First, some basics.
# help, type
# if, for, while, case, select

# Defining functions is easy, just function name { }
function basic_func {
  # functions can print output
  echo "You called a function";
  # functions can only 'return' a number
  return 1;
}
# You can check the return code is by using $?

# FUNCTION PARAMETERS

# Functions can take parameters and give output, too
function func_params {
  # function parameters in bash are positional, these can be used with $n
  echo "hi, i'm ${FUNCNAME[0]}"

  # $# tells you how many parameters the function was given
  echo "I was given $# parameters."

  echo "Parameter 1 is $1"
  # parameters are positional, you can refer to them with $n or ${n}
  if [ $# -gt 9 ]; then
    # Note that you have to use ${} for more than 9 parameters
    echo "I was given lots of parameters, the 10th one is ${10}, not $10"
  fi
  # [ is actually a bash builtin

  # You can iterate through the given parameters with a special for loop
  for i; do # you can also use `for i in "$@";` here
    echo ${i}
  done
}

# $@ splits all given parameters into separate strings
function at_func_params {
  func_params "$@"
}

# $* combines them all into a single string
function splat_func_params {
  func_params "$*"
}

# It's almost always better to use $@ until you need $*'s behavior

# VARIABLES AND SCOPE

# what's a good language without variables?
# Function's do NOT invoke a new subshell, so variables set by them become available to the
#   environment that called them!
function basic_vars {
  # variables are local by default
  default_var="I'm default"

  # a better way of doing it is to be explicit with declare
  declare -g declare_var="I'm declared global"
  export export_var="I'm exported"

  # Be careful about how you quote your strings with variables
  echo 'Single quotes dont do parameter expansion ${local_var}'

  # local vars are available to the function they're declared in
  local local_var="I'm local"
  # but they're also available to all functions subsequently called
}

# global vars are available, even after the function that created them has gone out of scope
function global_vars {
  echo "default    : ${default_ver}"
  echo "declare -g : ${declare_var}"
  echo "export     : ${export_var}"
  echo "local      : ${local_var}"
}

# variables are available in specific scopes
function scope_vars {
  local local_var="I'm local"
  export -f global_vars # You can export functions, too
  # global variables are available to most things
  echo "Global variables are available to most things"
  global_vars
  echo
  echo "...but not subshells unless they're exported"
  bash -c 'global_vars' # global_vars would not be available if it wasn't exported
}

# sometimes it's easier to pass arrays by name
function pass_by_nameref {
  local -n _some_var1=${1}
  local -n _some_var2=${2}
  echo ${_some_var1[@]}
  echo ${_some_var2[@]}
}

function by_ref {
  local -a pass_array1=( "I" "am" "an" "array" )
  local -a pass_array2=( "I" "am" "another" "array" )
  pass_by_nameref pass_array1 pass_array2
}

# Subshells get weird very quickly. I encourage you to do your own tinkering here.

# I/O REDIRECTION AND PIPES

# By default everything in bash has 3 'file descriptors' for I/O:
#   stdin, stdout, and stderr

# Redirect function stdin to stdout
function stdin_2_stdout {
  echo $(</dev/stdin) >&1
}

# Redirect function stdin to stderr
function stdin_2_stderr {
  echo $(</dev/stdin) >&2
}

# Pipes take the stdout of one function and gives it to the stdin of another
# echo "text" | stdin_2_stdout | grep -Eo 't'
# echo "text" | stdin_2_stderr | grep -Eo 't'

# ARRAYS
function basic_arrays {
  # bash arrays have some interesting behaviors
  local -a my_array=( "elem1" "elem2" "elem3.1 elem3.2" )

  # arrays output the first element by default
  echo "${my_array}"

  # use [@] to reference all of them, like $@
  echo "${my_array[@]}"
  # the previous note about $* applies here as well

  echo
  echo "You can iterate elements of an array with a for loop"
  for i in "${my_array[@]}"; do
    echo "  ${i}"
  done
}

function associative_arrays {
  local weird_key="weird key"
  local -A what_is=(
    [this]="that"
    [us]="them"
    [here]="there"
    [me]="you"
    [jank]="I am not an technically an array"
    [${weird_key}]="I'm a weird key"
  )

  echo "Keys : ${!what_is[@]}"
  echo "Values : ${what_is[@]}"
  echo "me & you : ${what_is[me]}"
  echo "jank     : ${what_is[jank]}"
  local var_jank="jank"
  local bad_array=( "${what_is[${var_jank}]}" )
  local jank_array=( ${what_is[${var_jank}]} )
  echo "${#bad_array[@]} elements in bad_array"
  echo "${#jank_array[@]} elements in jank_array"
  echo "weird key : ${what_is[${weird_key}]}"
}

# PARAMETER EXPANSIONS
function param_expansion {
  echo "default      : ${where_am_i:-dunno}"
  local where_am_i="$(pwd)"
  echo "full path    : ${where_am_i}"
  echo "this dir     : ${where_am_i##*/}"
  echo "lead path    : ${where_am_i%/*}"
  echo "uppercase    : ${where_am_i^^}"
  echo "substitution : ${where_am_i/bbc/beaverbarcamp}"
}

# SOMETHING USEFUL

# echo to stderr without
function errecho {
  echo "$@" >&2
}

# Check if array contains an element
function contains {
  [ $# -lt 2 ] &&
    errecho "Usage: ${FUNCNAME[0]} SEARCH_ITEM \${BASH_ARRAY[@]}" \
      && return 1
  for i in "${@:2}"; do
    [[ "${i}" == "$1" ]] && return 0
  done
  return 1
}

# Never use ``
# always use ${} $()

# https://www.gnu.org/software/bash/manual/bashref.html#Here-Documents
function heredoc_ex {
  local heredoc_payload="$(base64 -w 0 <<EOF
echo "I'm in a heredoc"
echo "My variables are determined when the heredoc is created, $$"
EOF
  )"
  echo "heredoc_payload..."
  echo "${heredoc_payload}"
  echo $$
  echo
  echo "decrypted payload..."
  echo ${heredoc_payload} | base64 -d
  echo $$
  echo
  echo "in a subshell"
  bash -c 'echo $1 | base64 -d; echo $$' /dev/null ${heredoc_payload}

}

# https://www.gnu.org/software/bash/manual/bashref.html#Here-Strings
function herestring_ex {
  local var_names="thing1 thing2 thing3"
  local vars="var1 var2 var3"
  read -r ${vars} <<< ${var_names}
  echo ${var1}
  echo ${var2}
  echo ${var3}
}

function term_colors {
  local C_BOLD=$'\e[1m'
  local C_RED=$'\e[31m'
  local X_FMT=$'\e[0m'
  echo "${C_BOLD}Use magic ANSI strings${X_FMT} for ${C_RED}colors!${X_FMT}"
  echo "${C_RED}Don't forget to clear formatting"
}

function async_things {
  # You can background processes with &
  echo "With & async"
  echo "wait 1" && sleep 1 && echo "done 1" &
  echo "wait 2" && sleep 2 && echo "done 2" &
  echo "wait 3" && sleep 3 && echo "done 3" &
  echo "wait 4" && sleep 4 && echo "done 4" &
  echo "wait 5" && sleep 5 && echo "done 5" &

  # an alternative to this is xargs
  echo
  echo "With xargs"
  seq 1 5 | xargs -n1 -P0 bash -c 'echo "xargs wait $1" && sleep $1 && echo "xargs done $1"' /dev/null
}

# Useful external tools:
#   parallel, xargs
#   comm
#   grep, awk, sed

# xargs, coproc, & concurrency
# read loops, select, and other user prompts
# set options
# process substitution <()
