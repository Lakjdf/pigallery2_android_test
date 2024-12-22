# PiGallery2 Android Test

This is a basic Android app for [PiGallery2](https://github.com/bpatrik/pigallery2) implemented using Flutter.

The goal of this app is to provide a native look & feel when browsing PiGallery2 on Android.
Note that this project is labelled as a test project since I use it to test out Flutter features & packages.
It might be unstable and will likely never adopt all the features of the webapp.

Currently supported features:
- Browse directories
- View images, videos, motion photos
- "any_text" search
- Directory flattening
- Share media using Android's share dialog
- View media from x years ago

There's no metadata displayed at the moment.

Only tested with PiGallery2 v1.9.5 & v2.0.0.

## Packages used

- [http](https://pub.dev/packages/http) - make HTTP requests
- [provider](https://pub.dev/packages/provider) - state management

- [shared_preferences](https://pub.dev/packages/shared_preferences) - persist server configurations
- [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) - store credentials
- [path_provider](https://pub.dev/packages/path_provider) - retrieve path to temporarily store media
- [cached_network_image](https://pub.dev/packages/cached_network_image) - cache & download thumbnails & images
- [flutter_cache_manager](https://pub.dev/packages/flutter_cache_manager) - configure cache & retrieve cached entries

- [collection](https://pub.dev/packages/collection) - natural sorting
- [quiver](https://pub.dev/packages/quiver) - some convenient data structures
- [path](https://pub.dev/packages/path) - concatenate api paths
- [async](https://pub.dev/packages/async) - utility classes for async operations
- [intl](https://pub.dev/packages/intl) - DateTime formatting
- [logging](https://pub.dev/packages/logging) - basic logging
- [mutex](https://pub.dev/packages/mutex) - convenience methods for mutual exclusion
- [mime](https://pub.dev/packages/mime) - distinguish between images and videos

- [dynamic_color](https://pub.dev/packages/dynamic_color) - Retrieve dynamic color scheme from device
- [share_plus](https://pub.dev/packages/share_plus) - open dialog to share downloaded media
- [motion_photos](https://pub.dev/packages/motion_photos) - extract videos from motion photos

- [photo_view](https://pub.dev/packages/photo_view) - display images with zoom gestures
- [media_kit](https://pub.dev/packages/media_kit) - video playback using libmpv

- [backdrop](https://pub.dev/packages/backdrop) - show a back layer for some settings
- [visibility_detector](https://pub.dev/packages/visibility_detector) - detect visibility fraction to update video volume
- [flutter_inappwebview](https://pub.dev/packages/flutter_inappwebview) - show admin panel within a WebView that respects cookies

- [flutter_spinkit](https://pub.dev/packages/flutter_spinkit) - loading animations
- [ionicons](https://pub.dev/packages/ionicons) - icon set

## Linux build

The linux build exists for development purposes and is not fully functional.

Required dependencies in addition to the flutter linux setup:
`sudo apt-get install libmpv-dev mpv libsecret-1-dev libjsoncpp-dev`

## Credits

The application logo is from [PiGallery2](https://github.com/bpatrik/pigallery2), which is licensed under the MIT License:

>The MIT License (MIT)
>
>Copyright (c) 2016 bpatrik
>
>Permission is hereby granted, free of charge, to any person obtaining a copy
>of this software and associated documentation files (the "Software"), to deal
>in the Software without restriction, including without limitation the rights
>to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
>copies of the Software, and to permit persons to whom the Software is
>furnished to do so, subject to the following conditions:
>
>The above copyright notice and this permission notice shall be included in all
>copies or substantial portions of the Software.
>
>THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
>IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
>FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
>AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
>LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
>OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
>SOFTWARE.