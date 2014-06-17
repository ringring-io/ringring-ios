# Ringring.io on iOS #

Ringring.io is a Phone and Messaging application built for privacy with open architectures. You can originate calls and send messages in an easy and secured way with no data-collecting man or company in the middle. The technology is freely available for public.

![Ringring.io Screenshot 1](https://raw.githubusercontent.com/ringring-io/ringring-ios/master/Screenshots/screenshot0_small.png) &nbsp;&nbsp;&nbsp; ![Ringring.io Screenshot 2](https://raw.githubusercontent.com/ringring-io/ringring-ios/master/Screenshots/screenshot1_small.png)

## Build Prerequisites ##

Ringring on iOS is based on [Liblinphone, free SIP VoIP SDK](http://www.linphone.org/eng/documentation/dev/liblinphone-free-sip-voip-sdk.html) and first you need to prepare your system to build it.

Download and install:

* Xcode 5 (Tested on 5.1.1)
* [Xcode Command Line Tools](https://developer.apple.com/downloads/index.action)
* [MacPorts](http://www.macports.org) (Make sure that /opt/local/bin (macport tools) arrives first in your PATH env variable, so that the macport tools are taken in place of the versions brought by Apple in /usr/bin. Otherwise the build will fail with obscure errors.)
* [CocoaPods](http://cocoapods.org)

Once Xcode and MacPorts are installed you need to tweak OSX, open a terminal and install the required build-time tools with:

    $ sudo port install coreutils automake autoconf libtool intltool wget pkgconfig cmake gmake yasm nasm grep doxygen ImageMagick optipng antlr3

Install [gas-preprosessor.pl](http://github.com/yuvi/gas-preprocessor/) to be copied into /opt/local/bin :

    $ wget --no-check-certificate https://raw.github.com/yuvi/gas-preprocessor/master/gas-preprocessor.pl
    $ sudo mv gas-preprocessor.pl /opt/local/bin/.
    $ sudo chmod +x /opt/local/bin/gas-preprocessor.pl

Link macport libtoolize to glibtoolize 

	$ sudo ln -s /opt/local/bin/glibtoolize /opt/local/bin/libtoolize

Link host's strings, ar and ranlib to simulator SDK 

	$ sudo ln -s  /usr/bin/strings /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/bin/strings
	$ sudo ln -s  /usr/bin/ar /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/bin/ar
	$ sudo ln -s  /usr/bin/ranlib /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/bin/ranlib


## Building the SDK ##

    $ cd submodules/build
    $ make all 

The resulting multi arch SDK is in liblinphone-sdk/ directory.

In case you upgrade your IOS SDK, you may force rebuilding everything, by doing

    $ make veryclean
    $ make all


## Building the iOS application ##

Install the Pod dependencies:

    $ pod install

Make sure to **always open the Xcode workspace** instead of the project file when building your project:

    $ open ringring.xcworkspace

Open Xcode and make sure "Build Active Architecture Only" is set to "No" in the build settings of both the "Pods" and "ringring" project.
    
Press "Run" in Xcode.
