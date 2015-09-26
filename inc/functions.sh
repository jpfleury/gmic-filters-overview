# Print checksum (10 digits) of the string passed as parameter.
checksum()
{
	string=$1
	
	echo -n "$string" | cksum | cut -d' ' -f1
}

# Delete or replace characters in a filename so it can be used in a terminal
# without quoting or escaping anything.
clean_filename()
{
	filename=$1
	
	echo -n "$filename" | sed -r 's/[^a-zA-Z0-9\.]+/-/g'
}

# Display all command line options.
display_help()
{
	source_image=$1
	working_folder=$2
	
	bold=$(tput bold)
	normal=$(tput sgr0)
	
	display_info_license
	echo ""
	echo "${bold}USER OPTIONS${normal}
  -a               Hide About section in the HTML file.
  -c CATEGORIES    Restrict filter categories to the list specified.
                   Must be separated by comma. Category names containing
                   spaces must be quoted. List: Arrays & tiles,
                   Artistic, Black & white, Colors, Contours,
                   Deformations, Degradations, Details, Film emulation,
                   Frames, Frequencies, Layers, Lights & shadows,
                   Patterns, Rendering, Repair, Sequences, Stereoscopic 3d,
                   Testing, Various
  -d               Delete existing files inside the working folder.
  -h               Show help options.
  -o               Open the HTML file after generating it.
  -r SIZE          Resize the source image before applying filters.
                   The source image is not modified. A copy is created.
  -s IMAGE         Use IMAGE as the source image. Default is
                   $source_image
  -w FOLDER        Use FOLDER as the working folder. Default is
                   $working_folder

${bold}EXAMPLES${normal}
  -r 750,500
  -r 50%,50%
  -c Colors
  -c Colors,Deformations
  -c \"Arrays & tiles\",Colors

${bold}DEV OPTIONS${normal}
  -l               Disable log file creation.
  -n               List new filters not added in \"filters.tsv\" yet.
  -u               Update code only without regenerating images.
                   If used with option -d, images won't be deleted.
"
}

# Display quick information about gmic-filters-overview.
display_info_license()
{
	echo "gmic-filters-overview: apply all G'MIC filters to an image and view
results in HTML
Copyright © 2015 Jean-Philippe Fleury
This program comes with ABSOLUTELY NO WARRANTY. This is free software
(GPLv3+), and you are welcome to redistribute it and/or modify it under
certain conditions (see file COPYING)."
}

# Generate a header to be used as separator, for example in the log file.
generate_header()
{
	title=$1
	
	header="############################################################\n"
	header+="##\n"
	header+="## $title\n"
	header+="##\n"
	header+="############################################################"
	echo -e "$header"
}

# Generate the HTML code used to display an image.
generate_image_html()
{
	source_image=$1
	image_file=$2
	id=$3
	filter_name=$4
	filter_command=$5
	arguments=$6
	customized=$7
	layers=$8
	dest_image_anim_static=$9
	
	src="images/$(basename "$image_file")"
	data_src=$src
	data_src_static=""
	controls=""
	filter_name_suppl=""
	
	if [[ $layers == "ANIMATED" ]]; then
		data_src_static="images/$(basename "$dest_image_anim_static")"
		src=$data_src_static
		controls='<span class="controls fa fa-play" title="Play"></span>'
	fi
	
	size=($(gmic -v - -i "$image_file" -echo_stdout[] {w}\" \"{h} -q))
	
	if [[ $image_file == $source_image ]]; then
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
		# if there's a difference of more than four pixels either for the width or
		# the height, comparison of these two images is disabled. We can't just
		# compare for exact dimensions, because sometimes the output image is just
		# a little bit smaller or larger than the source image. For example, the
		# source image may be 250x167 and the output image 250x168.
		
		size_source=($(gmic -v - -i "$source_image" -echo_stdout[] {w}\" \"{h} -q))
		diff_width=$((${size[0]} - ${size_source[0]}))
		diff_width=${diff_width/#-/} # Absolute value.
		diff_height=$((${size[1]} - ${size_source[1]}))
		diff_height=${diff_height/#-/} # Absolute value.
		
		if [[ ! $diff_width =~ ^[0-4]$ || ! $diff_height =~ ^[0-4]$ ]]; then
			disabled_compare=" disabled"
			disabled_compare_title=" (disabled)"
		fi
	fi
	
	read -r -d '' html <<HTML_LI
<li id="$id">
	<figure>
		<p class="image"><img src="$src" width="${size[0]}" data-src="$data_src" data-src-static="$data_src_static" height="${size[1]}" alt="$filter_name" /></p>
		
		<figcaption>
			<p class="filter-name">$filter_name$filter_name_suppl</p>
			
			<ul class="menu-image">
				<li><a href="#$id"><span class="anchor fa fa-anchor" title="Link to this image"></span></a></li>
				<li><a href="$data_src" target="_blank"><span class="new-tab fa fa-external-link" title="Open in a new tab"></span></a></li>
				
				<li class="sep"><span class="reorder fa fa-arrows" title="Reorder the image using drag and drop"></span></li>
				
				<li><span class="display-style fa fa-expand" title="Toggle default/large display"></span></li>
				<li><span class="info fa fa-chevron-circle-down" title="Toggle info display"></span></li>
				<li><span class="compare fa fa-eye $disabled_compare" title="Toggle source image comparison$disabled_compare_title"></span></li>
				<li><span class="select fa fa-square-o $disabled_select" title="Toggle selection$disabled_select_title"></span></li>
			</ul>
			
			<p class="more-info hide">$information</p>
			
			$controls
		</figcaption>
	</figure>
</li>
HTML_LI
	
	echo "$html"
}

# Generate a running time entry to be added in the log file.
generate_time_entry()
{
	running_time=$1
	exit_status=$2
	filter_name=$3
	
	entry=$(printf '%-11s' "$running_time")
	entry+=$(printf '%-14s' "$exit_status")
	entry+="$filter_name\n"
	echo -e "$entry"
}

# Convert nanoseconds to seconds (leading zero, three decimal places).
nanoseconds_to_seconds()
{
	nanoseconds=$1
	
	seconds=$(echo "scale=3;x=$nanoseconds/1000000000;if(x<1) print 0; x" | bc)
	
	if [[ $seconds == "00" ]]; then
		seconds=0
	fi
	
	echo "$seconds"
}

# Display new filters.
new_filters()
{
	tmp_dir=$(mktemp -d)
	old_file="data/gimp_filters.txt"
	old_file_tmp="$tmp_dir/old.txt"
	new_file_tmp="$tmp_dir/new.txt"
	new_file_url="http://gmic.eu/gimp_filters.txt"
	
	wget -qO "$new_file_tmp" "$new_file_url"
	
	pattern="List of filters, sorted alphabetically"
	sed -n "1,/$pattern/p" "$old_file" > "$old_file_tmp"
	sed -i -n "1,/$pattern/p" "$new_file_tmp"
	
	diff --new-line-format="" --unchanged-line-format="" "$new_file_tmp" "$old_file_tmp"
	
	rm -rf "$tmp_dir"
	
	if [[ $? != 0 ]]; then
		echo "WARNING: can't delete $tmp_dir" >&2
	fi
}

# Replace a tag inside a file with the specified content.
replace_tag()
{
	tag=$1
	content=$2
	file=$3
	tmp_file=$4
	
	# Escape the special character "&" for awk.
	content="${content//&/\\\&}"
	
	# Put content in a temporary file, then use the file as content to replace the tag.
	# We can't pass content directly to awk as argument in the command line, because
	# for very long strings, we would face an error "Argument list too long".
	echo -e "$content" > "$tmp_file"
	
	number_of_lines=$(wc -l < "$tmp_file")
	
	if [[ $number_of_lines > 1 ]]; then
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
