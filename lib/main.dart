import 'dart:io';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:pigallery2_android/data/backend/api_service.dart';
import 'package:pigallery2_android/data/storage/credential_storage.dart';
import 'package:pigallery2_android/data/backend/pigallery2_api_auth_wrapper.dart';
import 'package:pigallery2_android/data/repositories/item_repository.dart';
import 'package:pigallery2_android/data/repositories/media_repository.dart';
import 'package:pigallery2_android/data/repositories/server_repository.dart';
import 'package:pigallery2_android/data/storage/pigallery2_image_cache.dart';
import 'package:pigallery2_android/data/storage/shared_prefs_storage.dart';
import 'package:pigallery2_android/data/storage/storage_key.dart';
import 'package:pigallery2_android/domain/repositories/item_repository.dart';
import 'package:pigallery2_android/domain/repositories/media_repository.dart';
import 'package:pigallery2_android/domain/repositories/server_repository.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/photo_model.dart';
import 'package:pigallery2_android/util/path.dart';
import 'package:pigallery2_android/ui/home/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/server_settings/viewmodels/server_model.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/global_settings_model.dart';
import 'package:pigallery2_android/ui/top_picks/viewmodels/top_picks_model.dart';
import 'package:pigallery2_android/ui/themes.dart';
import 'package:pigallery2_android/ui/home/views/home_view.dart';
import 'package:provider/provider.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
class MyWidgetsBinding extends WidgetsFlutterBinding {
   @override
   ImageCache createImageCache() => PiGallery2ImageCache();
 }

void main() async {
  MyWidgetsBinding();
  WidgetsFlutterBinding.ensureInitialized();
  SharedPrefsStorage storage = SharedPrefsStorage();
  await storage.init();
  bool allowBadCertificate = storage.get(StorageKey.allowBadCertificates);
  if (allowBadCertificate) {
    HttpOverrides.global = MyHttpOverrides();
  }
  Downloads.clear();
  runApp(MyApp(storage));
}

class MyApp extends StatelessWidget {
  final SharedPrefsStorage _storage;
  late final CredentialStorage _credentialStorage;
  late final ApiService _apiService;

  MyApp(this._storage, {super.key}) {
    _credentialStorage = CredentialStorage();
    _apiService = PiGallery2ApiAuthWrapper(
      _storage,
      _credentialStorage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SharedPrefsStorage>(create: (context) {
          return _storage;
        }),
        Provider<ItemRepository>(create: (context) {
          return ItemRepositoryImpl(_apiService);
        }),
        Provider<MediaRepository>(create: (context) {
          return MediaRepositoryImpl(_apiService);
        }),
        Provider<ServerRepository>(create: (context) {
          return ServerRepositoryImpl(
            _apiService,
            _storage,
            _credentialStorage,
          );
        }),
        // needs to be defined here already since the photo view
        // is part of the hero animation to the fullscreen view
        ChangeNotifierProvider<PhotoModel>(
          create: ((context) => PhotoModel(context.read())),
        ),
        ChangeNotifierProvider<ServerModel>(
          create: ((context) {
            return ServerModel(Provider.of<ServerRepository>(context, listen: false));
          }),
        ),
        ChangeNotifierProvider<HomeModel>(
          create: ((context) {
            return HomeModel(
              Provider.of<ItemRepository>(context, listen: false),
              _storage,
            );
          }),
        ),
        ChangeNotifierProvider<GlobalSettingsModel>(
          create: ((context) {
            return GlobalSettingsModel(_storage);
          }),
        ),
        ChangeNotifierProxyProvider<GlobalSettingsModel, TopPicksModel>(
          create: ((context) {
            return TopPicksModel(Provider.of<ItemRepository>(context, listen: false), _storage);
          }),
          update: (BuildContext context, GlobalSettingsModel model, TopPicksModel? previous) {
            if (previous == null) {
              return TopPicksModel(Provider.of<ItemRepository>(context, listen: false), _storage);
            }
            return previous..update(model.topPicksDaysLength, model.showTopPicks);
          },
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
                  thumbVisibility: MaterialStateProperty.all(true),
                  thumbColor: MaterialStateProperty.all(colorScheme.onSurfaceVariant.withOpacity(0.4)),
                ),
              );
            }
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'PiGallery2',
              themeMode: ThemeMode.dark,
              theme: themeData,
              darkTheme: themeData,
              home: HomeView(0),
            );
          },
        ),
      ),
    );
  }
}
