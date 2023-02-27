#charset "us-ascii"
//
// custom.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a simple demonstration of how to implement custom line-buffered
// typographic filters
//
// It can be compiled via the included makefile with
//
//	# t3make -f custom.t3m
//
// ...or the equivalent, depending on what TADS development environment
// you're using.
//
// This "game" is distributed under the MIT License, see LICENSE.txt
// for details.
//
#include <adv3.h>
#include <en_us.h>

versionInfo:    GameID
        name = 'bufferedOutputFilter Library Demo Game'
        byline = 'Diegesis & Mimesis'
        desc = 'Demo game for the bufferedOutputFilter library. '
        version = '1.0'
        IFID = '12345'
	showAbout() {
		"This is a simple demonstration of a LineBufferedOutputFilter
		filter.
		<.p>
		If you >EXAMINE PEBBLE, the description will contain a
		bunch of lorem ipsum text.  Each line will have <q>===</q>
		added as a prefix and suffix to the line.
		<.p>
		That's it.
		<.p>
		Consult the README.txt document distributed with the library
		source for a quick summary of how to use the library in your
		own games.
		<.p>
		The library source is also extensively commented in a way
		intended to make it as readable as possible. ";
	}
;

// Custom filter declaration.
// We use LineBufferedOutputFilter as the base class.  It applies the
// filter markup on a line-by-line basis.
pebbleOutputFilter: LineBufferedOutputFilter
	// The string literal to use as the tag for this filter.
	// In this case the filter will be applied to everything
	// between the <PEBBLE></PEBBLE> tags.
	// The string is case-insensitive.
	bofTag = 'pebble'

	// String literal to prepend to every line.  Can be nil.
	lineBufferPrefix = '==='

	// String literal to append to every line.  Can be nil.
	lineBufferSuffix = '==='

	// Width of each line.  Text will be wrapped (on whitespace)
	// if adding another word would make the line longer than
	// this many characters.  Note that the logic for evaluating
	// line length is very simple and doesn't attempt to
	// figure out the rendered length of whitespace, ligatures, or
	// anything like that.  So '\t' is two characters, regardless
	// of how many typographic spaces it renders as.
	lineBufferWidth = 60
;

startRoom: Room 'Void'
        "This is a featureless void."
;
+me: Person;

// Pebble with a description using a tag matched by the filter we
// declared above.
+pebble: Thing 'small round pebble' 'pebble'
	"This is a bit of random pre-markup text.
	<.p>
	<PEBBLE>
	Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
	eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim
	ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut
	aliquip ex ea commodo consequat. Duis aute irure dolor in
	reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
	pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
	culpa qui officia deserunt mollit anim id est laborum.
	\n
	Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
	eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim
	ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut
	aliquip ex ea commodo consequat. Duis aute irure dolor in
	reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
	pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
	culpa qui officia deserunt mollit anim id est laborum.
	</PEBBLE>
	<.p>
	This is a bit of concluding post-markup text. "
;

gameMain: GameMainDef
	initialPlayerChar = me
	newGame() {
		// Add our custom filter to the main output stream.
		mainOutputStream.addOutputFilter(pebbleOutputFilter);
		runGame(true);
	}
;
