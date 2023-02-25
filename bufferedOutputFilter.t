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

class LineBufferedOutputFilter: BufferedOutputFilter
	lineBufferNewline = '\n'
	lineBufferPrefix = nil
	lineBufferSuffix = nil
	lineBufferWidth = 78

	lineBufferSplitPattern = R'<space>+'

	lineBufferFlush(buf) {
		buf.deleteChars(1);
		if(lineBufferPrefix) buf.append(lineBufferPrefix);
	}

	lineBufferAppend(outstr, buf) {
		if(lineBufferNewline) outstr.append(lineBufferNewline);
		if(lineBufferPrefix) outstr.append(lineBufferPrefix);
		//if(buf.length > 0) outstr.append(toString(buf));
		outstr.append(toString(buf));
		if(lineBufferSuffix) outstr.append(lineBufferSuffix);
		if(lineBufferNewline) outstr.append(lineBufferNewline);
	}

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

		// Start out with an indentation.
		lineBufferFlush(buf);

		// Go through every word(-ish thing) in the string.
		ar.forEach(function(o) {
			// If we just have a newline by itself, insert a
			// line break and reset the line buffer.
			if(rexMatch('^<space>*<newline>+<space>*$', o) != nil) {
				lineBufferAppend(r, buf);
				//r.append(toString(buf));
				//r.append('<.p>\n');
				//r.append(quoteOutputFilterIndent);
				lineBufferFlush(buf);
				return;
			}

			// Append the word to the line buffer and add a space.
			buf.append(o);
			buf.append(' ');

			// If we've reached the end of a line, flush the
			// line buffer to the return buffer and reset the
			// line buffer.
			if(buf.length() > lineBufferWidth) {
				lineBufferAppend(r, buf);
				lineBufferFlush(buf);
			}
		});

		// Add anything left over in the line buffer to the return
		// buffer.
		if(buf.length > 0) {
			lineBufferAppend(r, buf);
			//r.append('\n\t\t');
			//r.append(toString(buf));
			//r.append('\n');
		}
		
		// Return the return buffer as a string.
		return(toString(r));
	}
;

quoteOutputFilter: LineBufferedOutputFilter
	bofTag = 'quote'
	lineBufferPrefix = '\t\t'
	lineBufferWidth = 40
;

/*
quoteOutputFilter: BufferedOutputFilter
	bofTag = 'quote'

	lineBufferSplitPattern = '<space>+'
	quoteOutputFilterIndent = '\t\t'

	bofFormat(str) {
		local ar, buf, r;

		// Split the string at whitespace.
		//ar = str.split(R'<space>+');
		ar = str.split(lineBufferSplitPattern);

		// If we don't have any spaces, we don't have anything to do.
		if(ar.length < 2)
			return(str);

		// buf will hold our line buffer and r will hold our return
		// buffer.
		buf = new StringBuffer();
		r = new StringBuffer();

		// Start out with an indentation.
		buf.append(quoteOutputFilterIndent);

		// Go through every word(-ish thing) in the string.
		ar.forEach(function(o) {
			// If we just have a newline by itself, insert a
			// line break and reset the line buffer.
			if(rexMatch('^<space>*<newline>+<space>*$', o) != nil) {
				r.append(toString(buf));
				r.append('<.p>\n');
				r.append(quoteOutputFilterIndent);
				buf.deleteChars(1);
				buf.append(quoteOutputFilterIndent);
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
				buf.append(quoteOutputFilterIndent);
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
*/
