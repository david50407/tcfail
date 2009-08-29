# TCFail

Copyright © 2009 Weizhong Yang. All Rights Reserved.

## Introduction

If you are a Mac user and you read and write Traditional Chinese, the first thing you may want to do is to replace the system font after installing Apple's latest operating system, Mac OS X 10.6 Snow Leopard.

The default Traditional Chinese font, Heiti TC, looks really *BAD*. Many glyphs may come from the Japanese Kanji but do not follow the standard in Taiwan, so how can you say it is a Traditional Chinese font? You can also find that some glyphs with a same radical, but they were not created with a consistent principle. The strokes are too thin, it makes hard to read the characters on the monitors. Basically Heiti TC ruins the user experience.

To avoid the terrible font, you can alter the Traditional Chinese font fallback by editing a setting file. It is located somewhere under the sytstem folder ( ``/System/Library/Frameworks/ApplicationServices.framework/Frameworks/CoreText.framework/Resources/DefaultFontFallbacks.plist``) and you need system administrator privilege to edit it. The task of the application, TCFail, is to help you easily change the font fallback setting without knowing UNIX commands and the system names of the fonts. 

##  System Requirements

You need Mac OS X 10.6 Snow Leopard, of course.

## Usage

Select a font from the main window, click on the "Change!" button, and done. You may be asked to logout your system, the new font will take effect after logging in again.

## Build your own version

If you want to build the application by your self, Mac OS X 10.6 and Xocde 3.2 or higher version are required. You can download Xcode IDE free from Apple Developer Connection. You will be asked to regiter an ADC account.

It is quite easy to build the application:

1. Open TCFail.xcodeproj with Xcode.
2. Click on the "Build" or "Build and Go" button on the toolbar.
3. Done!