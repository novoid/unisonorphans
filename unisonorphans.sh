#!/bin/sh
FILENAME=$(basename $0)

show_help()
{
cat <<EOF

  - Time-stamp: <2013-03-17 12:00:58 vk>
  - Author:     Karl Voit, tools@Karl-Voit.at
  - License:    GPL v3

  If you are using unison file synchronizer[1] and you wonder which 
  of the ignored files exists locally (and are not synced), you might 
  like this script :-)

  This script analyzes \$PRFFILES (preferences files from unison) 
  and prints out information about ignored items: item type (file, 
  directory, link, ...) or if item is missing.

  If you give any parameter (other than \"==help\" or similar) to 
  this script, missing items are not listed. This is handy to look 
  only for local files that do not get synchronized.

  Please modify the content of \$PRFFILES (to meet your requirements)
  in: ${0}

  Depends on: sed, grep, mktemp

  Usage: ${FILENAME}
                ... lists all ignored items and their type

         ${FILENAME} --ignore
                ... lists only ignored items that exist locally

  [1] http://www.cis.upenn.edu/~bcpierce/unison/

EOF
exit 0
}

## a list of absolute paths to all relevant PRF files:
PRFFILES="${HOME}/.unison/blanche_common ${HOME}/.unison/blanche_gary_ALW_local.prf"



TEMPFILE=`mktemp`

IGNORENOTFOUND="false"
if [ -n "${1}" ]; then
    [ "${1}" = "-h" ] && show_help
    [ "${1}" = "-help" ] && show_help
    [ "${1}" = "--help" ] && show_help
    [ "${1}" = "help" ] && show_help
    IGNORENOTFOUND="true"
fi

debugthis()
{
        [ "${DEBUG}" = "true" ] && echo $FILENAME: DEBUG: $@
        #echo $FILENAME: DEBUG: $@ >> ${LOGFILE}
        echo "do nothing" >/dev/null
}

report()
{
    #echo "-----------------------------------------------"
        echo "$FILENAME: $@"
    #echo "-----------------------------------------------"
        #echo $FILENAME: $@ >> ${LOGFILE}
}

errorexit()
{
    debugthis "function myexit($1) called"

    [ "$1" -lt 1 ] && echo "$FILENAME done."
    if [ "$1" -gt 0 ]; then
        echo
        echo "$FILENAME aborted with errorcode $1:  $2"
        echo
        #echo "See \"${LOGFILE}\" for further details."
        #echo
    fi

    exit $1
}


handle_item()
{
    item="${1}"

    if [ -L "${item}" ]; then
	echo "symlink:   ${item}"
    elif [ -b "${item}" ]; then
	echo "block:     ${item}"
    elif [ -c "${item}" ]; then
	echo "character: ${item}"
    elif [ -p "${item}" ]; then
	echo "named pipe:${item}"
    elif [ -d "${item}" ]; then
	echo "directory: ${item}"
    elif [ -f "${item}" ]; then
	echo "file:      ${item}"
    elif [ -e "${item}" ]; then
	echo "EXISTS:    ${item}"
    else
	if [ "${IGNORENOTFOUND}" = "false" ]; then
	    echo "not found: ${item}"
	fi
    fi
}

cat ${PRFFILES} | sort > "${TEMPFILE}"


echo
report "=====-----> not ignore-path ..."
echo
grep -v "ignore = Path" "${TEMPFILE}" | grep ignore | sed 's/.*://'

echo
echo

cd "${HOME}"

echo
report "=====-----> ignore-path ..."
echo

while read rawline
do
   line=`echo "$rawline" | grep "ignore = Path" | sed 's/ignore = Path //' | sed 's/{//' | sed 's/}//' | sed 's/.*://'`
   [ -z "$line" ] && continue
   handle_item "${line}"
done < "${TEMPFILE}"


rm "${TEMPFILE}"

#end