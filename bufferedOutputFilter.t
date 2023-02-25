#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

// Module ID for the library
bofModuleID: ModuleID {
        name = 'Buffered Output Filter Library'
        byline = 'Diegesis & Mimesis'
        version = '1.0'
        listingOrder = 99
}

class BufferedOutputFilter: OutputFilter, PreinitObject
	// The HTML/XML-like tag to use to for the filter.
	// For example, if you wanted to declare the tags to
	// be <FOOZLE></FOOZLE>, you'd use bofTag = 'foozle'
	bofTag = nil

	// Property to hold the compiled regex.
	_bofPattern = nil

	// Filter can be toggled on and off by calling activate() and
	// deactivate().
	isActive = true
	activate() { isActive = true; }
	deactivate() { isActive = nil; }

	// Keeps track of whether the output stream is currently in
	// the middle of a tag (boolean true) or not (nil).
	_bofTagState = nil

	// Property to hold the vector used to keep track of buffered text.
	_bofVector = nil

	// Preinit method to compile the regex pattern to match our
	// tag, if one is defined.
	execute() {
		// If we have no tag defined we can't do anything, so
		// deactivate the filter.
		if(bofTag == nil) {
			deactivate();
			return;
		}
		_bofPattern = new RexPattern('<nocase><langle>(/'
			+ bofTag + '|' + bofTag + ')<rangle>');
	}

	bufferedFilterActive() {
		// Only filter text if we're currently active.
		if(isActive == nil)
			return(nil);

		// We need a filter to work.
		if(_bofPattern == nil)
			return(nil);

		return(true);
	}

	bofRexSearch(val) { return(rexSearch(_bofPattern, val)); }

	// Main filter method.  Entry point from the T3 OutputFilter logic.
	filterText(ostr, val) {
		local idx, str;

		if(bufferedFilterActive() != true)
			return(inherited(ostr, val));

		// Get the first occurance of our markup tag.
		//idx = rexSearch(_bofPattern, val);
		idx = bofRexSearch(val);

		// Loop until we're out of input or tags.
		while(idx != nil) {
			// Is this an open or a close?  If the tag starts
			// with a slash then we're a close, otherwise we're
			// an open.
			_bofTagState = !rexGroup(1)[3].startsWith('/');

			// Get the stuff after the tag.
			str = val.substr(idx[1] + idx[2]);

			// Create a results vector.
			if(_bofVector == nil)
				_bofVector = new Vector();

			// Append the stuff before the tag to the results
			// vector.  We store things as a two-element array,
			// the first element being the matching text and
			// the second being a boolean flag indicating
			// if it was found inside our markup tags (boolean
			// true) or not (nil).
			_bofVector.append([
				val.substr(1, idx[1] - 1),
				!_bofTagState
			]);

			// Update our value to only look at what's after
			// the tag we just looked at.
			val = str;

			// Find the next tag, if any.
			//idx = rexSearch(_bofPattern, str);
			idx = bofRexSearch(str);
		}

		// If we found matching text, we'll have a results
		// vector, which we now check.
		if(_bofVector != nil) {
			// If str is non-nil, that means we had a little
			// bit left over after our last tag match, so we
			// add it to the results vector.
			if(str != nil)
				_bofVector.append([ str, nil ]);

			// Now we make a string buffer to dump our results
			// vector into.
			val = new StringBuffer();

			// Go through the vector, checking if each bit was
			// found inside or outside our markup tags and
			// adding it to the string buffer with appropriate
			// formatting.
			_bofVector.forEach(function(o) {
				// Each element of the vector is a two-element
				// array.  The first element is the text,
				// and the second is a flag indicating if
				// it was found inside the markup tags or
				// not (boolean true if it was, nil otherwise).
				if(o[2] == true)
					val.append(bofFormat(o[1]));
				else
					val.append(o[1]);
			});

			// Convert the buffer into a string.
			val = toString(val);

			// Reset the results vector.
			_bofVector = nil;
		}

		return(val);
	}

	bofFormat(str) { return(str); }
;

// Line-buffered output filter
class LineBufferedOutputFilter: BufferedOutputFilter
	// Newline character(s).  Inserted at the end of every output line.
	lineBufferNewline = '\n'

	// Prefix and suffix for each line.  Can be nil.
	// If you wanted to have every line indented with a single tab,
	// you could use lineBufferPrefix = '\t', for example.
	lineBufferPrefix = nil
	lineBufferSuffix = nil

	// Width of each line.  Note that the line is wrapped when adding
	// the next word would put more than this many characters in
	// the buffer.  Also note that the logic is very simplistic and
	// doesn't figure the RENDERED width of the line (that is, '\t'
	// counts as two characters, not however many spaces a tab is).
	lineBufferWidth = 70

	// Pattern used to split the text into words for the purposes of
	// line wrapping.
	lineBufferSplitPattern = R'<space>+'

	// Clear the passed buffer and then add whatever line prefix, if any,
	// is defined.
	lineBufferClear(buf) {
		buf.deleteChars(1);
		if(lineBufferPrefix)
			buf.append(lineBufferPrefix);
	}

	// Flush the buffer (second arg) to the output stream (first arg).
	// The output stream is actually a buffer itself, but w/e.
	lineBufferFlush(outstr, buf) {
		// If we have a newline character defined, insert it.
		if(lineBufferNewline)
			outstr.append(lineBufferNewline);

		// Insert the line prefix, if defined.
		if(lineBufferPrefix)
			outstr.append(lineBufferPrefix);

		// Append the contents of the buffer.
		if(buf.length > 0)
			outstr.append(toString(buf));

		// Add the line suffix, if defined.
		if(lineBufferSuffix)
			outstr.append(lineBufferSuffix);

		// Add a newline.
		if(lineBufferNewline)
			outstr.append(lineBufferNewline);

		// Clear the buffer we just flushed to output.
		lineBufferClear(buf);
	}

	// Line-buffered formatter method.
	bofFormat(str) {
		local ar, buf, r;

		// Split the string at whitespace.
		ar = str.split(lineBufferSplitPattern);

		// If we don't have any spaces, we don't have anything to do.
		if(ar.length < 2)
			return(str);

		// buf will hold our line buffer and r will hold our return
		// buffer.
		buf = new StringBuffer();
		r = new StringBuffer();

		// Prep the line buffer.  This will clear it, which we
		// don't need to do right now, but it will also add whatever
		// line prefix we have defined.
		lineBufferClear(buf);

		// Go through every word(-ish thing) in the string.
		ar.forEach(function(o) {
			// If the "word" is just a newline by itself, insert a
			// paragraph break and reset the line buffer.
			if(rexMatch('^<space>*<newline>+<space>*$', o) != nil) {
				buf.append('<.p>');
				lineBufferFlush(r, buf);
				return;
			}

			// Check to see if the current word would make the
			// line too long.  If so, flush and clear the buffer.
			if((buf.length() + o.length()) > lineBufferWidth) {
				lineBufferFlush(r, buf);
			}

			// Append the word to the line buffer and add a space.
			buf.append(o);
			buf.append(' ');
		});

		// Add anything left over in the line buffer to the return
		// buffer.
		if(buf.length > 0)
			lineBufferFlush(r, buf);
		
		// Return the return buffer as a string.
		return(toString(r));
	}
;

quoteOutputFilter: LineBufferedOutputFilter
	bofTag = 'quote'
	lineBufferPrefix = '\t\t'
	lineBufferWidth = 40
;
