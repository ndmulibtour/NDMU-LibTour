import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768 &&
      MediaQuery.of(context).size.width < 1024;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  static double getWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double getHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // Get responsive value based on screen size
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  // Get responsive font size
  static double fontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    required double desktop,
  }) {
    return responsive<double>(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  // Get responsive padding
  static EdgeInsets padding(
    BuildContext context, {
    required EdgeInsets mobile,
    EdgeInsets? tablet,
    required EdgeInsets desktop,
  }) {
    return responsive<EdgeInsets>(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  // Get responsive spacing
  static double spacing(
    BuildContext context, {
    required double mobile,
    double? tablet,
    required double desktop,
  }) {
    return responsive<double>(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}
