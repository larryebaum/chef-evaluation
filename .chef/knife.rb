current_dir = File.dirname(__FILE__)
  user = admin
  client_key               "../.chef/admin.pem"
  validation_client_name   "a2-validator"
  validation_key           "../.chef/a2-validator.pem"
  chef_server_url          "https://chef-server.test/organizations/a2"
  cookbook_path            ["#{current_dir}/../cookbooks"]
