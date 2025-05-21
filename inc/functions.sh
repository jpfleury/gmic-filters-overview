# shellcheck shell=bash

# Print checksum of the value passed as parameter
checksum() {
	local value=$1
	
	# --------------------
	
	echo -n "$value" | shasum -a 256 | cut -c 1-12
}

# Delete or replace characters in a filename so it can be used in the terminal
# without needing quotes or escaping.
clean_filename() {
	local filename=$1
	
	local new_filename
	
	# --------------------
	
	new_filename=$(echo -n "$filename" | LC_ALL=C sed -E '
		s/[^a-zA-Z0-9._ -]//g;
		s/ +/-/g;
		s/^[^a-zA-Z0-9]+//;
		s/[^a-zA-Z0-9]+$//;
	')

	if [[ -z $new_filename ]]; then
		new_filename=$(echo -n "$filename" | sha256sum | cut -c 1-12)
	fi

	echo -n "$new_filename"
}

# Display all command line options.
display_help() {
	local source_image=$1
	local html_working_folder=$2
	
	# --------------------
	
	display_info_license
	echo
	cat <<-TXT
	${BOLD}USER OPTIONS${DEFAULT}
	  -a             Hide "About" section in the HTML file.
	  -c CATEGORIES  Restrict filter categories to the specified list.
	                 Categories must be separated by commas. Category names
	                 containing spaces must be quoted. If set to "CATEGORIES",
	                 the list of possible choices will be displayed.
	  -d             Delete existing files inside the HTML working folder.
	  -f             Update G'MIC filters.
	  -h             Show help options.
	  -o             Open the HTML file after generating it.
	  -r SIZE        Resize the source image before applying filters.
	                 The source image is not modified. A copy is created.
	  -s IMAGE       Use IMAGE as the source image. Default is
	                 $source_image
	  -w FOLDER      Use FOLDER as the HTML working folder. Default is
	                 $html_working_folder
	  -z             Dry run (simulate image manipulation).

	${BOLD}EXAMPLES${DEFAULT}
	  -r 750,500
	  -r 50%,50%
	  -c CATEGORIES # Display all available categories
	  -c Colors
	  -c Colors,Deformations
	  -c "Arrays & tiles",Colors

	${BOLD}DEV OPTIONS${DEFAULT}
	  -l             Disable log file creation.
	  -u             Update code only without regenerating images.
	                 If used with the -d option, images won't be deleted.
	
	TXT
}

# Display quick information about gmic-filters-overview.
display_info_license() {
	cat <<-TXT
	gmic-filters-overview: Apply all G'MIC filters to an image and browse the results in HTML.
	For more information, visit <https://github.com/jpfleury/gmic-filters-overview>.
	
	Copyright © 2015, 2025 Jean-Philippe Fleury
	
	This program comes with ABSOLUTELY NO WARRANTY. This is free software
	(GPLv3+), and you are welcome to redistribute it and/or modify it under
	certain conditions (see file COPYING).
	TXT
}

echo_err() {
	local message=$1
	local add_prefix=${2:-true}
	
	# --------------------
	
	if [[ $add_prefix == true ]]; then
		message="ERROR: $message"
	fi
	
	echo "$message" >&2
}

keep_filter() {
	local filter_name=$1
	local filter_command=$2
	local category_name=$3
	local categories_txt=$4
	
	# --------------------
	
	# filter_name
	#############
	
	if [[ -z $filter_name || ${filter_name:0:1} == "#" ]]; then
		return 1
	fi
	
	if [[ $filter_name == "filter_command" ]]; then
		return 1
	fi
	
	# filter_command
	################
	
	if [[ $filter_command == "_none_" || $filter_command == "fx_puzzle" ]]; then
		return 1
	fi
	
	# categories
	############
	
	if [[ -n $categories_txt && $categories_txt != *",$category_name,"* ]]; then
		return 1
	fi

	return 0
}

# Generate a header to be used as a separator, for example in the log file.
generate_header() {
	local title=$1
	
	# --------------------
	
	cat <<-TXT
	############################################################
	##
	## $title
	##
	############################################################
	TXT
}

# Generate the HTML code used to display an image.
generate_image_html() {
	local source_image=$1
	local image_file=$2
	local id=$3
	local filter_name=$4
	local filter_command=$5
	local arguments=$6
	local customized=$7
	local layers=$8
	local dest_image_anim_static=$9
	
	# --------------------
	
	src="images/$(basename "$image_file")"
	data_src=$src
	data_src_static=""
	controls=""
	filter_name_suppl=""
	
	if [[ $layers == "ANIMATED" ]]; then
		data_src_static="images/$(basename "$dest_image_anim_static")"
		src=$data_src_static
		controls='<span class="controls fa-solid fa-play" title="Play"></span>'
	fi
	
	if [[ $DRY_RUN == true ]]; then
		size=(0 0)
	else
		read -r -a size < <(gmic -v 0 - -i "$image_file" +echo[] '{w}"' '"{h}' -q)
	fi
	
	if [[ $image_file == "$source_image" ]]; then
		filter_name="Source image"
		information="No command (source image)"
		disabled_compare="disabled"
		disabled_select="disabled"
		disabled_compare_title=" (disabled)"
		disabled_select_title=" (disabled)"
	else
		if [[ $customized == "CUSTOM" ]]; then
			filter_name_suppl='*'
			information='<code class="custom">'
		else
			information='<code>'
		fi
		
		information+="$filter_command $arguments</code>"
		disabled_compare=""
		disabled_select=""
		disabled_compare_title=""
		disabled_select_title=""
		
		# We compare the image width and height with those of the source image.
		# If there's a difference of more than four pixels in either width or
		# height, the comparison between these two images is disabled. We can't just
		# check for exact dimensions, because sometimes the output image is just
		# slightly smaller or larger than the source image. For example, the
		# source image may be 250x167 and the output image 250x168.
		
		read -r -a size_source < <(gmic -v 0 - -i "$source_image" +echo[] '{w}"' '"{h}' -q)
		
		diff_width=$(( size[0] - size_source[0] ))
		diff_width=${diff_width/#-/} # abs
		diff_height=$(( size[1] - size_source[1] ))
		diff_height=${diff_height/#-/} # abs
		
		if [[ ! $diff_width =~ ^[0-4]$ || ! $diff_height =~ ^[0-4]$ ]]; then
			disabled_compare=" disabled"
			disabled_compare_title=" (disabled)"
		fi
	fi
	
	read -r -d '' html <<-HTML
		<li id="$id">
			<figure>
				<p class="image"><img src="$src" width="${size[0]}" data-src="$data_src" data-src-static="$data_src_static" height="${size[1]}" alt="$filter_name" /></p>
				
				<figcaption>
					<p class="filter-name">$filter_name$filter_name_suppl</p>
					
					<ul class="menu-image">
						<li class="anchor-container"><a href="#$id"><span class="anchor fa-fw fa-solid fa-anchor" title="Link to this image"></span></a></li>
						<li class="new-tab-container"><a href="$data_src" target="_blank"><span class="new-tab fa-fw fa-solid fa-arrow-up-right-from-square" title="Open in a new tab"></span></a></li>
						
						<li class="sep reorder-container"><span class="reorder fa-fw fa-solid fa-arrows-up-down-left-right" title="Reorder the image using drag and drop"></span></li>
						
						<li class="display-style-container"><span class="display-style fa-fw fa-solid fa-expand" title="Toggle default/large display"></span></li>
						<li class="info-container"><span class="info fa-fw fa-solid fa-circle-chevron-down" title="Toggle info display"></span></li>
						<li class="compare-container"><span class="compare fa-fw fa-solid fa-eye $disabled_compare" title="Toggle source image comparison$disabled_compare_title"></span></li>
						<li class="select-container"><span class="select fa-fw fa-regular fa-square $disabled_select" title="Toggle selection$disabled_select_title"></span></li>
					</ul>
					
					<p class="more-info hide">$information</p>
					
					$controls
				</figcaption>
			</figure>
		</li>
	HTML
	
	echo "$html"
}

# Generate a running time entry to be added in the log file.
generate_time_entry() {
	local running_time=$1
	local exit_status=$2
	local filter_name=$3
	
	local entry
	
	# --------------------
	
	entry=$(printf '%-11s' "$running_time")
	entry+=$(printf '%-14s' "$exit_status")
	entry+=${filter_name}${N}
	
	echo "$entry"
}

get_category_name() {
	local filter_name=$1
	
	local category_name
	
	# --------------------
	
	category_name=${filter_name%%/*}
	category_name=${category_name%"${category_name##*[![:space:]]}"}
	
	echo -n "$category_name"
}

# Convert nanoseconds to seconds (leading zero, with three decimal places).
nanoseconds_to_seconds() {
	local nanoseconds=$1
	
	local seconds
	
	# --------------------
	
	seconds=$(echo "scale = 3; x = $nanoseconds / 1000000000; if (x < 1) print 0; x" | bc)
	
	if [[ $seconds == "00" ]]; then
		seconds=0
	fi
	
	echo "$seconds"
}

# Replace a tag in a file with the specified content.
replace_tag() {
	local tag=$1
	local content=$2
	local file=$3
	local tmp_file=$4
	
	local n nb_of_lines
	
	# --------------------
	
	# Escape the special character "&" for awk.
	content=${content//&/\\\&}
	
	# Put the content in a temporary file, then use the file to replace the tag.
	# We can't pass the content directly to awk as a command-line argument,
	# because very long strings would cause an "Argument list too long" error.
	echo -e "$content" > "$tmp_file"
	
	nb_of_lines=$(wc -l < "$tmp_file")
	
	if (( nb_of_lines > 1 )); then
		n="\n"
	else
		n=""
	fi
	
	awk -i inplace -v f="$tmp_file" "BEGIN {
		while (getline < f) txt=txt \$0 \"$n\"
	} /$tag/ {
		sub(\"$tag\", txt)
	} 1" "$file"
}
