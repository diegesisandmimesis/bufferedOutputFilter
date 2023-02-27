#charset "us-ascii"
//
// sample.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// Simple demonstration of BufferedOutputFilter filtering.
//
// It can be compiled via the included makefile with
//
//	# t3make -f makefile.t3m
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
		"This is a simple demonstration of a BufferedOutputFilter
		filter.
		<.p>
		If you >EXAMINE PEBBLE, the description will contain a
		bunch of lorem ipsum text formatted as a block quote.
		This is declared via &lt;QUOTE&gt;&lt;/QUOTE&gt; tags
		in the pebble description.
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

startRoom: Room 'Void'
        "This is a featureless void."
;
+me: Person;
+pebble: Thing 'small round pebble' 'pebble'
	"This is a bit of random pre-markup text.
	<.p>
	<QUOTE>
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
	</QUOTE>
	<.p>
	This is a bit of concluding post-markup text. "
;

gameMain: GameMainDef
	initialPlayerChar = me
	newGame() {
		// Add the quote filter to the main output stream.
		mainOutputStream.addOutputFilter(quoteOutputFilter);
		runGame(true);
	}
;
