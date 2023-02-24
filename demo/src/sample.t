#charset "us-ascii"
//
// sample.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the bufferedOutputFilter
// library.
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
		"This is a simple test game that demonstrates the features
		of the bufferedOutputFilter library.
		<.p>
		Consult the README.txt document distributed with the library
		source for a quick summary of how to use the library in your
		own games.
		<.p>
		The library source is also extensively commented in a way
		intended to make it as readable as possible. ";
	}
;

pebbleOutputFilter: BufferedOutputFilter
	lineBufferFilterTag = 'pebble'

	lineBufferFilterFormat(str) {
		local ar, buf, r;

		// Split the string at whitespace.
		ar = str.split(R'<space>+');

		// If we don't have any spaces, we don't have anything to do.
		if(ar.length < 2)
			return(str);

		// buf will hold our line buffer and r will hold our return
		// buffer.
		buf = new StringBuffer();
		r = new StringBuffer();

		// Start out with an indentation.
		buf.append('\t\t');

		// Go through every word(-ish thing) in the string.
		ar.forEach(function(o) {
			// If we just have a newline by itself, insert a
			// line break and reset the line buffer.
			if(rexMatch('^<space>*<newline>+<space>*$', o) != nil) {
				r.append(toString(buf));
				r.append('<.p>\n\t\t');
				buf.deleteChars(1);
				buf.append('\t\t');
				return;
			}

			// Append the word to the line buffer and add a space.
			buf.append(o);
			buf.append(' ');

			// If we've reached the end of a line, flush the
			// line buffer to the return buffer and reset the
			// line buffer.
			if(buf.length() > 40) {
				r.append('\n\t\t');
				r.append(toString(buf));
				r.append('\n');
				buf.deleteChars(1);
				buf.append('\t\t');
			}
		});
		// Add anything left over in the line buffer to the return
		// buffer.
		if(buf.length > 0) {
			r.append('\n\t\t');
			r.append(toString(buf));
			r.append('\n');
		}
		
		// Return the return buffer as a string.
		return(toString(r));
	}
;

startRoom: Room 'Void'
        "This is a featureless void."
;
+me: Person;
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
		mainOutputStream.addOutputFilter(pebbleOutputFilter);
		runGame(true);
	}
;
