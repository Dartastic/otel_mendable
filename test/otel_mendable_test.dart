// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_mendable/otel_mendable.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_mendable-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('chat records sources + confidence + token usage', () async {
    await tracedMendable<String>(
      operation: 'chat',
      invoke: () async => const MendableCallResult(
        value: 'ok',
        result: MendableResult(
          projectId: 'proj_1',
          anonKey: 'anon_42',
          conversationId: 'conv_1',
          messageId: 'msg_1',
          requestType: 'chat',
          modelName: 'gpt-4o-mini',
          tokensIn: 1200,
          tokensOut: 480,
          sourcesReturned: 5,
          confidence: 0.87,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('mendable chat')!);
    expect(a['mendable.project.id'], 'proj_1');
    expect(a['mendable.model.name'], 'gpt-4o-mini');
    expect(a['mendable.sources.returned'], 5);
    expect(a['mendable.confidence'], 0.87);
    expect(a['mendable.tokens.out'], 480);
  });

  test('crawl.url records pages delta + connector', () async {
    await tracedMendable<String>(
      operation: 'crawl.url',
      invoke: () async => const MendableCallResult(
        value: 'ok',
        result: MendableResult(
          requestType: 'crawl_url',
          sourceConnectorKind: 'web',
          crawledPagesDelta: 47,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('mendable crawl.url')!);
    expect(a['mendable.source.connector_kind'], 'web');
    expect(a['mendable.crawled.pages_delta'], 47);
  });

  test('feedback records vote', () async {
    await tracedMendable<String>(
      operation: 'message.rate',
      invoke: () async => const MendableCallResult(
        value: 'ok',
        result: MendableResult(
          messageId: 'msg_2',
          feedbackSubmitted: true,
          feedbackVote: 'down',
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('mendable message.rate')!);
    expect(a['mendable.feedback.submitted'], true);
    expect(a['mendable.feedback.vote'], 'down');
  });

  test('HTTP 429 sets span error', () async {
    await tracedMendable<String>(
      operation: 'chat',
      invoke: () async => const MendableCallResult(
        value: 'ok',
        result: MendableResult(statusCode: 429),
      ),
    );
    expect(
      spans.findSpanByName('mendable chat')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutMendableInstrumentationAsync(() async {
      await tracedMendable<String>(
        operation: 'search',
        invoke: () async => const MendableCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('mendable '), isEmpty);
  });
}
