# PiGallery2 Android Test

This is a basic Android app for [PiGallery2](https://github.com/bpatrik/pigallery2) implemented using Flutter.

It doesn't display any metadata and only supports a simple 'any_text' search.

Only tested with PiGallery2 v1.9.5 & v2.0.0.

## Packages used

- [http](https://pub.dev/packages/http) - make HTTP requests
- [provider](https://pub.dev/packages/provider) - state management
- [photo_view](https://pub.dev/packages/photo_view) - display images with zoom gestures
- [shared_preferences](https://pub.dev/packages/shared_preferences) - persist server configurations
- [flutter_spinkit](https://pub.dev/packages/flutter_spinkit) - loading animations
- [cached_network_image](https://pub.dev/packages/cached_network_image) - cache thumbnails
- [mime](https://pub.dev/packages/mime) - distinguish between images and videos
- [better_player](https://pub.dev/packages/better_player) - display videos with HTTP headers
- [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) - store credentials
- [flutter_inappwebview](https://pub.dev/packages/flutter_inappwebview) - show admin panel within a webview that respects cookies
- [path_provider](https://pub.dev/packages/path_provider) - retrieve path to temporarily store media
- [share_plus](https://pub.dev/packages/share_plus) - open dialog to share downloaded media
- [collection](https://pub.dev/packages/collection) - natural sorting
- [dynamic_color](https://pub.dev/packages/dynamic_color) - Retrieve dynamic color scheme from device
- [backdrop](https://pub.dev/packages/backdrop) - show a back layer for some settings
- [path](https://pub.dev/packages/path) - concatenate api paths
- [async](https://pub.dev/packages/async) - utility classes for async operations

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