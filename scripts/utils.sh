# vim: set ts=4 sw=4:
# Utility functions for one-context scripts.
# https://github.com/jirutka/one-context

readonly VERSION='0.9.0'

# Enable pipefail if supported by the shell.
if ( set -o pipefail 2>/dev/null ); then
	set -o pipefail
fi

# Creates, updates or deletes generated section with the given content in the
# specified configuration file. If the content is empty string, then the
# generated section (start/end tags and everything between) is removed.
#
# $1: Path of the file to modify.
# $2: Content to be inserted into the file; reads from STDIN if not provided.
update_config() {
	local conf_file="$1"
	local content="${2-"$(cat -)"}"  # if $2 is *not set*, read from STDIN

	local start_tag='# BEGIN generated'
	local end_tag='# END generated'

	[ -z "$content" ] || content=$(
		cat <<-EOF
			$start_tag by one-context (do not modify this block)
			$content
			$end_tag
		EOF
	)

	if [ -f "$conf_file" ] && grep -q "^$start_tag" "$conf_file"; then

		if [ "$content" ]; then
			content=${content//$'\n'/\\$'\n'}  # escape \n, busybox sed doesn't like them
			sed -ni "/^$start_tag/ {
					a\\$content
					# read and discard next line and repeat until $end_tag or EOF
					:a; n; /^$end_tag/!ba; n
				}; p" "$conf_file"
		else
			# Remove start/end tags and everything between them.
			sed -i "/^$start_tag/,/^$end_tag/d" "$conf_file"
		fi

	elif [ "$content" ]; then
		printf '\n%s\n' "$content" >> "$conf_file"
	fi
}

# Prints value of the specified variable, or the given default if the variable
# is empty or not defined.
#
# $1: Name of the variable to print.
# $2: Default value.
getval() {
	local var_name="$1"
	local default="${2:-}"

	eval "printf '%s\n' \${$var_name:-$default}"
}

# Returns 0 if the given value is "YES" (case insensitive), 1 otherwise.
#
# $1: The value to test.
yesno() {
	case "$1" in
		[yY][eE][sS]) return 0;;
		*) return 1;;
	esac
}
