# PiGallery2 Android Test

This is a basic android app capable of displaying images and videos of a PiGallery2 instance - no metadata, search, albums, etc.

The mobile view of the PiGallery2 frontend is great. I only created this app to get more familiar with Flutter.

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