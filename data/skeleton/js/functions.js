$(document).ready(function() {
	////////////////////////////////////////
	// Miscellaneous
	////////////////////////////////////////
	
	// Make sure all images have the same height.
	var height_source_image = $('#source-image p.image img').height();
	$('p.image img').css('height', height_source_image);
	
	// Drag and snap images over other images.
	$('p.image img').draggable({
		start: function(event, ui) {
			$('p.image img').css('z-index', 0);
			$(this).css('z-index', 1);
		},
		snap: true,
		stack: 'img',
		opacity: 0.5,
		revert: true
	});
	
	// Scroll to previous/next image.
	$(document).keydown(function(e) {
		if (e.which == 37 || e.which == 39) { // Left arrow / right arrow.
			var li = $('#all-filters ul.images > li:in-viewport').first();
			
			if (li.length == 0) {
				id = 'source-image';
			} else {
				if (e.which == 37) {
					// Move up.
					var reference = li.prev();
				} else {
					// Move down.
					var reference = li.next();
					var position_this = li.position();
					var position_reference = reference.position();
					
					if (position_this.top == position_reference.top) {
						// Two images per row.
						reference = reference.next();
					}
				}
				
				var id = reference.attr('id');
				
				if (id === undefined) {
					id = li.attr('id');
				}
			}
			
			location.href = '#'+id;
		}
	});
	
	// Play animation.
	$('#page').on('click', 'img[data-src-static!=""], span.controls', function() {
		var img = $(this).closest('figure').find('p.image img');
		var controls = $(this).closest('figure').find('span.controls');
		var src = img.attr('src');
		var data_src = img.attr('data-src');
		var data_src_static = img.attr('data-src-static');
		var new_src = '';
		var new_title = '';
		
		if (src == data_src_static) {
			new_src = data_src;
			new_title = 'Pause'
		} else {
			new_src = data_src_static;
			new_title = 'Play'
		}
		
		img.attr('src', new_src);
		controls.attr('title', new_title);
		controls.toggleClass('fa-play fa-pause');
	});
	
	////////////////////////////////////////
	// Titles and sections
	////////////////////////////////////////
	
	// About [+/-].
	$('#about-title span').click(function(){
		$(this).toggleClass('fa-minus-square-o fa-plus-square-o');
		$('#about').toggleClass('hide');
	});
	
	// All filters [+/-].
	$('#all-filters-title span').click(function(){
		$(this).toggleClass('fa-minus-square-o fa-plus-square-o');
		$('#all-filters').toggleClass('hide');
	});
	
	// Display/hide category.
	$('#categories button').click(function(){
		var category = $(this).text();
		
		$('#all-filters p.filter-name').each(function(){
			if (category == $(this).text().split('/')[0].trim()) {
				$(this).closest('li').toggleClass('hide');
			}
		});
		
		$(this).toggleClass('active inactive');
	});
	
	// Selected filters [+/-].
	$('#selected-filters-title span').click(function(){
		$(this).toggleClass('fa-minus-square-o fa-plus-square-o');
		$('#selected-filters').toggleClass('hide');
	});
	
	////////////////////////////////////////
	// .menu-images
	////////////////////////////////////////
	
	// Reorder images.
	$('ul.images').sortable({
		handle: ".reorder",
		tolerance: "pointer"
	});
	
	// Toggle default/large display.
	$('#page').on('click', 'span.display-style', function() {
		var img = $(this).closest('figure').find('p.image img');
		
		if ($(this).hasClass('fa-expand')) {
			var docH = $(window).height();
			var liH = $(this).parents('li:eq(1)').outerHeight(true);
			var imgH = img.height();
			img.css('height', 'auto');
			img.css('max-height', imgH + (docH - liH));
		} else {
			img.css('height', $('#source-image p.image img').height());
		}
		
		$(this).parents('li:eq(1)').toggleClass('large');
		$(this).toggleClass('fa-expand fa-compress');
		var image_id = $(this).parents('li:eq(1)').attr('id');
		location.href = '#'+image_id;
	});
	
	// Toggle info display.
	$('#page').on('click', 'span.info', function() {
		$(this).parents('li:eq(1)').find('p.more-info').toggleClass('hide');
		$(this).toggleClass('fa-chevron-circle-down fa-chevron-circle-up');
	});
	
	// Toggle source image comparison.
	$('#page').on('click', 'span.compare:not(.disabled)', function() {
		var img = $(this).closest('figure').find('p.image img');
		var image_src = img.attr('src');
		var image_data_src = img.attr('data-src');
		var source_image_src = $('#source-image p.image img').attr('src');
		var new_src = "";
		
		if (image_src == image_data_src) {
			new_src = source_image_src;
		} else {
			new_src = image_data_src;
		}
		
		img.attr('src', new_src);
		$(this).toggleClass('fa-eye fa-eye-slash');
	});
	
	// Toggle selection.
	$('#all-filters ul.images span.select:not(.disabled)').click(function() {
		var image_id = $(this).parents('li:eq(1)').attr('id');
		var selected_image_id = image_id+'-selected';
		
		if ($(this).hasClass('fa-square-o')) {
			$(this).toggleClass('fa-square-o fa-check-square-o');
			var selected_image = $(this).parents('li:eq(1)').clone();
			selected_image.attr('id', selected_image_id);
			selected_image.find('span.anchor').closest('a').attr('href', '#'+selected_image_id)
			$('#selected-filters ul.images').append(selected_image);
		} else if ($(this).hasClass('fa-check-square-o')) {
			$(this).toggleClass('fa-square-o fa-check-square-o');
			$('#'+selected_image_id).remove();
		}
		
		$(this).closest('figure').toggleClass('selected');
	});
	$('#selected-filters ul.images').on('click', 'span.select:not(.disabled)', function() {
		var selected_image_id = $(this).parents('li:eq(1)').attr('id');
		var image_id = selected_image_id.replace(/-selected$/, '');
		$('#'+image_id+' span.select').toggleClass('fa-square-o fa-check-square-o');
		$('#'+image_id+' figure.selected').toggleClass('selected');
		$('#'+selected_image_id).remove();
	});
	
	////////////////////////////////////////
	// #menu
	////////////////////////////////////////
	
	// Expand images display.
	$('#expand').click(function(){
		$('ul.images > li:not(.large)').each(function(){
			var img = $(this).find('p.image img');
			var docH = $(window).height();
			var liH = $(this).outerHeight(true);
			var imgH = img.height();
			img.css('height', 'auto');
			img.css('max-height', imgH + (docH - liH));
			$(this).toggleClass('large');
			$(this).find('span.display-style').toggleClass('fa-expand fa-compress');
		});
	});
	
	// Reduce images display.
	$('#reduce').click(function(){
		$('ul.images > li.large').each(function(){
			var img = $(this).find('p.image img');
			img.css('height', $('#source-image p.image img').height());
			$(this).toggleClass('large');
			$(this).find('span.display-style').toggleClass('fa-expand fa-compress');
		});
	});
	
	// Toggle categories.
	$('#toggle-categories').click(function(){
		$('#categories button').trigger('click');
	});
	
	// List selected filters.
	$('#list-selected-filters').click(function(){
		var list = [];
		
		$('#selected-filters p.filter-name').each(function(){
			var filter_name = $(this).text();
			
			if (filter_name != 'Source image' && $.inArray(filter_name, list) === -1) {
				list.push(filter_name);
			}
		});
		
		if (list.length == 0) {
			list.push('No filters selected');
		}
		
		list.sort();
		var text = '<div title="Selected filters">'+list.join("<br />\n")+'</div>';
		$(text).dialog();
	});
});
