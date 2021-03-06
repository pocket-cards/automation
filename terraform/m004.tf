

module "m004" {
  source = "github.com/wwalpha/terraform-module-registry/aws/lambda"

  filename         = "${data.archive_file.m004.output_path}"
  source_code_hash = "${filebase64sha256("${data.archive_file.m004.output_path}")}"

  enable_xray        = true
  function_name      = "${local.project_name_uc}-M004"
  handler            = "index.handler"
  runtime            = "nodejs10.x"
  role_name          = "${local.project_name_uc}_Lambda_M004Role"
  layers             = ["${local.xray}"]
  role_policy_json   = ["${file("iam/lambda_policy_m004.json")}"]
  trigger_principal  = "events.amazonaws.com"
  trigger_source_arn = "${aws_cloudwatch_event_rule.m004.arn}"

  variables = {
    CALL_SLACK_FUNCTION = "PocketCards-M005Role"
  }

  timeout = 5
}

// -----------------------------------------
// Lambda Module File
// -----------------------------------------
data "archive_file" "m004" {
  type        = "zip"
  source_file = "../build/m004/index.js"
  output_path = "../build/m004/index.zip"
}

# -----------------------------------------------
# Amazon CloudWatch Rule
# -----------------------------------------------
resource "aws_cloudwatch_event_rule" "m004" {
  name        = "${local.project_name_uc}_CodeBuildError"
  description = "CodeBuild State Error Rule"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.codebuild"
  ],
  "detail-type": [
    "CodeBuild Build State Change"
  ],
  "detail": {
    "build-status": [
      "FAILED"
    ]
  }
}
PATTERN
}

# -----------------------------------------------
# Amazon CloudWatch Event Target
# -----------------------------------------------
resource "aws_cloudwatch_event_target" "m004" {
  depends_on = ["aws_cloudwatch_event_rule.m004"]

  rule = "${aws_cloudwatch_event_rule.m004.name}"
  arn = "${module.m004.arn}"
}

