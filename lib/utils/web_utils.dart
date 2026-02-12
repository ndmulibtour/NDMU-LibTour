// Create this file at: lib/utils/web_utils.dart

// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

/// Register platform views for web
void registerWebViewFactories() {
  // Register Google Maps embed view
  ui_web.platformViewRegistry.registerViewFactory(
    'google-maps-embed',
    (int viewId) {
      final iframe = html.IFrameElement()
        ..src =
            'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d15856.701312787516!2d124.82961490786025!3d6.499475322968497!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x32f81894a34e543f%3A0xf3131275609f854e!2sNotre%20Dame%20of%20Marbel%20University!5e1!3m2!1sen!2sph!4v1769222987127!5m2!1sen!2sph'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true
        ..setAttribute('loading', 'lazy')
        ..setAttribute('referrerpolicy', 'no-referrer-when-downgrade');

      return iframe;
    },
  );
}
