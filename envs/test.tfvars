environment = "test"
aws_region = "eu-west-1"
db_instance_class = "db.t3.medium"
db_allocated_storage = 50
publicly_accessible = false
db_engine = "mysql"
db_engine_version = "8.0"
create_user = true
user = [
  {
    first_name = "Piet"
    last_name  = "Pietersen"
    email      = "piet@2solar.nl"
    username   = "piet123"
    schema     = "piet_schema"
  }
]
