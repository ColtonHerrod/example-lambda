terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Or the latest version you want to use
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
}

data "archive_file" "lambda_zip" {
  type = "zip"
  source_file = "lambda.py"
  output_path = "lambda.zip"
}

resource "aws_lambda_function" "hello_world" {
  function_name    = "example-lambda"
  handler          = "lambda.lambda_handler"  # File.Handler (important!)
  runtime           = "python3.12" # Or your desired runtime
  filename          = "lambda.zip"
  memory_size      = 128  # Adjust as needed
  timeout          = 30  # Adjust as needed (seconds)
  role = aws_iam_role.lambda_dynamodb_role.arn
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.example.name
    }
  }
}

resource "aws_iam_role" "lambda_dynamodb_role" {
  name = "lambda_dynamodb_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "dynamodb_policy" {
  name = "dynamodb_policy"
  description = "Policy for Lambda to read and write to DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        Effect = "Allow",
        Resource = [
          aws_dynamodb_table.example.arn,
          "${aws_dynamodb_table.example.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dynamodb_attachment" {
  role       = aws_iam_role.lambda_dynamodb_role.name
  policy_arn = aws_iam_policy.dynamodb_policy.arn
}

resource "aws_dynamodb_table" "example" {
  name           = "example-lambda"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "name"
  attribute {
    name = "name"
    type = "S"
  }
}