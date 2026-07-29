#!/bin/sh

[ -n "$lib_env_load_once" ] && return
lib_env_load_once=1

write_cli_config()
{
	config_file="$HOME/.config/cli/defaults"
	if [ ! -d "$config_file" ]; then
		mkdir -p "$config_file"
	fi

	if [ ! -f "$config_file/config.yaml" ]; then
		cp "$LKP_SRC/lib/default_config.yaml" "$config_file/config.yaml"
	fi
}

set_env()
{
	write_cli_config
}

set_env
