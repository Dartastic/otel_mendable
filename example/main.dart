// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_mendable/otel_mendable.dart';

/// Traces Mendable calls with OpenTelemetry.
///
/// `otel_mendable` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Mendable call in
/// [tracedMendable]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'mendable-example');

  // Wraps a Mendable API call in a CLIENT span.
  final mendableId = await tracedMendable<String>(
    operation: 'chat.stream',
    invoke: () async {
      // Make the Mendable call here, then report what it returned.
      const id = 'mendable_8f3a2c';
      return const MendableCallResult(
          value: id,
          result: MendableResult(
              projectId: 'assistant',
              anonKey: 'anonymous_user_id',
              conversationId: 'conversation_8f3a2c',
              messageId: 'message_8f3a2c',
              requestType: 'chat',
              modelName: 'gpt-4o-mini',
              tokensIn: 128,
              tokensOut: 128,
              sourcesReturned: 1,
              confidence: 0.5,
              feedbackSubmitted: true,
              feedbackVote: 'up',
              crawledPagesDelta: 1,
              sourceConnectorKind: 'web',
              statusCode: 200));
    },
  );
  OTelLog.info('tracedMendable chat.stream returned $mendableId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutMendableInstrumentationAsync.
  await runWithoutMendableInstrumentationAsync(
    () => tracedMendable<String>(
      operation: 'chat.stream',
      invoke: () async {
        const id = 'mendable_8f3a2c';
        return const MendableCallResult(
            value: id,
            result: MendableResult(
                projectId: 'assistant',
                anonKey: 'anonymous_user_id',
                conversationId: 'conversation_8f3a2c',
                messageId: 'message_8f3a2c',
                requestType: 'chat',
                modelName: 'gpt-4o-mini',
                tokensIn: 128,
                tokensOut: 128,
                sourcesReturned: 1,
                confidence: 0.5,
                feedbackSubmitted: true,
                feedbackVote: 'up',
                crawledPagesDelta: 1,
                sourceConnectorKind: 'web',
                statusCode: 200));
      },
    ),
  );

  await OTel.shutdown();
}
