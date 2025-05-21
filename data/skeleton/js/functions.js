document.addEventListener('DOMContentLoaded', () => {
	//################################################################################
	//## @title Miscellaneous
	//################################################################################

	// Ensure all images have the same height
	const heightSourceImage = document.querySelector('#source-image p.image img').height;
	document.querySelectorAll('p.image img').forEach(img => {
		img.style.height = `${heightSourceImage}px`;
	});

	// Enable drag-and-snap for images
	$('p.image img').draggable({
		start(event, ui) {
			$('p.image img').css('z-index', 0);
			$(this).css('z-index', 1);
		},
		snap: true,
		stack: 'img',
		opacity: 0.5,
		revert: true
	});

	// Scroll to previous/next image with arrow keys
	document.addEventListener('keydown', e => {
		if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') { // Left or right arrow
			const visibleItem = $('#all-filters ul.images > li:in-viewport').first();

			let targetId;

			if (!visibleItem.length) {
				targetId = 'source-image';
			} else {
				let reference;

				// Move to previous item
				if (e.key === 'ArrowLeft') {
					reference = visibleItem.prev();
				}

				// Move to next item (two-per-row case handled)
				else {
					reference = visibleItem.next();

					const posThis = visibleItem.position();
					const posRef = reference.position();

					if (posThis.top === posRef.top) {
						reference = reference.next();
					}
				}

				targetId = reference.attr('id') || visibleItem.attr('id');
			}

			location.href = `#${targetId}`;
		}
	});

	// Play/pause animation on image click
	$('#page').on('click', 'img[data-src-static], span.controls', function () {
		const $figure = $(this).closest('figure');
		const $img = $figure.find('p.image img');
		const $controls = $figure.find('span.controls');

		const src = $img.attr('src');
		const staticSrc = $img.attr('data-src-static');
		const animatedSrc = $img.attr('data-src');
		const isStatic = src === staticSrc;

		$img.attr('src', isStatic ? animatedSrc : staticSrc);
		$controls.attr('title', isStatic ? 'Pause' : 'Play');
		$controls.toggleClass('fa-play fa-pause');
	});

	//################################################################################
	//## @title Sections and toggles
	//################################################################################

	// Toggle "About" section
	document.querySelector('#about-title span').addEventListener('click', function () {
		$(this).toggleClass('fa-square-minus fa-square-plus');
		$('#about').toggleClass('hide');
	});

	// Toggle "All Filters" section
	document.querySelector('#all-filters-title span').addEventListener('click', function () {
		$(this).toggleClass('fa-square-minus fa-square-plus');
		$('#all-filters').toggleClass('hide');
	});

	// Toggle category visibility
	document.querySelectorAll('#categories button').forEach(btn => {
		btn.addEventListener('click', function () {
			const category = this.textContent.trim();

			$('#all-filters p.filter-name').each(function () {
				if (category === $(this).text().split('/')[0].trim()) {
					$(this).closest('li').toggleClass('hide');
				}
			});
			$(this).toggleClass('active inactive');
		});
	});

	// Toggle "Selected Filters" section
	document.querySelector('#selected-filters-title span').addEventListener('click', function () {
		$(this).toggleClass('fa-square-minus fa-square-plus');
		$('#selected-filters').toggleClass('hide');
	});

	//################################################################################
	//## @title Image menu
	//################################################################################

	// Reorder images with drag handle
	$('ul.images').sortable({
		handle: '.reorder',
		tolerance: 'pointer'
	});

	// Toggle image size display
	$('#page').on('click', 'span.display-style', function () {
		const $img = $(this).closest('figure').find('p.image img');

		const isExpanded = $(this).hasClass('fa-expand');

		if (isExpanded) {
			const docH = $(window).height();
			const liH = $(this).parents('li').eq(1).outerHeight(true);
			const imgH = $img.height();

			$img.css('height', 'auto').css('max-height', imgH + (docH - liH));
		} else {
			$img.css('height', `${heightSourceImage}px`);
		}

		$(this).parents('li').eq(1).toggleClass('large');
		$(this).toggleClass('fa-expand fa-compress');

		location.href = `#${$(this).parents('li').eq(1).attr('id')}`;
	});

	// Toggle additional info display
	$('#page').on('click', 'span.info', function () {
		$(this).parents('li').eq(1).find('p.more-info').toggleClass('hide');
		$(this).toggleClass('fa-circle-chevron-down fa-circle-chevron-up');
	});

	// Toggle source comparison on click
	$('#page').on('click', 'span.compare:not(.disabled)', function () {
		const $img = $(this).closest('figure').find('p.image img');

		const current = $img.attr('src');
		const dataSrc = $img.attr('data-src');
		const staticBase = $('#source-image p.image img').attr('src');

		$img.attr('src', current === dataSrc ? staticBase : dataSrc);
		$(this).toggleClass('fa-eye fa-eye-slash');
	});

	//################################################################################
	//## @title Selection handling
	//################################################################################

	// Select/unselect filters
	function toggleSelection($icon) {
		const li = $icon.parents('li').eq(1);
		const id = li.attr('id');
		const selId = `${id}-selected`;

		if ($icon.hasClass('fa-square')) {
			$icon.toggleClass('fa-square fa-square-check');

			const $clone = li.clone().attr('id', selId);

			$clone.find('span.anchor').closest('a').attr('href', `#${selId}`);
			$('#selected-filters ul.images').append($clone);
		} else {
			$icon.toggleClass('fa-square-check fa-square');
			$(`#${selId}`).remove();
		}

		li.find('figure').toggleClass('selected');
	}

	$('#all-filters ul.images').on('click', 'span.select:not(.disabled)', function () {
		toggleSelection($(this));
	});

	$('#selected-filters ul.images').on('click', 'span.select:not(.disabled)', function () {
		const selLi = $(this).parents('li').eq(1);
		const original = selLi.attr('id').replace(/-selected$/, '');

		$(`#${original} span.select`).toggleClass('fa-square fa-square-check');
		$(`#${original} figure`).toggleClass('selected');
		selLi.remove();
	});

	//################################################################################
	//## @title Menu actions
	//################################################################################

	// Expand all images
	document.getElementById('expand').addEventListener('click', () => {
		$('ul.images > li:not(.large)').each(function () {
			const $img = $(this).find('p.image img');

			const docH = $(window).height();
			const liH = $(this).outerHeight(true);
			const imgH = $img.height();

			$img.css('height', 'auto').css('max-height', imgH + (docH - liH));
			$(this).addClass('large');
			$(this).find('span.display-style').toggleClass('fa-expand fa-compress');
		});
	});

	// Reduce all images
	document.getElementById('reduce').addEventListener('click', () => {
		$('ul.images > li.large').each(function () {
			$(this).find('p.image img').css('height', `${heightSourceImage}px`);
			$(this).removeClass('large');
			$(this).find('span.display-style').toggleClass('fa-expand fa-compress');
		});
	});

	// Toggle all categories at once
	document.getElementById('toggle-categories').addEventListener('click', () => {
		document.querySelectorAll('#categories button').forEach(btn => btn.click());
	});

	// List selected filters in dialog
	document.getElementById('list-selected-filters').addEventListener('click', () => {
		const list = [];
		$('#selected-filters p.filter-name').each(function () {
			const fname = $(this).text();

			if (fname !== 'Source image' && !list.includes(fname)) {
				list.push(fname);
			}
		});

		if (!list.length) {
			list.push('No filters selected');
		}

		list.sort();

		$('<div>', { title: 'Selected filters', html: list.join('<br>') }).dialog();
	});
});
