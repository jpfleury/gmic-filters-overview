[See demos online.](http://jpfleury.github.io/gfo-demos/)

## Overview

[G'MIC](http://gmic.eu) is a free framework for image processing. It comes with hundreds of filters. There are so many possibilities. It's easy to get lost and just not know what filters to start it.

Here comes [gmic-filters-overview](https://github.com/jpfleury/gmic-filters-overview). It allows to overview all non-interactive G'MIC filters at once for a specific image. Just run the script and enjoy all filters applied automatically to your image. Then view results in a convenient HTML file offering a few Javascript functions like source image comparison.

## Requirements

To generate images from the command line:

- Bash (tested on GNU/Linux)
- G'MIC v1.6.5.2 or more recent

To view results in the HTML file:

- A modern browser. For Internet Explorer users, that means at least version 10 (although not tested).

## Installation

[Download the archive of the latest version](https://github.com/jpfleury/gmic-filters-overview/archive/master.zip) and extract it. That's it. gmic-filters-overview is ready to be used by the current user.

## Usage

**Note:** for this documentation, let's say the resulting folder from the extraction of the archive is `~/gmic-filters-overview-master` and the user navigated to this directory with a console (`cd ~/gmic-filters-overview-master`).

gmic-filters-overview consists of two parts: the Bash script to generate images and the HTML file to view results.

### Generate images (Bash script)

To display help and all command line options, run the script with the **option `-h`**:

	./gmic-filters-overview.sh -h

The two main options are the source image and the working folder. If no options are passed, that is:

	./gmic-filters-overview.sh

a default sample image will be used and a working folder will be created inside the script folder, as if the command line was the following:

	./gmic-filters-overview.sh -s /path-to-sample-image-inside-script-folder -w /path-to-script-folder/_HTML_

The source image is the one used to apply all filters. It's set with the **option `-s`**:

	./gmic-filters-overview.sh -s /path/to/image

The working folder is the location where the HTML file is created and images are saved. It will be created if it doesn't exist. It's set with the **option `-w`**:

	./gmic-filters-overview.sh -w /path/to/folder

If the working folder exists and was previously used by gmic-filters-overview, the **option `-d`** can be used to delete files before generating new ones.

By default, all filters from all filter categories are used. The **option `-c`** allows to restrict filter categories to the specified list:

	./gmic-filters-overview.sh -c "Arrays & tiles",Colors

In this example, only filters from *Arrays & tiles* and *Colors* will be included. Categories must be separated by comma. Category names containing spaces must be quoted. Available categories: Arrays & tiles, Artistic, Black & white, Colors, Contours, Deformations, Degradations, Details, Film emulation, Frames, Frequencies, Layers, Lights & shadows, Patterns, Rendering, Repair, Sequences, Stereoscopic 3d, Testing, Various.

Another way to select a subset of all available filters is to edit the file `data/filters.tsv`. It contains the list of filters used by the script. A filter can be disabled by commenting its line (i.e. adding the character `#` at the beginning of the line).

Applying hundreds of filters can take a long time for big images. In such cases, it's advisable to resize the source image before applying filters. It can be done with the **option `-r`**:

	./gmic-filters-overview.sh -r 750,500

In this example, the source image is resized to 750 × 500 px. Note that the original image is not modified. A copy is created.

The script creates an HTML file. The **option `-a`** hides by default the About section appearing at the beginning of the file.

The **option `-o`** allows to automatically open the HTML file in the default browser.

Some or all of these options can be combined:

	./gmic-filters-overview.sh -s /path/to/image -w /path/to/folder -c "Arrays & tiles",Colors -r 750,500 -a -d -o

After all images are generated, a log file is created at the root of the working folder. It contains information about each filter used, like filter name, command line, exit status and running time. Errors (if there were) are also listed.

### View results (HTML file)

A file `index.html` is created at the root of the working folder ([see demos online](http://jpfleury.github.io/gfo-demos/)) and gives an overview of each filter. Information and instructions are displayed at the beginning of the file.

## Development

Git is used for revision control. [Repository can be browsed online or cloned.](https://github.com/jpfleury/gmic-filters-overview)

## License

Author: Jean-Philippe Fleury (<http://www.jpfleury.net/en/contact.php>)  
Copyright © 2015 Jean-Philippe Fleury

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

## Third-party code

- [Font Awesome](http://fontawesome.io): font license: SIL OFL 1.1; code license: MIT License
- [jQuery](https://jquery.com): MIT license
- [jQuery UI](https://jqueryui.com): MIT license
- [isInViewport](https://github.com/zeusdeux/isInViewport): MIT license
