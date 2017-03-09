
function output() {
	echo "$@" >&3
}

function initialize() {
	local input_json=$1
	echo "${input_json}" > /tmp/stdin

	local host=$(echo ${input_json} | jq -r '.source.host')
	local user=$(echo ${input_json} | jq -r '.source.user')
	local pkey="$(echo ${input_json} | jq -r '.source.private_key')"
	local glob=$(echo ${input_json} | jq -r '.source.glob')
	local basedir=$(echo ${input_json} | jq -r '.source.base_directory')

	# sanitize the glob
	glob=$(basename ${glob})

	# give a default to basedir
	[[ ${basedir} == "null" ]] && basedir="."

	local version=$(output ${input_json} | jq -r '.version')
	[[ ${version} != "null" ]] && version=$(output "${version}" | jq -r '.path')

	echo "Initializing environment"

	output "host='${host}'"
	output "user='${user}'"
	output "glob='${glob}'"
	output "version='${version}'"
	output "basedir='${basedir}'"
	output "pkey='${pkey}'"
}

function init_ssh_auth() {
	local pkey=$1
	keyfile=$(mktemp)

	pkey=$(output "${pkey}" | sed -e 's/-----BEGIN RSA PRIVATE KEY----- \(.*\) -----END RSA PRIVATE KEY-----/\1/' | tr ' ' '\n')
	output "-----BEGIN RSA PRIVATE KEY-----" > ${keyfile}
	output "${pkey}" >> ${keyfile}
	output "-----END RSA PRIVATE KEY-----" >> ${keyfile}
	chmod 600 ${keyfile}

	ssh-keygen -l -f ${keyfile} > /dev/null 2>&1
	is_good=$?

	if [[ ${is_good} != 0 ]]; then
		echo "Private key file is corrupt!"
		exit ${is_good}
	fi

	eval $(ssh-agent) > /dev/null 2>&1
	ssh-add ${keyfile} > /dev/null 2>&1
}

function get_latest_files() {
	local user=$1
	local host=$2
	local glob=$3
	local version=$4
	local basedir=$5

	files=$(ssh -o StrictHostKeyChecking=no ${user}@${host} "ls -lrt ${basedir}/${glob}")
	files=$(output "${files}" | awk '/^\-/{print $(NF)}')

	if [[ $version != null ]]; then
		version=$(basename ${version})
		grepcheck="^${basedir}/${version}$"

		numfiles=$(output "${files}" | wc -l | xargs)
		files=$(output "${files}" | grep -A ${numfiles} "${grepcheck}")
	else
		files=$(output "${files}" | head -n 1)
	fi

	output "${files}"
}

exec 3>&1 # make stdout available as fd 3 for the result
exec 1>&2 # redirect all output to stderr for logging

input_json=$(</dev/stdin)

vars=$(initialize "${input_json}")

output ${vars} > /tmp/vars
eval ${vars}

init_ssh_auth "${pkey}"
