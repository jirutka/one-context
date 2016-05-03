# vim: set ts=4:
# Utility functions for one-context scripts.
# https://github.com/jirutka/one-context

readonly VERSION='0.3.0'

# Update/create generated section with the given content in the specified
# configuration file.
#
# $1: Path of the file to modify.
# $2: Path of the script that generated the config (just for info).
# $3: Content to be inserted into the file; reads from STDIN if not provided.
update_config() {
	local conf_file="$1"
	local generated_by="$2"
	local content="${3:-"$(cat -)"}"

	local start_tag='# BEGIN generated'
	local end_tag='# END generated'

	content=$(
		cat <<-EOF
			$start_tag by $generated_by
			# Do not modify this block, any modifications will be lost after reboot!
			$content
			$end_tag
		EOF
	)

	if [ -f "$conf_file" ] && grep -q "^$start_tag" "$conf_file"; then
		content=${content//$'\n'/\\$'\n'}  # escape \n, busybox sed doesn't like them

		sed -ni "/^$start_tag/ {
				a\\$content
				# read and discard next line and repeat until $end_tag or EOF
				:a; n; /^$end_tag/!ba; n
			}; p" "$conf_file"
	else
		printf "$content" >> "$conf_file"
	fi
}
