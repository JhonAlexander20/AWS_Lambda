provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role_terraform_1_Jhon_Alexander_Chambi_vilca"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_s3_bucket" "lambda_trigger_bucket" {
  bucket = var.bucket_name
}

resource "aws_iam_policy" "lambda_s3_read_policy" {
  name = "lambda_s3_read_policy_jhon"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "s3:GetObject",
      Resource = "arn:aws:s3:::${var.bucket_name}/*"
    }]
  })
}

resource "aws_iam_policy_attachment" "attach_lambda_s3_read" {
  name       = "attach_lambda_s3_read"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = aws_iam_policy.lambda_s3_read_policy.arn
}

resource "aws_lambda_function" "my_lambda" {
  function_name = "Jhon_Alexander_Chambi_Vilca"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"
  filename      = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      ENV = "dev"
    }
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.bucket_name}"
}

resource "aws_s3_bucket_notification" "trigger_lambda_on_upload" {
  bucket = aws_s3_bucket.lambda_trigger_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.my_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
