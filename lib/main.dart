import 'dart:io';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:pigallery2_android/core/services/api.dart';
import 'package:pigallery2_android/core/services/models/initial_server_data.dart';
import 'package:pigallery2_android/core/services/storage_helper.dart';
import 'package:pigallery2_android/core/viewmodels/home_model.dart';
import 'package:pigallery2_android/core/viewmodels/server_model.dart';
import 'package:pigallery2_android/core/viewmodels/global_settings_model.dart';
import 'package:pigallery2_android/core/viewmodels/top_picks_model.dart';
import 'package:pigallery2_android/ui/themes.dart';
import 'package:pigallery2_android/ui/views/home_view.dart';
import 'package:pigallery2_android/ui/widgets/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> clearDownloadedFiles() {
  return getTemporaryDirectory().then((value) => value.delete(recursive: true));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool allowBadCertificate = prefs.getBool('allowBadCertificate') ?? false;
  if (allowBadCertificate) {
    HttpOverrides.global = MyHttpOverrides();
  }
  clearDownloadedFiles();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    StorageHelper storageHelper = StorageHelper();
    return FutureBuilder(
        future: storageHelper.init(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingIndicator();
          }

          return MultiProvider(
            providers: [
              Provider<ApiService>(create: (_) {
                return PiGallery2ApiAuthWrapper(
                  initialServerData: snapshot.data as InitialServerData,
                  storageHelper: storageHelper,
                );
              }),
              ChangeNotifierProvider<ServerModel>(
                create: ((context) {
                  return ServerModel(
                    Provider.of<ApiService>(context, listen: false),
                    storageHelper,
                  );
                }),
              ),
              ChangeNotifierProvider<HomeModel>(
                create: ((context) {
                  return HomeModel(
                    Provider.of<ApiService>(context, listen: false),
                    storageHelper,
                  );
                }),
              ),
              ChangeNotifierProvider<GlobalSettingsModel>(
                create: ((context) {
                  return GlobalSettingsModel(storageHelper);
                }),
              ),
              ChangeNotifierProxyProvider<GlobalSettingsModel, TopPicksModel>(
                create: ((context) {
                  return TopPicksModel(Provider.of<ApiService>(context, listen: false));
                }),
                update: (BuildContext context, GlobalSettingsModel model, TopPicksModel? previous) {
                  if (previous == null) {
                    return TopPicksModel(Provider.of<ApiService>(context, listen: false));
                  }
                  return previous..fetchTopPicks(model.topPicksDaysLength);
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
        });
  }
}
