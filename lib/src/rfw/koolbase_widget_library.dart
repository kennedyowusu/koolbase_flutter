import 'package:flutter/material.dart';
import 'package:rfw/rfw.dart';
import 'rfw_models.dart';

LocalWidgetLibrary createKoolbaseWidgetLibrary() {
  return LocalWidgetLibrary(<String, LocalWidgetBuilder>{
    // ─── Layout ──────────────────────────────────────────────────────────
    'Column': (context, source) => Column(
          mainAxisAlignment: _mainAxisAlignment(
              source.v<String>(<Object>['mainAxisAlignment'])),
          crossAxisAlignment: _crossAxisAlignment(
              source.v<String>(<Object>['crossAxisAlignment'])),
          children: source.childList(<Object>['children']),
        ),
    'Row': (context, source) => Row(
          mainAxisAlignment: _mainAxisAlignment(
              source.v<String>(<Object>['mainAxisAlignment'])),
          crossAxisAlignment: _crossAxisAlignment(
              source.v<String>(<Object>['crossAxisAlignment'])),
          children: source.childList(<Object>['children']),
        ),
    'Stack': (context, source) => Stack(
          children: source.childList(<Object>['children']),
        ),
    'Container': (context, source) => Container(
          width: source.v<double>(<Object>['width']),
          height: source.v<double>(<Object>['height']),
          padding: _edgeInsets(source.v<double>(<Object>['padding'])),
          margin: _edgeInsets(source.v<double>(<Object>['margin'])),
          child: source.optionalChild(<Object>['child']),
        ),
    'Padding': (context, source) => Padding(
          padding: _edgeInsets(source.v<double>(<Object>['padding'])) ??
              EdgeInsets.zero,
          child: source.optionalChild(<Object>['child']),
        ),
    'SizedBox': (context, source) => SizedBox(
          width: source.v<double>(<Object>['width']),
          height: source.v<double>(<Object>['height']),
          child: source.optionalChild(<Object>['child']),
        ),
    'Expanded': (context, source) => Expanded(
          flex: source.v<int>(<Object>['flex']) ?? 1,
          child: source.child(<Object>['child']),
        ),
    'Center': (context, source) => Center(
          child: source.optionalChild(<Object>['child']),
        ),
    'SingleChildScrollView': (context, source) => SingleChildScrollView(
          child: source.optionalChild(<Object>['child']),
        ),

    // ─── Text ────────────────────────────────────────────────────────────
    'Text': (context, source) => Text(
          source.v<String>(<Object>['text']) ?? '',
          textAlign: _textAlign(source.v<String>(<Object>['textAlign'])),
        ),

    // ─── Material ────────────────────────────────────────────────────────
    'ElevatedButton': (context, source) => ElevatedButton(
          onPressed: source.voidHandler(<Object>['onPressed']),
          child: source.child(<Object>['child']),
        ),
    'TextButton': (context, source) => TextButton(
          onPressed: source.voidHandler(<Object>['onPressed']),
          child: source.child(<Object>['child']),
        ),
    'OutlinedButton': (context, source) => OutlinedButton(
          onPressed: source.voidHandler(<Object>['onPressed']),
          child: source.child(<Object>['child']),
        ),
    'Card': (context, source) => Card(
          child: source.optionalChild(<Object>['child']),
        ),
    'Divider': (context, source) => const Divider(),
    'CircularProgressIndicator': (context, source) =>
        const CircularProgressIndicator(),

    // ─── Koolbase primitives ─────────────────────────────────────────────
    'KoolbaseText': (context, source) {
      final styleKey = source.v<String>(<Object>['style']) ?? 'body';
      final theme = Theme.of(context);
      final textStyle = switch (styleKey) {
        'headline' => theme.textTheme.headlineMedium,
        'title' => theme.textTheme.titleLarge,
        'subtitle' => theme.textTheme.titleMedium,
        'caption' => theme.textTheme.bodySmall,
        _ => theme.textTheme.bodyMedium,
      };
      return Text(
        source.v<String>(<Object>['text']) ?? '',
        style: textStyle,
        textAlign: _textAlign(source.v<String>(<Object>['textAlign'])),
      );
    },

    'KoolbaseButton': (context, source) => ElevatedButton(
          onPressed: source.voidHandler(<Object>['onPressed']),
          child: Text(source.v<String>(<Object>['label']) ?? ''),
        ),

    'KoolbaseSpacer': (context, source) => SizedBox(
          height: source.v<double>(<Object>['height']) ?? 16.0,
          width: source.v<double>(<Object>['width']) ?? 0.0,
        ),

    'KoolbaseBadge': (context, source) {
      final label = source.v<String>(<Object>['label']) ?? '';
      final colorStr = source.v<String>(<Object>['color']) ?? 'primary';
      final theme = Theme.of(context);
      final color = switch (colorStr) {
        'error' => theme.colorScheme.error,
        'secondary' => theme.colorScheme.secondary,
        _ => theme.colorScheme.primary,
      };
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    },
  });
}

/// Custom widget library — extracts known keys from DataSource
LocalWidgetLibrary createCustomWidgetLibrary(List<KoolbaseRfwWidget> widgets) {
  return LocalWidgetLibrary(<String, LocalWidgetBuilder>{
    for (final w in widgets)
      w.name: (context, source) {
        final data = <String, dynamic>{
          'text': source.v<String>(<Object>['text']),
          'label': source.v<String>(<Object>['label']),
          'title': source.v<String>(<Object>['title']),
          'subtitle': source.v<String>(<Object>['subtitle']),
          'color': source.v<String>(<Object>['color']),
          'style': source.v<String>(<Object>['style']),
          'value': source.v<String>(<Object>['value']),
        }..removeWhere((_, v) => v == null);
        return w.builder(context, data);
      },
  });
}

// ─── Helpers ──────────────────────────────────────────────────────────────

MainAxisAlignment _mainAxisAlignment(String? value) => switch (value) {
      'center' => MainAxisAlignment.center,
      'end' => MainAxisAlignment.end,
      'spaceBetween' => MainAxisAlignment.spaceBetween,
      'spaceAround' => MainAxisAlignment.spaceAround,
      'spaceEvenly' => MainAxisAlignment.spaceEvenly,
      _ => MainAxisAlignment.start,
    };

CrossAxisAlignment _crossAxisAlignment(String? value) => switch (value) {
      'center' => CrossAxisAlignment.center,
      'end' => CrossAxisAlignment.end,
      'stretch' => CrossAxisAlignment.stretch,
      _ => CrossAxisAlignment.start,
    };

TextAlign _textAlign(String? value) => switch (value) {
      'center' => TextAlign.center,
      'end' => TextAlign.end,
      'justify' => TextAlign.justify,
      _ => TextAlign.start,
    };

EdgeInsets? _edgeInsets(double? value) {
  if (value == null) return null;
  return EdgeInsets.all(value);
}
