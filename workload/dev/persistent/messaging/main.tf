# account outbox → SNS transactions → SQS notification (+ DLQ) → notification service (app spec §7.1)

locals {
  name = "minibank-dev"
}

resource "aws_sns_topic" "transactions" {
  name = "${local.name}-transactions"

  # AWS managed key: no key to pay for, works with SQS subscribers
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sqs_queue" "notification_dlq" {
  name = "${local.name}-notification-dlq"

  # longer than the main queue: a moved message keeps its original send time
  message_retention_seconds = 1209600 # 14 days
  sqs_managed_sse_enabled   = true
}

resource "aws_sqs_queue" "notification" {
  name = "${local.name}-notification"

  visibility_timeout_seconds = 30     # longer than handling one message
  message_retention_seconds  = 345600 # 4 days: survives a weekend with the cluster down
  receive_wait_time_seconds  = 20     # long polling: fewer empty receives
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notification_dlq.arn
    maxReceiveCount     = 5
  })
}

# only the notification queue may use this DLQ
resource "aws_sqs_queue_redrive_allow_policy" "notification_dlq" {
  queue_url = aws_sqs_queue.notification_dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.notification.arn]
  })
}

# stricter than the console's Principal "*": the SNS service, and only from our topic
data "aws_iam_policy_document" "notification_queue" {
  statement {
    sid       = "FromTransactionsTopic"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.notification.arn]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.transactions.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "notification" {
  queue_url = aws_sqs_queue.notification.id
  policy    = data.aws_iam_policy_document.notification_queue.json
}

resource "aws_sns_topic_subscription" "notification" {
  topic_arn            = aws_sns_topic.transactions.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.notification.arn
  raw_message_delivery = true

  # the queue must accept SNS before the first message arrives
  depends_on = [aws_sqs_queue_policy.notification]
}
