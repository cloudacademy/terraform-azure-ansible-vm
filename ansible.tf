# WEB SERVER ANSIBLE SCRIPT
#============================

resource "null_resource" "ansible" {
  triggers = {
    vm_machine_ids = azurerm_linux_virtual_machine.cloudacademy_web_vm.virtual_machine_id
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    working_dir = "${path.module}/ansible"
    command     = <<EOT
        sed 's/HOST_IPS/${azurerm_linux_virtual_machine.cloudacademy_web_vm.private_ip_address}/g' hosts > vms
        ansible-playbook \
        -v -i vms playbook.web.yaml \
        --ssh-common-args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
    EOT
  }

  depends_on = [
    azurerm_linux_virtual_machine.cloudacademy_web_vm
  ]
}
