output "cert0" {
  value = "${aws_route53_record.acm_validation_records}"

}
output "alb_dns" {
  value = aws_route53_record.elb_tf.name
}
