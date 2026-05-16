// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_mendable_suppression.dart';

const _tracerName = 'dartastic_otel_libs_mendable';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class MendableResult {
  const MendableResult({
    this.projectId,
    this.anonKey,
    this.conversationId,
    this.messageId,
    this.requestType,
    this.modelName,
    this.tokensIn,
    this.tokensOut,
    this.sourcesReturned,
    this.confidence,
    this.feedbackSubmitted,
    this.feedbackVote,
    this.crawledPagesDelta,
    this.sourceConnectorKind,
    this.statusCode,
  });

  /// Mendable project (`assistant` in Mendable terms).
  final String? projectId;

  /// Anonymous identifier supplied for end-user attribution (Mendable
  /// calls this `anonymous_user_id`).
  final String? anonKey;

  final String? conversationId;
  final String? messageId;

  /// `chat` / `search` / `rate_message` / `ingest` / `crawl_url`.
  final String? requestType;

  /// Model used (Mendable rotates between several — `gpt-4o-mini`,
  /// `gpt-4o`, `claude-3-5-sonnet`, etc.).
  final String? modelName;

  /// Token usage (`prompt` and `completion` token counts).
  final int? tokensIn;
  final int? tokensOut;

  /// Number of source citations the answer cites.
  final int? sourcesReturned;

  /// Mendable's confidence score (0.0-1.0) — useful for low-confidence
  /// routing.
  final double? confidence;

  /// `true` when the end user submitted feedback (thumbs up/down).
  final bool? feedbackSubmitted;

  /// `up` / `down`.
  final String? feedbackVote;

  /// Pages crawled on a `crawl_url` call.
  final int? crawledPagesDelta;

  /// `web` / `github` / `confluence` / `notion` / `slack` / `s3` /
  /// `google_drive` / `intercom` / `zendesk` / `text` / `pdf` /
  /// `discord` — ingestion source kind.
  final String? sourceConnectorKind;

  final int? statusCode;
}

class MendableCallResult<T> {
  const MendableCallResult({required this.value, this.result});
  final T value;
  final MendableResult? result;
}

/// Wraps a Mendable API call in a CLIENT span. [operation] is one of
/// `chat`, `chat.stream`, `search`, `conversations.new`,
/// `conversations.delete`, `message.rate`, `ingest.text`,
/// `ingest.pdf`, `ingest.url`, `crawl.url`, `sources.list`,
/// `sources.delete`, `analytics.events`.
Future<T> tracedMendable<T>({
  required String operation,
  required Future<MendableCallResult<T>> Function() invoke,
}) async {
  if (mendableInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'mendable',
    'rpc.method': operation,
    'mendable.operation': operation,
  };

  final span = _tracer().startSpan(
    'mendable $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.projectId != null) {
        extras.add(OTel.attributeString(
          'mendable.project.id',
          r.result!.projectId!,
        ));
      }
      if (r.result!.anonKey != null) {
        extras.add(OTel.attributeString(
          'mendable.anon_user.id',
          r.result!.anonKey!,
        ));
      }
      if (r.result!.conversationId != null) {
        extras.add(OTel.attributeString(
          'mendable.conversation.id',
          r.result!.conversationId!,
        ));
      }
      if (r.result!.messageId != null) {
        extras.add(OTel.attributeString(
          'mendable.message.id',
          r.result!.messageId!,
        ));
      }
      if (r.result!.requestType != null) {
        extras.add(OTel.attributeString(
          'mendable.request.type',
          r.result!.requestType!,
        ));
      }
      if (r.result!.modelName != null) {
        extras.add(OTel.attributeString(
          'mendable.model.name',
          r.result!.modelName!,
        ));
      }
      if (r.result!.tokensIn != null) {
        extras.add(OTel.attributeInt(
          'mendable.tokens.in',
          r.result!.tokensIn!,
        ));
      }
      if (r.result!.tokensOut != null) {
        extras.add(OTel.attributeInt(
          'mendable.tokens.out',
          r.result!.tokensOut!,
        ));
      }
      if (r.result!.sourcesReturned != null) {
        extras.add(OTel.attributeInt(
          'mendable.sources.returned',
          r.result!.sourcesReturned!,
        ));
      }
      if (r.result!.confidence != null) {
        extras.add(OTel.attributeDouble(
          'mendable.confidence',
          r.result!.confidence!,
        ));
      }
      if (r.result!.feedbackSubmitted != null) {
        extras.add(OTel.attributeBool(
          'mendable.feedback.submitted',
          r.result!.feedbackSubmitted!,
        ));
      }
      if (r.result!.feedbackVote != null) {
        extras.add(OTel.attributeString(
          'mendable.feedback.vote',
          r.result!.feedbackVote!,
        ));
      }
      if (r.result!.crawledPagesDelta != null) {
        extras.add(OTel.attributeInt(
          'mendable.crawled.pages_delta',
          r.result!.crawledPagesDelta!,
        ));
      }
      if (r.result!.sourceConnectorKind != null) {
        extras.add(OTel.attributeString(
          'mendable.source.connector_kind',
          r.result!.sourceConnectorKind!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Mendable HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
