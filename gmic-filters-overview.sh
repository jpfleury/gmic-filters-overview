#!/bin/bash

# gmic-filters-overview: Apply all G'MIC filters to an image and view
# results in HTML
# Author: Jean-Philippe Fleury (<http://www.jpfleury.net/en/contact.php>)
# Copyright © 2015 Jean-Philippe Fleury

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

########################################################################
##
## Inclusions
##
########################################################################

# Absolute parent folder of the script.
script_folder=$(dirname "$(readlink -f "$0")")

source "$script_folder/inc/functions.sh"
source "$script_folder/inc/config.sh"

if [[ -d "$script_folder/inc/config-custom.sh" ]]; then
	source "$script_folder/inc/config-custom.sh"
fi

########################################################################
##
## Command line options
##
########################################################################

# Option: -a
# If TRUE, About section is hidden by default in the HTML file.
hide_html_about="FALSE"

# Option: -c
# Restrict filter categories to the specified list. If empty, all
# categories are used.
categories=()

# Option: -d
# If TRUE, delete existing files inside the working folder.
delete_existing_files="FALSE"

# Option: -l
# If TRUE, don't create the log file.
disable_log_file_creation="FALSE"

# Option: -o
# If TRUE, open the HTML file after generating it.
open_html_file="FALSE"

# Option: -r
# Resize the source image before applying filters. The source image is not
# modified. A copy is created. Default is no resizing.
new_size=""

# Option: -s FILE
# Source image. Default is the sample image shipped with the script.
source_image="$script_folder/data/sample.jpg"

# Option: -u
# If TRUE, update code only without regenerating images. If used with
# option -d, images won't be deleted.
update_code_only="FALSE"

# Option: -w FOLDER
# Working folder (where the HTML file is created and images are saved).
# It will be created if it doesn't exist. Default is a folder named "_HTML_"
# in the script folder.
working_folder="$script_folder/_HTML_"

while getopts ':ac:dhlnor:s:uw:' opt; do
	case "${opt}" in
		a) hide_html_about="TRUE" ;;
		c) IFS=',' read -ra categories <<< "$OPTARG" ;;
		d) delete_existing_files="TRUE" ;;
		h) display_help "$source_image" "$working_folder"
		   exit 0 ;;
		l) disable_log_file_creation="TRUE" ;;
		n) new_filters
		   exit 0 ;;
		o) open_html_file="TRUE" ;;
		r) new_size="$OPTARG" ;;
		s) source_image="$OPTARG" ;;
		u) update_code_only="TRUE" ;;
		w) working_folder="$OPTARG" ;;
		*) echo "ERROR: option $OPTARG unknown" >&2
		   exit 1 ;;
	esac
done

########################################################################
##
## Testing for errors
##
########################################################################

log_warnings=""

# G'MIC config folder.

config_folder=$(gmic -v - -echo_stdout[] \$_path_rc)

if [[ $config_folder =~ '/'$ ]]; then
	# Delete trailing slash.
	config_folder=${config_folder::-1}
fi

if [[ ! -d $config_folder ]]; then
	echo "ERROR: G'MIC config folder not found ($config_folder)" >&2
	exit 1
fi

# Update file.

update_file="$config_folder/cli_update"
update_file+=$(gmic -v - -echo_stdout[] \$_version)
update_file+=".gmic"

if [[ ! -f $update_file ]]; then
	echo "ERROR: update file not found ($update_file). Try to run \"gmic --update\" on the command line." >&2
	exit 1
fi

# Custom commands file.

custom_commands_file="$script_folder/jpfleury.gmic"

if [[ ! -f $custom_commands_file ]]; then
	echo "ERROR: custom commands file not found ($custom_commands_file)" >&2
	exit 1
fi

# FIlters file.

filters_file="$script_folder/data/filters.tsv"

if [[ ! -f $filters_file ]]; then
	echo "ERROR: filters file not found ($filters_file)" >&2
	exit 1
fi

number_of_filters=0

while IFS=$'\t\n' read -r filter_name others; do
	if [[ $filter_name =~ ^# || $filter_name == "" ]]; then
		# Empty line or comment. Ignoring it.
		continue
	fi
	
	category_name=$(echo "$filter_name" | cut -d'/' -f1 | sed -e 's/[[:space:]]*$//')
	
	if [[ ${#categories[@]} > 0 && ! " ${categories[@]} " =~ " ${category_name} " ]]; then
		# The filter is not classed in a category specified by the user.
		# Ignoring it.
		continue
	fi
	
	((number_of_filters++))
done < "$filters_file"

if [[ $number_of_filters == 0 ]]; then
	echo "ERROR: no filters set in the filters file ($filters_file)" >&2
	exit 1
fi

# Working folder.

mkdir -p "$working_folder"

if [[ ! -d $working_folder ]]; then
	echo "ERROR: working folder not found ($working_folder)" >&2
	exit 1
fi

skeleton_folder="$script_folder/data/skeleton"

if [[ ! -d $skeleton_folder ]]; then
	echo "ERROR: skeleton folder not found ($skeleton_folder)" >&2
	exit 1
fi

if [[ $delete_existing_files == "TRUE" ]]; then
	for file in "$skeleton_folder"/*; do
		filename=$(basename "$file")
		
		if [[ -e "$working_folder/$filename" && \
		      ($update_code_only == "FALSE" || $filename != "images") ]]; then
			rm -rf "$working_folder/$filename"
			
			if [[ $? != 0 ]]; then
				log_warnings+="WARNING: can't delete $working_folder/$filename\n\n"
			fi
		fi
	done
fi

cp -r "$skeleton_folder/." "$working_folder"

if [[ $? != 0 ]]; then
	echo "ERROR: can't create files inside the working folder ($working_folder)" >&2
	exit 1
fi

if [[ $disable_log_file_creation == "TRUE" ]]; then
	rm -f "$working_folder/log"
	
	if [[ $? != 0 ]]; then
		log_warnings+="WARNING: can't delete $working_folder/log\n\n"
	fi
fi

# Source image.

if [[ ! -f $source_image ]]; then
	echo "ERROR: source image not found ($source_image)" >&2
	exit 1
fi

source_filename=$(basename "$source_image")
source_clean_filename=$(clean_filename "$source_filename")
source_image_working_folder="$working_folder/images/$source_clean_filename"

# Useful only with option -u.
if [[ -e $source_image_working_folder ]]; then
	# Image "$source_image_working_folder" already exists.
	siwf_already_exists="TRUE"
else
	siwf_already_exists="FALSE"
fi

if [[ $update_code_only == "FALSE" || $siwf_already_exists == "FALSE" ]]; then
	cp "$source_image" "$source_image_working_folder"
	
	if [[ $? != 0 ]]; then
		echo "ERROR: source image ($source_image) can't be copied in the working folder" >&2
		exit 1
	fi
fi

source_image=$source_image_working_folder

if [[ -n $new_size && ($update_code_only == "FALSE" || $siwf_already_exists == "FALSE") ]]; then
	source_image_ext=".${source_image##*.}"
	source_image_settings=""
	
	if [[ $source_image_ext == $static_ext ]]; then
		source_image_settings=$static_ext_settings
	elif [[ $source_image_ext == $merge_ext ]]; then
		source_image_settings=$merge_ext_settings
	elif [[ $source_image_ext == $append_ext ]]; then
		source_image_settings=$append_ext_settings
	fi
	
	gmic -i "$source_image" -resize "$new_size" -o "$source_image$source_image_settings" &> /dev/null
	
	if [[ $? != 0 ]]; then
		echo "ERROR: source image ($source_image) can't be resized" >&2
		exit 1
	fi
fi

########################################################################
##
## Parsing filters
##
########################################################################

# HTML file content.
all_filters_html=""
category_list=()

# Log
log_file="$working_folder/log"
log_time=""
log_command_lines=""
log_errors=""

# To calculate the running time of the script.
time1=$(date +"%s%N")

i=1

while IFS=$'\t\n' read -r filter_name filter_command arguments \
                          customized more_options layers; do
	if [[ $filter_name =~ ^# || $filter_name == "" ]]; then
		# Empty line or comment. Ignoring it.
		continue
	fi
	
	category_name=$(echo "$filter_name" | cut -d'/' -f1 | sed -e 's/[[:space:]]*$//')
	
	if [[ ${#categories[@]} > 0 && ! " ${categories[@]} " =~ " ${category_name} " ]]; then
		# The filter is not classed in a category specified by the user.
		# Ignoring it.
		continue
	fi
	
	if [[ $arguments == "NULL" ]]; then
		arguments=""
	fi
	
	if [[ $more_options == "NULL" ]]; then
		more_options=""
	fi
	
	####################################
	# Output image path
	####################################
	
	# Checksum added to the filename as an ID (the filename would be too long if
	# arguments were added). The checksum is also used as an anchor in the HTML file.
	id=$(checksum "$filter_command $arguments $more_options")
	
	output_image="$filter_name-"
	output_image+=$id
	output_image=$(clean_filename "$output_image")
	output_image="$working_folder/images/$output_image"
	output_image_anim_static=""
	
	# Output image file type.
	if [[ $layers == "ANIMATED" ]]; then
		output_image+=$anim_ext
		ext_settings=$anim_ext_settings
		output_image_anim_static="$output_image$static_ext"
		more_options+=" -o[0%] $output_image_anim_static$static_ext_settings"
	elif [[ $layers == "APPEND" ]]; then
		output_image+=$append_ext
		ext_settings=$append_ext_settings
		#more_options+=" -jpf_layer_indice -append y,0.5"
		more_options+=" -jpf_layer_indice -gimp_pack 2,1,1,0,'/tmp/gmic'"
	elif [[ $layers == "MERGE" ]]; then
		output_image+=$merge_ext
		ext_settings=$merge_ext_settings
		more_options+=" -gimp_merge_layers"
	else
		output_image+=$static_ext
		ext_settings=$static_ext_settings
	fi
	
	####################################
	# gmic invocation
	####################################
	
	command_line="gmic -m $update_file -m $custom_commands_file -i $source_image $filter_command $arguments $more_options -o $output_image$ext_settings"
	
	time_invoc1=$(date +"%s%N")
	
	if [[ $update_code_only == "FALSE" || ! -e $output_image ]]; then
		$command_line &> /dev/null
	fi
	
	exit_status=$?
	time_invoc2=$(date +"%s%N")
	
	time_invoc=$(nanoseconds_to_seconds $((time_invoc2-time_invoc1)))
	
	####################################
	# Log
	####################################
	
	title="$filter_name ($i from $number_of_filters)"
	
	log_entry="$title\n$command_line\n"
	log_entry+="time: $time_invoc s; exit status: $exit_status\n\n"
	
	if [[ $exit_status != 0 ]]; then
		rm -f "$output_image"
		
		if [[ $? != 0 ]]; then
			log_warnings+="WARNING: can't delete $output_image\n\n"
		fi
		
		log_errors+="$log_entry"
	fi
	
	echo -en "$log_entry"
	
	log_time+=$(generate_time_entry "$time_invoc" "$exit_status" "$filter_name")
	log_time+="\n"
	log_command_lines+=$log_entry
	
	####################################
	# HTML file
	####################################
	
	if [[ $exit_status == 0 ]]; then
		all_filters_html+=$(generate_image_html "$source_image" "$output_image" "$id" \
		                    "$filter_name" "$filter_command" "$arguments" "$customized" \
		                    "$layers" "$output_image_anim_static")
		all_filters_html+="\n\n"
		
		if [[ ! " ${category_list[@]} " =~ " ${category_name} " ]]; then
			category_list+=("$category_name")
		fi
	fi
	
	((i++))
done < "$filters_file"

time2=$(date +"%s%N")
time=$(nanoseconds_to_seconds $((time2-time1)))

########################################################################
##
## Post-parsing
##
########################################################################

####################################
# Filling out the HTML file
####################################

readarray -t categories_sorted < <(for cat in "${category_list[@]}"; do echo "$cat"; done | sort)
categories_html=""

for cat_name in "${categories_sorted[@]}"; do
	id_cat=$(checksum "$cat_name")
	categories_html+="<button id=\"$id_cat\" class=\"active\" type=\"button\">$cat_name</button>\n"
done

html_file="$working_folder/index.html"
source_image_block=$(generate_image_html "$source_image" "$source_image" "source-image")
source_image_block_selected=$(generate_image_html "$source_image" "$source_image" \
                              "source-image-selected")
all_filters_html="$source_image_block\n\n$all_filters_html"

if [[ $hide_html_about == "TRUE" ]]; then
	class_about_title="fa-plus-square-o"
	class_about="hide"
else
	class_about_title="fa-minus-square-o"
	class_about=""
fi

tmp_file="$working_folder/tmp_file"

replace_tag "{{{ALL_FILTERS}}}" "$all_filters_html" "$html_file" "$tmp_file"
replace_tag "{{{SELECTED_FILTERS}}}" "$source_image_block_selected" "$html_file" "$tmp_file"
replace_tag "{{{SOURCE_IMAGE_NAME}}}" "$(basename "$source_image")" "$html_file" "$tmp_file"
replace_tag "{{{CATEGORIES}}}" "$categories_html" "$html_file" "$tmp_file"
replace_tag "{{{CLASS_ABOUT_TITLE}}}" "$class_about_title" "$html_file" "$tmp_file"
replace_tag "{{{CLASS_ABOUT}}}" "$class_about" "$html_file" "$tmp_file"
replace_tag "{{{NUMBER_OF_FILTERS}}}" "$number_of_filters" "$html_file" "$tmp_file"

if [[ -e $tmp_file ]]; then
	rm -f "$tmp_file"
	
	if [[ $? != 0 ]]; then
		log_warnings+="WARNING: can't delete $tmp_file\n\n"
	fi
fi

if [[ $open_html_file == "TRUE" ]]; then
	xdg-open "$html_file" &
fi

####################################
# Filling out the log file
####################################

if [[ $disable_log_file_creation == "FALSE" ]]; then
	# About.
	header=$(generate_header "ABOUT")
	info_license=$(display_info_license)
	echo -e "$header\n\n$info_license\n\nDate: $(date)\n" >> "$log_file"
	
	# Running time entries.
	header=$(generate_header "RUNNING TIME")
	description="Total running time: $time s\n\n"
	description+="Below is the running time (in descending order) of all filters.\n\n"
	description+=$(generate_time_entry "TIME (S)" "EXIT STATUS" "FILTER NAME")
	log_time=$(echo -e "$log_time" | sort -nr) # Descending order.
	echo -e "$header\n\n$description\n$log_time\n" >> "$log_file"
	
	# Command line entries.
	header=$(generate_header "COMMAND LINES")
	echo -e "$header\n\n$log_command_lines" >> "$log_file"
fi

# Errors.
if [[ -n $log_errors ]]; then
	header=$(generate_header "ERRORS")
	log_errors="$header\n\n$log_errors"
	# Output to stderr and add in the log file.
	echo -e "$log_errors" >&2
	
	if [[ $disable_log_file_creation == "FALSE" ]]; then
		echo -e "$log_errors" >> "$log_file"
	fi
fi

# Warnings.
if [[ -n $log_warnings ]]; then
	header=$(generate_header "WARNINGS")
	log_warnings="$header\n\n$log_warnings"
	# Output to stderr and add in the log file.
	echo -e "$log_warnings" >&2
	
	if [[ $disable_log_file_creation == "FALSE" ]]; then
		echo -e "$log_warnings" >> "$log_file"
	fi
fi

####################################
# That's it. :-)
####################################

exit $?
