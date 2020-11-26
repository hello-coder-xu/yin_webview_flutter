// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;


import android.os.Build;
import android.os.Build.VERSION_CODES;
import android.webkit.CookieManager;
import android.webkit.CookieSyncManager;
import android.webkit.ValueCallback;
import android.net.Uri;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

class FlutterCookieManager implements MethodCallHandler {
    private final MethodChannel methodChannel;

    FlutterCookieManager(BinaryMessenger messenger) {
        methodChannel = new MethodChannel(messenger, "plugins.flutter.io/cookie_manager");
        methodChannel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(MethodCall methodCall, Result result) {
        switch (methodCall.method) {
            case "clearCookies":
                clearCookies(result);
                break;
            case "setCookies":
                setCookies(result, methodCall);
                break;
            default:
                result.notImplemented();
        }
    }

    void dispose() {
        methodChannel.setMethodCallHandler(null);
    }

    private static void clearCookies(final Result result) {
        CookieManager cookieManager = CookieManager.getInstance();
        final boolean hasCookies = cookieManager.hasCookies();
        if (Build.VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {
            cookieManager.removeAllCookies(
                    new ValueCallback<Boolean>() {
                        @Override
                        public void onReceiveValue(Boolean value) {
                            result.success(hasCookies);
                        }
                    });
        } else {
            cookieManager.removeAllCookie();
            result.success(hasCookies);
        }
    }


    private static void setCookies(final Result result, final MethodCall methodCall) {
        CookieManager cookieManager = CookieManager.getInstance();
        cookieManager.removeAllCookie();
        if (Build.VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {
            cookieManager.removeAllCookies(
                    new ValueCallback<Boolean>() {
                        @Override
                        public void onReceiveValue(Boolean value) {
                            addCookies(result, methodCall);
                        }
                    });
        } else {
            cookieManager.removeAllCookie();
            addCookies(result, methodCall);
        }
    }

    private static void addCookies(final Result result, MethodCall methodCall) {
        String cookieString = methodCall.argument("cookies");
        String url = methodCall.argument("url");
        Uri uri = Uri.parse(url);
        String domain = uri.getHost();
        CookieManager cookieManager = CookieManager.getInstance();
        if (cookieString != null) {
            String[] cookiesList = cookieString.split(";");
            if (cookiesList.length == 0) {
                cookieManager.setCookie(domain, "k=v");
            } else {
                for (String temp : cookiesList) {
                    cookieManager.setCookie(domain, temp);
                }
            }
            cookieManager.flush();
        }
        result.success(true);
    }
}
