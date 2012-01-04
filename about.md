What is SwiffCore?

SwiffCore is a Mac OS X and iOS framework that renders vector shapes and animations stored in the SWF format.  It also provides basic support for accompanying bitmaps, fonts, text, and MP3 streams.

It isn't a Flash runtime.  It doesn't enable you to run your interactive Flash games on iOS.  It will, however, play your favorite Flash animations from the early 21st century.


Why?
I needed a solution for bringing my music theory lessons to the iPhone and iPad.  Each lesson  of frames of vector artwork

1) Generate PNG files for each frame, in various resolutions
I had already written a SWF->PNG converter for Mac OS X .  It used WebKit to load the Flash Player plug-in, seek to a specific frame, then capture the frame using the screenshot APIs).

2) Generate a movie file for each lesson
While iOS supports both the H.264 and MPEG-4 formats, neither is well suited for text and simple vector graphic content.

3) Use as3swf's Shape Export to Objective-C to generate classes for each lesson.

4) Write my own shape exported into a proprietery data format, then render it
This is basically an abstraction layer on #3.  At some point, the data format begins to look like SWF.

5) Read the SWF file and render it myself.
Like a boss.


How do I use it?
1) Create an NSData object containing your SWF file
2) Load it into a SwiffMovie using -[SwiffMovie initWithData:]
3) Make an accompanying SwiffView using -[SwiffView initWithFrame:movie:]
4) Play it using the SwiffPlayhead returned by -[SwiffView playhead]


How does it work?
Under the hood, SwiffCore uses Core Graphics to draw the vector shapes and static text, Core Text to draw dynamic text fields, and Core Audio to playback sounds and music.  It composites all graphics into a Core Animation CALayer, contained in a UIView or NSView.  

Optionally, multiple CALayers can be used (via SwiffPlacedObject.wantsLayer) to reduce CPU load and interpolate animations up to 60fps (even when the source movie is less than 60fps).

For more information, read the SwiffCore Architecture wiki article.


What's supported?



use a variant of this solution for displaying 

Unfortuately, the number of PNG files



With thousands of unique frames of vector artwork, redrawing 

For Theory Lessons, I needed  to render thousands of frames of vector artwork into my 
SwiffCore I had thousands of frames of animated vector artwork 


- Ability to specify the pixel width
- Customize rendering 

What's the performance like?

Ultimately, performance depends on the source movie and the use of SwiffPlacedObject.wantsLayer.  If SwiffCore has to redraw several objects per frame, and those frames contain gradients and/or complex paths, it's easy to saturate the CPU and drop frames.  CPU usage is greatly reduced when SwiffPlacedObject.wantsLayer is set to YES, but more memory will be used.

For Theory Lessons on an iPhone 3GS, SwiffCore rendered all of my movies at a full 20fps (the movies' specified frame rate) without using wantsLayer.