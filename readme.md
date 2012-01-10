# SwiffCore

SwiffCore is a Mac OS X and iOS framework that renders vector shapes and animations stored in the SWF format.  It also provides basic support for the accompanying bitmaps, fonts, text, and MP3 streams.

It **isn't** a Flash runtime.  It doesn't enable you to run your interactive Flash games on iOS.  It will, however, accurately render your existing vector graphics and animations.


## Why?

I needed a solution for bringing my music theory lessons (http://www.musictheory.net/lessons) to the iPhone
and iPad.  Each lesson contains several hundred frames of vector information.  

During initial development, I explored several options:

1. **Use Adobe Flash Professional's export-to-iOS feature**  
This creates a standalone .ipa file of your entire Flash project.  I couldn't find a safe, supported way of accessing these from my app.  Also, I would rather not inject a blob of Adobe-quality binary code into my app.

2. **Generate PNG files for each frame, in various resolutions**  
I had already written a SWF->PNG converter for Mac OS X .  It used WebKit to load the Flash Player plug-in, seek to a specific frame, then capture the frame using the screenshot APIs).  While the resulting images were accurate, they also used a large amount of space on disk (~45MB).

3. **Generate a movie file for each lesson**  
While iOS supports both the H.264 and MPEG-4 formats, neither is well suited for text and simple vector graphic content.

4. **Use [as3swf](https://github.com/claus/as3swf)'s Shape Export to Objective-C to generate classes for each lesson.**  
This resulted in a very large binary size.

5. **Write my own shape exported into a proprietery data format, then render it**  
This is basically an abstraction layer on #4.  At some point, the data format begins to look like SWF.

6. **Read the SWF file and render it myself.**


## Usage

Using the framework is fairly simple:

1. Create an NSData instance containing your SWF file
2. Load it into a SwiffMovie instance using `-[SwiffMovie initWithData:]`
3. Make an accompanying SwiffView instance using `-[SwiffView initWithFrame:movie:]`
4. Play it using the SwiffPlayhead returned by `-[SwiffView playhead]`


## Design

Under the hood, SwiffCore uses Core Graphics to draw the vector shapes and static text, Core Text to draw dynamic
text fields, and Core Audio to playback sounds and music.  It composites all graphics into a Core Animation CALayer,
contained in a UIView or NSView.  

Optionally, multiple CALayers can be used (via `-[SwiffPlacedObject setWantsLayer:YES]`) to reduce redrawing.
Placed objects promoted to layers also animate at a full 60fps (even when the source movie is less than 60fps).

For more information, read the SwiffCore Architecture wiki article.


## What's supported?


## Performance

Ultimately, performance depends on the source movie and the use of `SwiffPlacedObject.wantsLayer`.  If SwiffCore has to redraw several objects per frame, and those frames contain gradients and/or complex paths, it's easy to saturate the CPU and drop frames.  CPU usage is greatly reduced when `SwiffPlacedObject.wantsLayer` is set to YES, but memory footprint increases.

For Theory Lessons on an iPhone 3GS, SwiffCore rendered all of my movies at a full 20fps (the original frame rate) without using wantsLayer.  I then promoted specific SwiffPlacedObject instances to have their own layer (wantsLayer=YES) to create fluid 60fps animations.

