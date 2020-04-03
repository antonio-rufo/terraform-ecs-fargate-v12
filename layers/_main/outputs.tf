output "state_bucket_id" {
  value       = "${aws_s3_bucket.state.id}"
  description = "The ID of the bucket to be used for state files."
}

output "state_bucket_region" {
  value       = "${aws_s3_bucket.state.region}"
  description = "The region the state bucket resides in."
}

output "account_id" {
  value = "${data.aws_caller_identity.current.account_id}"
}

output "caller_arn" {
  value = "${data.aws_caller_identity.current.arn}"
}

output "caller_user" {
  value = "${data.aws_caller_identity.current.user_id}"
}
