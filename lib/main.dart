import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pigallery2_android/core/services/api.dart';
import 'package:pigallery2_android/core/services/models/initial_server_data.dart';
import 'package:pigallery2_android/core/services/storage_helper.dart';
import 'package:pigallery2_android/core/viewmodels/home_model.dart';
import 'package:pigallery2_android/core/viewmodels/server_model.dart';
import 'package:pigallery2_android/ui/themes.dart';
import 'package:pigallery2_android/ui/views/home_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool allowBadCertificate = prefs.getBool('allowBadCertificate') ?? false;
  if (allowBadCertificate) {
    HttpOverrides.global = MyHttpOverrides();
  }
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
            return Center(
              child: SpinKitSpinningLines(
                color: CustomThemeData.oledColorScheme.secondary,
              ),
            );
          }

          return MultiProvider(
            providers: [
              Provider(create: (_) {
                return ApiService(
                  initialServerData: snapshot.data as InitialServerData,
                  storageHelper: storageHelper,
                );
              }),
              ChangeNotifierProvider<ServerModel>(
                create: ((context) => ServerModel(
                      Provider.of<ApiService>(context, listen: false),
                      storageHelper,
                    )),
              ),
              ChangeNotifierProvider<HomeModel>(
                create: ((context) {
                  return HomeModel(
                    Provider.of<ApiService>(context, listen: false),
                  );
                }),
              ),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'PiGallery2',
              themeMode: ThemeMode.dark,
              darkTheme: CustomThemeData.oledThemeData,
              home: HomeView(),
            ),
          );
        });
  }
}
