resource "aws_iam_role" "replication" {
  name = "srmtest-s3-replication-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "replication" {
  name = "srmtest-s3-replication-policy"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${var.source_bucket_arn}",
        "${aws_s3_bucket.west1.arn}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
         "s3:GetObjectVersionTagging"
      ],
      "Effect": "Allow",
      "Resource": [
        "${var.source_bucket_arn}/*",
        "${aws_s3_bucket.west1.arn}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags"
      ],
      "Effect": "Allow",
      "Resource": [
        "${var.source_bucket_arn}/*",
        "${aws_s3_bucket.west1.arn}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

resource "aws_s3_bucket" "west1" {
  provider      = aws.west1
  bucket        = "srmtest-destination"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "west1" {
  provider                = aws.west1
  bucket                  = aws_s3_bucket.west1.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "west1_bucket_ownership" {
  provider = aws.west1
  bucket   = aws_s3_bucket.west1.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "west1" {
  provider = aws.west1
  bucket   = aws_s3_bucket.west1.id
  versioning_configuration {
    status = "Enabled"
  }
}

/*
resource "aws_s3_bucket" "west2" {
  provider = aws.west2
  bucket   = "srmtest-source"
  force_destroy = true
}
*/

resource "aws_s3_bucket_public_access_block" "west2" {
  provider                = aws.west2
  bucket                  = var.source_bucket_id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "west2_bucket_ownership" {
  provider = aws.west2
  bucket   = var.source_bucket_id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "west2" {
  provider = aws.west2

  bucket = var.source_bucket_id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "west2_to_west1" {
  provider = aws.west2
  # Must have bucket versioning enabled first
  # depends_on = [aws_s3_bucket_versioning.west2]

  role   = aws_iam_role.replication.arn
  bucket = var.source_bucket_id

  rule {
    id     = "CRR_west2_west1"
    status = "Enabled"

    destination {
      bucket = aws_s3_bucket.west1.arn

    }
  }
}

resource "aws_s3_bucket_replication_configuration" "west1_to_west2" {
  provider = aws.west1
  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.west1]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.west1.id

  rule {
    id     = "CRR_west1_west2"
    status = "Enabled"

    destination {
      bucket = var.source_bucket_arn

    }
  }
}
