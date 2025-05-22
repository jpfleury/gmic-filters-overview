#!/usr/bin/env bash

# This file is part of gmic-filters-overview.
# Apply all G'MIC filters to an image and browse the results in HTML.

# Author: Jean-Philippe Fleury (<https://github.com/jpfleury>)
# Copyright © 2015, 2025 Jean-Philippe Fleury

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

################################################################################
## @title Constants (1 of 2)
################################################################################

SCRIPT_FOLDER=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
USER_FOLDER="$SCRIPT_FOLDER/user"

declare -r SCRIPT_FOLDER USER_FOLDER

BOLD=$(tput bold 2> /dev/null)
DEFAULT=$(tput sgr0 2> /dev/null)
N=$'\n'

declare -r BOLD DEFAULT N

################################################################################
## @title Inclusions
################################################################################

source "$SCRIPT_FOLDER/inc/functions.sh"
source "$SCRIPT_FOLDER/inc/config.sh"

if [[ -f "$USER_FOLDER/inc/config.sh" ]]; then
	# shellcheck source=/dev/null
	source "$USER_FOLDER/inc/config.sh"
fi

################################################################################
## @title Command line options
################################################################################

# Option: -a
# If true, "About" section is hidden by default in the HTML file.
hide_html_about=false

# Option: -c
# Restrict filter categories to the specified list. If empty, all categories are used.
user_categories=()
user_categories_txt=""
display_categories=false

# Option: -d
# If true, delete existing files inside the HTML folder.
delete_existing_files=false

# Option: -f
# Update G'MIC filters.
update_gmic_filters=false

# Option: -l
# If true, don't create the log file.
disable_log_file_creation=false

# Option: -o
# If true, open the HTML file after generating it.
open_html_file=false

# Option: -r
# Resize the source image before applying filters. The source image is not modified.
# A copy is created. Default is no resizing.
new_size=""

# Option: -s FILE
# Source image. Default is the sample image shipped with the script.
source_image="$SCRIPT_FOLDER/data/sample.jpg"

# Option: -u
# If true, update code only without regenerating images. If used with the -d option, images won't be deleted.
update_code_only=false

# Option: -w FOLDER
# HTML working folder (where the HTML file is created and images are saved).
# It will be created if it doesn't exist. Default is the "user/html" folder inside the script folder.
user_html_working_folder="$USER_FOLDER/html"

# Option: -z
# Dry run (simulate image manipulation).
dry_run=false

while getopts ':ac:dfhlor:s:uw:z' opt; do
	case "${opt}" in
		a)
			hide_html_about=true
			;;
		
		c)
			IFS=',' read -ra user_categories <<< "$OPTARG"
			user_categories_txt=$(printf ',%s,' "${user_categories[@]}")
			
			if [[ $user_categories_txt == ",CATEGORIES," ]]; then
				display_categories=true
			fi
			
			;;
		
		d)
			delete_existing_files=true
			;;
		
		f)
			update_gmic_filters=true
			;;
		
		h)
			display_help "$source_image" "$user_html_working_folder"
			
			exit 0
			;;
		
		l)
			disable_log_file_creation=true
			;;
		
		o)
			open_html_file=true
			;;
		
		r)
			new_size="$OPTARG"
			;;
		
		s)
			source_image="$OPTARG"
			;;
		
		u)
			update_code_only=true
			;;
		
		w)
			user_html_working_folder="$OPTARG"
			;;
		
		z)
			dry_run=true
			;;
		
		*)
			echo_err "Option $OPTARG unknown"
			
			exit 1
			;;
	esac
done

################################################################################
## @title Constants (2 of 2)
################################################################################

DRY_RUN=$dry_run

declare -r DRY_RUN

################################################################################
## @title Testing for errors
################################################################################

log_warnings=""

# G'MIC config folder
#####################

gmic_config_folder=$(gmic -v 0 +echo[] \$_path_rc)

if [[ ${gmic_config_folder: -1} == / ]]; then
	gmic_config_folder=${gmic_config_folder::-1}
fi

if [[ ! -d $gmic_config_folder ]]; then
	echo_err "G'MIC config folder not found: $gmic_config_folder"
	
	exit 1
fi

# G'MIC update file
###################

gmic_version=$(gmic -v 0 +echo[] \$_version)

if [[ -z $gmic_version ]]; then
	echo_err "Can't get G'MIC version"
	
	exit 1
fi

gmic_update_filename="update${gmic_version}.gmic"
gmic_update_file="$gmic_config_folder/$gmic_update_filename"

if [[ ! -f $gmic_update_file ]]; then
	curl -L "https://gmic.eu/plain_$gmic_update_filename" -o "$gmic_update_file"
	
	if [[ ! -f $gmic_update_file ]]; then
		echo_err "G'MIC update file not found: $gmic_update_file"
		
		exit 1
	fi
fi

# Custom commands file
######################

custom_commands_file="$SCRIPT_FOLDER/jpfleury.gmic"

if [[ ! -f $custom_commands_file ]]; then
	echo_err "Custom commands file not found: $custom_commands_file"
	
	exit 1
fi

# G'MIC filters file
####################

data_folder="$SCRIPT_FOLDER/data"
user_data_folder="$USER_FOLDER/data"

filters_file="$data_folder/filters.tsv"
user_filters_file="$user_data_folder/filters.tsv"
custom_filters_file="$user_data_folder/custom-filters.tsv"

user_gmic_update_file_json="$user_data_folder/update${gmic_version}.json"

if [[ $update_gmic_filters == true ]]; then
	# Other files that might be worth checking manually:
	#curl -L "https://gmic.eu/gui_filters.txt" -o "$user_data_folder/gui_filters.txt"
	#curl -L "https://gmic.eu/plain_$gmic_update_filename" -o "$user_data_folder/$gmic_update_filename"
	
	if [[ ! -f $user_gmic_update_file_json ]]; then
		curl -L "https://gmic.eu/update${gmic_version}.json" -o "$user_gmic_update_file_json"
		
		if [[ ! -f $user_gmic_update_file_json ]]; then
			echo_err "G'MIC update file in JSON not found: $user_gmic_update_file_json"
			
			exit 1
		fi
	fi
	
	echo $'filter_name\tfilter_command\targuments\tcustomized\tmore_options_txt\tlayers' > "$user_filters_file"
	jq -r '
		.categories[]
		| .name as $cat
		| .filters[]
		| [
			"\($cat) / \(.name)",         # Column 1: filter_name
			.command,                     # Column 2: filter_command
			(
				.parameters
				| map(select(
					has("pos")
					and (
					has("default")
					or has("alignment")
					or has("position")
					or has("value")
					or has("name")
					)
				))
				| sort_by(.pos)
				| map(
					( if has("default") then .default
					elif has("alignment") then .alignment
					elif has("position") then .position
					elif has("value") then .value
					elif has("name") then .name
					end
					) | tostring as $v
					| if ($v | test("\\s"))
					then "\"\($v)\""
					else $v
					end
				)
				| join(",")
			),                            # Column 3: arguments
			( .customized // "DEFAULT" ), # Column 4: customized
			( .more_options // "NULL" ),  # Column 5: more_options
			( .layers // "STATIC" )       # Column 6: layers
			]
		| @tsv
	' "$user_gmic_update_file_json" >> "$user_filters_file"
fi

if [[ -f $custom_filters_file ]]; then
	filters_file=$custom_filters_file
elif [[ -f $user_filters_file ]]; then
	filters_file=$user_filters_file
fi

if [[ ! -f $filters_file ]]; then
	echo_err "G'MIC filters file not found: $filters_file"
	
	exit 1
fi

# Display categories (if applicable)
####################################

if [[ $display_categories == true ]]; then
	echo "Here is the list of all available categories:$N"
	
	grep -v '^filter_name' "$filters_file" | cut -d '/' -f1 | sed 's/[[:space:]]\+$//' | sort -u
	
	exit 0
fi

# Nb of filters
###############

nb_of_filters=0

while IFS=$'\t\n' read -r filter_name filter_command; do
	category_name=$(get_category_name "$filter_name")
	
	if ! keep_filter "$filter_name" "$filter_command" "$category_name" "$user_categories_txt"; then
		continue
	fi
	
	((nb_of_filters++))
done < "$filters_file"

if [[ $nb_of_filters == 0 ]]; then
	echo_err "No filters set in the G'MIC filters file: $filters_file"
	
	exit 1
fi

# HTML working folder
#####################

mkdir -p "$user_html_working_folder"

if [[ ! -d $user_html_working_folder ]]; then
	echo_err "HTML working folder not found: $user_html_working_folder"
	
	exit 1
fi

data_skeleton_folder="$SCRIPT_FOLDER/data/skeleton"

if [[ ! -d $data_skeleton_folder ]]; then
	echo_err "Data skeleton folder not found: $data_skeleton_folder"
	
	exit 1
fi

if [[ $delete_existing_files == true ]]; then
	for file in "$data_skeleton_folder"/*; do
		filename=$(basename "$file")
		user_filepath="$user_html_working_folder/$filename"
		
		if [[ -e $user_filepath && ($update_code_only == false || $filename != "images") ]]; then
			if ! rm -rf "${user_filepath:?}"; then
				log_warnings+="WARNING: Can't delete file: ${user_filepath}${N}${N}"
			fi
		fi
	done
fi

if ! (
	cd "$data_skeleton_folder" || exit 1
	tar --exclude='.gitkeep' -cf - . | tar -xf - -C "$user_html_working_folder"
); then
	echo_err "Can't create files inside the HTML working folder: $user_html_working_folder"
	
	exit 1
fi

if [[ $disable_log_file_creation == true ]]; then
	if ! rm -f "$user_html_working_folder/log"; then
		log_warnings+="WARNING: Can't delete file: $user_html_working_folder/log${N}${N}"
	fi
fi

# Source image
##############

if [[ ! -f $source_image ]]; then
	echo_err "Source image not found: $source_image"
	
	exit 1
fi

source_image_filename=$(basename "$source_image")
source_image_clean_filename=$(clean_filename "$source_image_filename")
user_source_image="$user_html_working_folder/images/$source_image_clean_filename"

# Useful only with option -u
if [[ -e $user_source_image ]]; then
	user_source_image_already_exists=true
else
	user_source_image_already_exists=false
fi

if [[ $update_code_only == false || $user_source_image_already_exists == false ]]; then
	if ! cp "$source_image" "$user_source_image"; then
		echo_err "Source image \"$source_image\" can't be copied into the HTML working folder \"$user_html_working_folder/images\""
		
		exit 1
	fi
fi

source_image=$user_source_image

if [[ -n $new_size && ($update_code_only == false || $user_source_image_already_exists == false) ]]; then
	source_image_ext=".${source_image##*.}"
	source_image_settings=""
	
	if [[ $source_image_ext == "$static_ext" ]]; then
		source_image_settings=$static_ext_settings
	elif [[ $source_image_ext == "$merge_ext" ]]; then
		source_image_settings=$merge_ext_settings
	elif [[ $source_image_ext == "$append_ext" ]]; then
		source_image_settings=$append_ext_settings
	fi
	
	if ! gmic -i "$source_image" -resize "$new_size" -o "${source_image}${source_image_settings}" &> /dev/null; then
		echo_err "The source image can't be resized: $source_image"
		
		exit 1
	fi
fi

################################################################################
## @title Parsing filters
################################################################################

# HTML file content
all_filters_html=""
filter_category_list=()
filter_category_list_txt=""

# Log
user_log_file="$user_html_working_folder/log.txt"
log_time=""
log_command_lines=""
log_errors=""

# To calculate the script's running time
time1=$(date +"%s%N")

i=1

while IFS=$'\t\n' read -r filter_name filter_command arguments customized more_options layers; do
	category_name=$(get_category_name "$filter_name")
	
	if ! keep_filter "$filter_name" "$filter_command" "$category_name" "$user_categories_txt"; then
		continue
	fi
	
	# Argument sanitization
	#######################
	
	if [[ $arguments == "NULL" ]]; then
		arguments=""
	fi
	
	if [[ $more_options == "NULL" ]]; then
		more_options=""
	fi
	
	# Output image path
	###################
	
	# Checksum added to the filename as an ID (the filename would be too long if arguments were used).
	# The checksum is also used as an anchor in the HTML file.
	id=$(checksum "$filter_command $arguments $more_options")
	
	output_image_filename=$(clean_filename "$filter_name")-$id
	user_output_image="$user_html_working_folder/images/$output_image_filename"
	user_output_image_anim_static=""
	
	# Output image file type
	
	if [[ $layers == "ANIMATED" ]]; then
		user_output_image+=$anim_ext
		
		ext_settings=$anim_ext_settings
		
		user_output_image_anim_static=${user_output_image}${static_ext}
		
		more_options+=" -o[0%] ${user_output_image_anim_static}${static_ext_settings}"
	elif [[ $layers == "APPEND" ]]; then
		user_output_image+=$append_ext
		
		ext_settings=$append_ext_settings
		
		#more_options+=" -jpf_layer_indice -append y,0.5"
		more_options+=" -jpf_layer_indice"
		more_options+="  -gimp_pack 2,1,1,0,'/tmp/gmic'"
	elif [[ $layers == "MERGE" ]]; then
		user_output_image+=$merge_ext
		
		ext_settings=$merge_ext_settings
		
		more_options+=" -gimp_merge_layers"
	else
		user_output_image+=$static_ext
		
		ext_settings=$static_ext_settings
	fi
	
	# G'MIC invocation
	##################
	
	# shellcheck disable=SC2206
	command_line=(
		gmic
		-m "$gmic_update_file"
		-m "$custom_commands_file"
		-i "$source_image"
		"$filter_command"
		$arguments
		$more_options
		-o "${user_output_image}${ext_settings}"
	)
	
	time_invoc1=$(date +"%s%N")
	timeout_message=""
	
	if [[ $DRY_RUN == false && ($update_code_only == false || ! -e $user_output_image) ]]; then
		if [[ $timeout_duration =~ ^[1-9][0-9]*s$ ]]; then
			timeout "$timeout_duration" "${command_line[@]}" &> /dev/null
			exit_status=$?
			
			if [[ $exit_status == 124 ]]; then
				timeout_message=" (timeout forced after $timeout_duration)"
			fi
		else
			"${command_line[@]}" &> /dev/null
			exit_status=$?
		fi
	else
		exit_status=0
	fi
	
	if [[ $exit_status == 0 && ! -f $user_output_image ]]; then
		user_output_image_base=${user_output_image%.*}
		user_output_image_ext=${user_output_image##*.}
		first_layer=${user_output_image_base}_000000.${user_output_image_ext}
		
		if [[ -f $first_layer ]]; then
			if ! cp "$first_layer" "$user_output_image"; then
				log_warnings+="WARNING: Can't copy image: $first_layer => ${user_output_image}${N}"
			fi
		fi
	fi
	
	time_invoc2=$(date +"%s%N")
	time_invoc=$(nanoseconds_to_seconds $((time_invoc2 - time_invoc1)))
	
	# Log
	#####
	
	log_entry="$filter_name ($i of $nb_of_filters)$N"
	log_entry+=${command_line[*]}${N}
	log_entry+="time: ${time_invoc} s${timeout_message}; exit status: ${exit_status}${N}${N}"
	
	if [[ $exit_status != 0 ]]; then
		if ! rm -f "$user_output_image"; then
			log_warnings+="WARNING: Can't delete image: ${user_output_image}${N}"
		fi
		
		log_errors+=$log_entry
	fi
	
	echo -n "$log_entry"
	
	log_time+=$(generate_time_entry "$time_invoc" "$exit_status" "$filter_name")$N
	log_command_lines+=$log_entry
	
	# HTML file
	###########
	
	if [[ $exit_status == 0 ]]; then
		all_filters_html+=$(generate_image_html "$source_image" "$user_output_image" "$id" \
		                    "$filter_name" "$filter_command" "$arguments" "$customized" \
		                    "$layers" "$user_output_image_anim_static")${N}${N}
		
		if [[ ! $filter_category_list_txt == *",${category_name},"* ]]; then
			filter_category_list+=("$category_name")
			filter_category_list_txt+=",$category_name,"
		fi
	fi
	
	((i++))
done < "$filters_file"

time2=$(date +"%s%N")
time=$(nanoseconds_to_seconds $((time2 - time1)))

################################################################################
## @title Post-parsing
################################################################################

########################################
## @subtitle HTML file
########################################

readarray -t filter_categories_sorted < <(for cat in "${filter_category_list[@]}"; do echo "$cat"; done | sort)
filter_categories_html=""

for cat_name in "${filter_categories_sorted[@]}"; do
	id_cat=$(checksum "$cat_name")
	filter_categories_html+="<button id=\"$id_cat\" class=\"active\" type=\"button\">$cat_name</button>$N"
done

user_html_file="$user_html_working_folder/index.html"
source_image_block=$(generate_image_html "$source_image" "$source_image" "source-image")
source_image_block_selected=$(generate_image_html "$source_image" "$source_image" "source-image-selected")
all_filters_html=${source_image_block}${N}${N}${all_filters_html}

if [[ $hide_html_about == true ]]; then
	class_about_title="fa-square-plus"
	class_about="hide"
else
	class_about_title="fa-square-minus"
	class_about=""
fi

user_tmp_file="$user_html_working_folder/tmp_file.txt"

replace_tag "{{{ALL_FILTERS}}}" "$all_filters_html" "$user_html_file" "$user_tmp_file"
replace_tag "{{{SELECTED_FILTERS}}}" "$source_image_block_selected" "$user_html_file" "$user_tmp_file"
replace_tag "{{{SOURCE_IMAGE_NAME}}}" "$(basename "$source_image")" "$user_html_file" "$user_tmp_file"
replace_tag "{{{CATEGORIES}}}" "$filter_categories_html" "$user_html_file" "$user_tmp_file"
replace_tag "{{{CLASS_ABOUT_TITLE}}}" "$class_about_title" "$user_html_file" "$user_tmp_file"
replace_tag "{{{CLASS_ABOUT}}}" "$class_about" "$user_html_file" "$user_tmp_file"
replace_tag "{{{NB_OF_FILTERS}}}" "$nb_of_filters" "$user_html_file" "$user_tmp_file"

if [[ -e $user_tmp_file ]]; then
	if ! rm -f "$user_tmp_file"; then
		log_warnings+="WARNING: can't delete ${user_tmp_file}${N}${N}"
	fi
fi

if [[ $open_html_file == true ]]; then
	xdg-open "$user_html_file" &
fi

########################################
## @subtitle Log file
########################################

if [[ $disable_log_file_creation == false ]]; then
	# About
	#######
	
	header=$(generate_header "ABOUT")
	info_license=$(display_info_license)
	
	echo "${header}${N}${N}${info_license}${N}${N}Date: $(date)${N}" >> "$user_log_file"
	
	# Running time entries
	######################
	
	header=$(generate_header "RUNNING TIME")
	description="Total running time: $time s${N}${N}"
	description+="Below is the running time (in descending order) of all filters.${N}${N}"
	description+=$(generate_time_entry "TIME (S)" "EXIT STATUS" "FILTER NAME")
	log_time=$(echo -e "$log_time" | sort -nr)
	
	echo "${header}${N}${N}${description}${N}${log_time}${N}" >> "$user_log_file"
	
	# Command line entries
	######################
	
	header=$(generate_header "COMMAND LINES")
	
	echo "${header}${N}${N}${log_command_lines}" >> "$user_log_file"
fi

# Errors
########

if [[ -n $log_errors ]]; then
	header=$(generate_header "ERRORS")
	log_errors=${header}${N}${N}${log_errors}
	
	echo_err "$log_errors" false
	
	if [[ $disable_log_file_creation == false ]]; then
		echo "$log_errors" >> "$user_log_file"
	fi
fi

# Warnings
##########

if [[ -n $log_warnings ]]; then
	header=$(generate_header "WARNINGS")
	log_warnings=${header}${N}${N}${log_warnings}
	
	echo_err "$log_warnings" false
	
	if [[ $disable_log_file_creation == false ]]; then
		echo "$log_warnings" >> "$user_log_file"
	fi
fi

exit $?
