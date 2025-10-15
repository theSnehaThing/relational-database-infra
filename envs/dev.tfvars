environment = "dev"
aws_region = "eu-west-1"
db_instance_class = "db.t3.small"
db_allocated_storage = 20
publicly_accessible = false
db_engine = "mysql"
db_engine_version = "8.0"
user = [
  {
    first_name = "Piet"
    last_name  = "Pietersen"
    email      = "piet@2solar.nl"
    username   = "piet"

  },
    {
    first_name = "Klaas"
    last_name  = "Klassen"
    email      = "klass@2solar.nl"
    username   = "klass"

  },
    {
    first_name = "Piet"
    last_name  = "AnotherPiet"
    email      = "piet2@2solar.nl"
    username   = "piet"
  }
]

create_user = true
