input_json=$(</dev/stdin)

host=$(echo ${input_json} | jq -r '.source.host')
user=$(echo ${input_json} | jq -r '.source.user')
pkey=$(echo ${input_json} | jq -r '.source.private_key')
glob=$(echo ${input_json} | jq -r '.source.glob')

version=$(echo ${input_json} | jq -r '.version')
[ -z "${version}" ] || version=$(echo "${version}" | jq -r '.path')

keyfile=$(mktemp)

# Make sure to wrap in quotes, or the newlines (which are necessary) are swallowed
echo "${pkey}" > ${keyfile}

eval $(ssh-agent)
ssh-add ${keyfile}
