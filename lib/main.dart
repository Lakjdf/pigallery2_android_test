import 'dart:io';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:media_kit/media_kit.dart';
import 'package:pigallery2_android/data/backend/api_service.dart';
import 'package:pigallery2_android/data/repositories/album_repository.dart';
import 'package:pigallery2_android/data/repositories/sort_options_repository.dart';
import 'package:pigallery2_android/data/storage/credential_storage.dart';
import 'package:pigallery2_android/data/backend/pigallery2_api_auth_wrapper.dart';
import 'package:pigallery2_android/data/repositories/item_repository.dart';
import 'package:pigallery2_android/data/repositories/media_repository.dart';
import 'package:pigallery2_android/data/repositories/server_repository.dart';
import 'package:pigallery2_android/data/storage/pigallery2_image_cache.dart';
import 'package:pigallery2_android/data/storage/session_storage.dart';
import 'package:pigallery2_android/data/storage/shared_prefs_storage.dart';
import 'package:pigallery2_android/data/storage/storage_key.dart';
import 'package:pigallery2_android/domain/repositories/album_repository.dart';
import 'package:pigallery2_android/domain/repositories/item_repository.dart';
import 'package:pigallery2_android/domain/repositories/media_repository.dart';
import 'package:pigallery2_android/domain/repositories/server_repository.dart';
import 'package:pigallery2_android/domain/repositories/sort_options_repository.dart';
import 'package:pigallery2_android/ui/app_bar/viewmodels/app_bar_model.dart';
import 'package:pigallery2_android/ui/app_bar/viewmodels/app_bar_scroll_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/photo_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_models_provider.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_navigator_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_state_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/web_view_model.dart';
import 'package:pigallery2_android/ui/settings/viewmodels/add_server_model.dart';
import 'package:pigallery2_android/ui/settings/viewmodels/server_model.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/image_preloader.dart';
import 'package:pigallery2_android/util/extensions.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/global_settings_model.dart';
import 'package:pigallery2_android/ui/top_picks/viewmodels/top_picks_model.dart';
import 'package:pigallery2_android/ui/themes.dart';
import 'package:pigallery2_android/ui/home/views/home_view.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'util/system_ui.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class MyWidgetsBinding extends WidgetsFlutterBinding {
  @override
  ImageCache createImageCache() => PiGallery2ImageCache();
}

void setupLogging() {
  if (kDebugMode) {
    Logger.root.level = Level.ALL;
  } else {
    Logger.root.level = Level.INFO;
  }
  Logger.root.onRecord.listen((record) {
    final errorMessage = record.error?.let((it) => ': $it\n${record.stackTrace}') ?? '';
    // ignore: avoid_print
    print('${record.level.name}: ${record.loggerName}: ${record.message}$errorMessage');
  });
}

void main() async {
  MyWidgetsBinding();
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  SharedPrefsStorage storage = SharedPrefsStorage();
  await storage.init();
  bool allowBadCertificate = storage.get(StorageKey.allowBadCertificates);
  if (allowBadCertificate) {
    HttpOverrides.global = MyHttpOverrides();
  }
  setupLogging();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  FlutterSecureStorage secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  SessionStorage sessionStorage = SessionStorage(secureStorage);
  await sessionStorage.init();
  runApp(MyApp(storage, secureStorage, sessionStorage));
}

class MyApp extends StatelessWidget {
  final SharedPrefsStorage _storage;
  late final CredentialStorage _credentialStorage;
  late final SessionStorage _sessionStorage;
  late final GlobalSettingsModel _settingsModel;

  MyApp(this._storage, FlutterSecureStorage secureStorage, this._sessionStorage, {super.key}) {
    _credentialStorage = CredentialStorage(secureStorage);
    _settingsModel = GlobalSettingsModel(_storage);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SharedPrefsStorage>(
          create: (context) {
            return _storage;
          },
        ),
        Provider<ServerRepository>(
          create: (context) {
            return ServerRepositoryImpl(_storage, _credentialStorage, _sessionStorage);
          },
        ),
        Provider<ApiService>(
          create: (context) {
            return PiGallery2ApiAuthWrapper(_credentialStorage, _sessionStorage, context.read());
          },
        ),
        Provider<ItemRepository>(
          create: (context) {
            return ItemRepositoryImpl(context.read());
          },
        ),
        Provider<AlbumRepository>(
          create: (context) {
            return AlbumRepositoryImpl(context.read());
          },
        ),
        Provider<MediaRepository>(
          create: (context) {
            return MediaRepositoryImpl(context.read());
          },
        ),
        Provider<SortOptionsRepository>(
          create: (context) {
            return SortOptionsRepositoryImpl(_storage);
          },
        ),
        Provider<ImagePreloader>(
          create: (context) {
            return ImagePreloader(context.read(), context);
          },
        ),
        // needs to be defined here already since the photo view
        // is part of the hero animation to the fullscreen view
        ChangeNotifierProvider<PhotoModel>(create: ((context) => PhotoModel(context.read(), context.read()))),
        ChangeNotifierProvider<VideoModel>(create: ((context) => VideoModel(context.read()))),
        ChangeNotifierProvider<ServerModel>(
          create: ((context) {
            return ServerModel(Provider.of<ServerRepository>(context, listen: false));
          }),
        ),
        ChangeNotifierProvider<AddServerModel>(
          create: ((context) {
            return AddServerModel(context.read(), context.read());
          }),
        ),
        ChangeNotifierProvider<TabStateModel>(
          create: ((context) {
            return TabStateModel();
          }),
        ),
        ChangeNotifierProvider<TabModelsProvider>(
          create: ((context) {
            return TabModelsProvider(
              context.read(),
              GalleryModel(context.read(), context.read(), context.read(), false),
              GalleryModel(context.read(), context.read(), context.read(), true),
            );
          }),
        ),
        ChangeNotifierProvider<WebViewModel>(
          create: ((context) {
            return WebViewModel(context.read());
          }),
        ),
        ChangeNotifierProvider<AppBarModel>(
          create: ((context) {
            return AppBarModel(context.read(), context.read(), context.read());
          }),
        ),
        ChangeNotifierProvider<AppBarScrollModel>(
          create: ((context) => AppBarScrollModel()),
        ),
        ChangeNotifierProvider<GlobalSettingsModel>(create: ((context) => _settingsModel)),
        ChangeNotifierProxyProvider<GlobalSettingsModel, TopPicksModel>(
          create: ((context) {
            return TopPicksModel(Provider.of<ItemRepository>(context, listen: false), context.read(), _storage);
          }),
          update: (BuildContext context, GlobalSettingsModel model, TopPicksModel? previous) {
            if (previous == null) {
              return TopPicksModel(Provider.of<ItemRepository>(context, listen: false), context.read(), _storage);
            }
            return previous..update(model.topPicksDaysLength, model.showTopPicks);
          },
        ),
        ChangeNotifierProvider<TabNavigatorModel>(
          create: ((context) {
            return TabNavigatorModel(context.read(), context.read(), context.read(), context.read());
          }),
          lazy: false,
        ),
      ],
      child: Selector<GlobalSettingsModel, bool>(
        selector: (context, model) => model.useMaterial3,
        builder: (context, useMaterial3, child) => DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            ThemeData themeData = CustomThemeData.oledThemeData;
            if (useMaterial3 && darkDynamic != null) {
              ColorScheme colorScheme = darkDynamic.harmonized();
              themeData = ThemeData(
                useMaterial3: true,
                colorScheme: colorScheme,
                dividerTheme: DividerThemeData(color: colorScheme.secondaryContainer),
                scrollbarTheme: ScrollbarThemeData(
                  thumbVisibility: WidgetStateProperty.all(true),
                  thumbColor: WidgetStateProperty.all(colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                ),
                tabBarTheme: CustomThemeData.tabBarTheme(colorScheme),
              );
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              SystemUi.setDefaultSystemBarColors(context);
            });
            return RefreshConfiguration(
              // https://github.com/peng8350/flutter_pulltorefresh/issues/656#issuecomment-2966048816
              springDescription: const SpringDescription(
                mass: 1,
                stiffness: 364.718677686,
                damping: 35.2,
              ),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'PiGallery2',
                themeMode: ThemeMode.dark,
                theme: themeData,
                darkTheme: themeData,
                home: HomeView(),
              ),
            );
          },
        ),
      ),
    );
  }
}
