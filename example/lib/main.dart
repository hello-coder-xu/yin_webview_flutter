// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(MaterialApp(home: WebViewExample()));

const String kNavigationExamplePage = '''
<!DOCTYPE html><html>
<head><title>Navigation Delegate Example</title></head>
<body>
<p>
The navigation delegate is set to block navigation to the youtube website.
</p>
<ul>
<ul><a href="https://www.youtube.com/">https://www.youtube.com/</a></ul>
<ul><a href="https://www.google.com/">https://www.google.com/</a></ul>
</ul>
</body>
</html>
''';

// String initialUrl='https://flutter.dev';
String initialUrl = 'https://m.debug.8591.com.hk';

class WebViewExample extends StatefulWidget {
  @override
  _WebViewExampleState createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  final Completer<WebViewController> _controller = Completer<WebViewController>();
  String title = '';

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        // This drop down menu demonstrates that Flutter widgets can be shown over the web view.
        actions: <Widget>[
          NavigationControls(_controller.future),
          SampleMenu(_controller.future),
        ],
      ),
      body: Builder(builder: (BuildContext context) {
        return WebView(
          initialUrl: initialUrl,
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            print('test onWebViewCreated');
            _controller.complete(webViewController);
          },
          navigationDelegate: (NavigationRequest request) {
            print('test navigationDelegate');
            if (request.url.startsWith('https://www.youtube.com/')) {
              print('blocking navigation to $request}');
              return NavigationDecision.prevent;
            }
            print('allowing navigation to $request');
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            print('Page started loading: $url');
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
          },
          webChromeClient: (String url, String title) {
            print('test webChromeClient title=$title url=$url');
            this.title = title ?? '';
            if (mounted) setState(() {});
          },
          gestureNavigationEnabled: true,
        );
      }),
    );
  }
}

enum MenuOptions {
  showUserAgent,
  listCookies,
  clearCookies,
  addToCache,
  addToCookies,
  listCache,
  clearCache,
  navigationDelegate,
}

class SampleMenu extends StatelessWidget {
  SampleMenu(this.controller);

  final Future<WebViewController> controller;
  final CookieManager cookieManager = CookieManager();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: controller,
      builder: (BuildContext context, AsyncSnapshot<WebViewController> controller) {
        return PopupMenuButton<MenuOptions>(
          onSelected: (MenuOptions value) {
            switch (value) {
              case MenuOptions.showUserAgent:
                _onShowUserAgent(controller.data, context);
                break;
              case MenuOptions.listCookies:
                _onListCookies(controller.data, context);
                break;
              case MenuOptions.addToCookies:
                _onAddToCookies(controller.data, context);
                break;
              case MenuOptions.clearCookies:
                _onClearCookies(context);
                break;
              case MenuOptions.addToCache:
                _onAddToCache(controller.data, context);
                break;
              case MenuOptions.listCache:
                _onListCache(controller.data, context);
                break;
              case MenuOptions.clearCache:
                _onClearCache(controller.data, context);
                break;
              case MenuOptions.navigationDelegate:
                _onNavigationDelegateExample(controller.data, context);
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuItem<MenuOptions>>[
            PopupMenuItem<MenuOptions>(
              value: MenuOptions.showUserAgent,
              child: const Text('Show user agent'),
              enabled: controller.hasData,
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.addToCookies,
              child: Text('Add to cookies'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.listCookies,
              child: Text('List cookies'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.clearCookies,
              child: Text('Clear cookies'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.addToCache,
              child: Text('Add to cache'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.listCache,
              child: Text('List cache'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.clearCache,
              child: Text('Clear cache'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.navigationDelegate,
              child: Text('Navigation Delegate example'),
            ),
          ],
        );
      },
    );
  }

  void _onShowUserAgent(WebViewController controller, BuildContext context) async {
    // Send a message with the user agent string to the Toaster JavaScript channel we registered
    // with the WebView.
    final String userAgent = await controller.evaluateJavascript('navigator.userAgent');
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('userAgent:'),
          _getCookieList(userAgent),
        ],
      ),
    ));
  }

  void _onListCookies(WebViewController controller, BuildContext context) async {
    final String cookies = await controller.evaluateJavascript('document.cookie');
    // ignore: deprecated_member_use
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Cookies:'),
          _getCookieList(cookies),
        ],
      ),
    ));
  }

  void _onAddToCookies(WebViewController controller, BuildContext context) {
    Map<String, String> hashMap = HashMap<String, String>();
    hashMap['base_domain'] = '.m.debug.8591.com.hk';
    hashMap['access_token_develop'] =
        'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIyIiwianRpIjoiYWI1MTY2ZjFjNDY0OTFiNDg0YzY1YjhhOTYyYjJmY2E1NTlkZDViYTUzZGZkNjJjOGVlZjI2YjdmMjdhOWMzMTYxYmZiNGJhODNjNzZhOGQiLCJpYXQiOjE2MDYzNzM3NTksIm5iZiI6MTYwNjM3Mzc1OSwiZXhwIjoxNjA2MzgwOTU4LCJzdWIiOiIxMDEwMDA5Iiwic2NvcGVzIjpbIioiXX0.k9Dmkbw1xLzQ3-6fK-4P3VDx7XivRyfaNMwOqjkfQCYaa5n83WdVB3R97LP6BCsJcV7dOPMJAMqcLvL63fL0RiWQjUF_n51435-UcsudZBJmr8NSi74NeHl6e891xfydzLKqlFltlF1RrXOygpJYT6AZ7_4QXY0xgJGqvo6eXqkPwZ0f6mcI01dM-z24Okzkk4as4uwnzFAOzLhzGgrG0odRtW3eYtMzJoADiJukS3br8Ui-gtSZrkzZd6wDWOmHYKmDO_MHj-CSt4tDq4_gFe6CJSIk4SEmggFsHnJrRogdS_VnnwtVYu51qg7ffsNgn0HbHaRzwKXJPuLcEdsaMC_299vZ1CS6B-PN5Re9dq9igcG3sf183HVLJAz7DgOBLYGJYuEb1KN0ZmnUCpXAjvMqmYrENiE7UuTqpK6Xo-O1evUZBsbAxy0SDjsRYQOjYW4kMVLDZHLloOiVX1ZpDI6RLbh0BgkSFXWLUlAb5JicsSVMoNr-nqrDhZy2H89auSKpVmG0ZyhFxNhgSzFB6RGZcU07IkXk820495zkKSV1ookzbcvxh2gS3IacaJ0y26dHhSOdbPe66bdr_VoaFC052KNRbVxXps9LwPxdBml07pIV2qssa810zeWf-L4KzTtXYev2-s230aRMdeMdJMljY4G9ECcJBTocyQmOg_4';
    hashMap['refresh_token_develop'] =
        'def50200a1253356ad3308d986b1c2c4b9d9c1f231031f1ea96b4b7feddf3b4775d5ff857bbbb7799e9b6289b9e6e671329c8442ffa1561bada99c4c80f6add18423cde7304946034b5a4d484dce671c47a0ba231d820b6cca5a2793f7f449f714f0109553acd34a121e016d4f9c2720228a8d78cf8d87555f5eb9d855f1893ab89bb9e1f90a8d69cccd244a5439b0ffe44e8004c781d09a1274547c963421b2759e9413ccb4fdd1c5b8cd2734da48510ab4d58b4f811a7da0414656dd7389ec25c4503254af058ad108ce5290f74e663ab4440c7fa79913aa1ef2323a6323aa082ca0c4bfeefb76f2376ff909f133c3f2ea2e661606356c005211fbfef2a24e4e0979cdeb2f9ee7fee43fc7f0b5b7d9053c84cb2c4038d12c560e7affd8bdba88a818d874c5876799c9ada2137507eba374b1792d4f214bdfa29ee9b3a4bad1c60a9810f08838ca841fda1cd41699f329d713dd5a77218345eb9709362982763c0bc0b4e30bca4dc8e0';

    hashMap.forEach((key, value) async {
      await controller.evaluateJavascript('document.cookie="$key=$value;"');
    });
    controller.reload();
    // ignore: deprecated_member_use
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Cookies:设置成功'),
        ],
      ),
    ));
  }

  void _onAddToCache(WebViewController controller, BuildContext context) async {
    await controller
        .evaluateJavascript('caches.open("test_caches_entry"); localStorage["test_localStorage"] = "dummy_entry";');
    // ignore: deprecated_member_use
    Scaffold.of(context).showSnackBar(const SnackBar(
      content: Text('Added a test entry to cache.'),
    ));
  }

  void _onListCache(WebViewController controller, BuildContext context) async {
    await controller.evaluateJavascript('caches.keys()'
        '.then((cacheKeys) => JSON.stringify({"cacheKeys" : cacheKeys, "localStorage" : localStorage}))'
        '.then((caches) => Toaster.postMessage(caches))');
  }

  void _onClearCache(WebViewController controller, BuildContext context) async {
    await controller.clearCache();
    // ignore: deprecated_member_use
    Scaffold.of(context).showSnackBar(const SnackBar(
      content: Text("Cache cleared."),
    ));
  }

  void _onClearCookies(BuildContext context) async {
    final bool hadCookies = await cookieManager.clearCookies();
    String message = 'There were cookies. Now, they are gone!';
    if (!hadCookies) {
      message = 'There are no cookies.';
    }
    // ignore: deprecated_member_use
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  void _onNavigationDelegateExample(WebViewController controller, BuildContext context) async {
    final String contentBase64 = base64Encode(const Utf8Encoder().convert(kNavigationExamplePage));
    await controller.loadUrl('data:text/html;base64,$contentBase64');
  }

  Widget _getCookieList(String cookies) {
    if (cookies == null || cookies == '""') {
      return Container();
    }
    final List<String> cookieList = cookies.split(';');
    final Iterable<Text> cookieWidgets = cookieList.map((String cookie) => Text(cookie));
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: cookieWidgets.toList(),
    );
  }
}

class NavigationControls extends StatelessWidget {
  const NavigationControls(this._webViewControllerFuture) : assert(_webViewControllerFuture != null);

  final Future<WebViewController> _webViewControllerFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: _webViewControllerFuture,
      builder: (BuildContext context, AsyncSnapshot<WebViewController> snapshot) {
        final bool webViewReady = snapshot.connectionState == ConnectionState.done;
        final WebViewController controller = snapshot.data;
        return Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: !webViewReady
                  ? null
                  : () async {
                      if (await controller.canGoBack()) {
                        await controller.goBack();
                      } else {
                        // ignore: deprecated_member_use
                        Scaffold.of(context).showSnackBar(
                          const SnackBar(content: Text("No back history item")),
                        );
                        return;
                      }
                    },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: !webViewReady
                  ? null
                  : () async {
                      if (await controller.canGoForward()) {
                        await controller.goForward();
                      } else {
                        // ignore: deprecated_member_use
                        Scaffold.of(context).showSnackBar(
                          const SnackBar(content: Text("No forward history item")),
                        );
                        return;
                      }
                    },
            ),
            IconButton(
              icon: const Icon(Icons.replay),
              onPressed: !webViewReady
                  ? null
                  : () {
                      controller.reload();
                    },
            ),
          ],
        );
      },
    );
  }
}
