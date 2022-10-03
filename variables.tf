variable "access_key" {
  type = string
  sensitive = true
}
variable "secret_key" {
  type = string
  sensitive = true
}
variable "source_bucket_arn" {
  type = string
}
variable "source_bucket_id" {
  type = string
}