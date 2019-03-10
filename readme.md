# Defensive Terraform Azure Storage Backend Configuration

**Description**

While studying Cloud Infrastructure on Azure, I started tinkering with Terraform and _Infrastructure as Code_. Enabling me to quickly spin up/down different scenarios we were assigned by our teacher.

Deploying from my local machine worked fine while my Terraform configs were small. As my projects started to grow though. I quickly found a need to separate deployment configurations into more logical units.

That's when I started looking into creating separate tf-states, instead of managing different directories or having the whole thing in a massive state file.

## The Problem

- As the project grew. It became obvious that I needed to be able to deploy certain parts of the infrastructure separate from other resources.

- Having a large deployment configuration meant a huge tfstate file.

- Also if working in a team, there is no way of knowing if someone has made any applies while you have been working on your cloned copy. Which would mean that your local tfstate file would be behind theirs?

- On top of that. Pushing everything to a git-repo together with the tf-state file was not an option as it exposed certain Azure secrets.

- The git repo needs to only contain the infrastructure code so that anyone with the right credentials can get started straight away. Work on their part. Apply the updates and push the infrastructure code back to master again.

The following are my steps to separating infrastructure into smaller units and using remote backend on an Azure Storage Blob.

_You'll find the documentation on remote backends here._
[Terraform CLI Backend Types](https://www.terraform.io/docs/backends/types/index.html)
[Store Terraform state in Azure Storage](https://docs.microsoft.com/en-us/azure/terraform/terraform-backend)

### Creating a storage account to store our tf-state

Storing the tf-state in the cloud provides a better separation of concerns approach and also enables state locking with some providers. Meaning that only a single configuration can be applied at a time.

##### the current working directory structure

```json
├── remote-state
│   ├── main.tf
│   ├── outputs.tf
│   └── variables.tf
├── backend.tfvars
├── backend.tfvars.backup
└── terraform.tfvars
```

Here I work with a `terraform.tfvars` file as a global configuration file. Don't specify any default values in the other `variables.tf` files.

1. First create an storage account and container in Azure before adding remote backend state.

   1. cd into **`remote-state`** directory on your terminal

   2. comment out the backend config part

   ##### /main.tf

   ```
   # terraform {
   # backend "azurerm" {}
   # }
   ```

   3. run **`terraform init`**
   4. I used **`az login`** with Azure CLI to populate my credentials into terraform
   5. check the config with **`terraform plan -var-file="../terraform.tfvars"`**

   6. deploy with **`terraform apply -var-file="../terraform.tfvars`**
   7. make a note of the _storage account details_ output at the end of the `apply` chain.

If all went well Terraform has created our new storage account and generated a **`terraform.tfstate`** file.

Now, the thing is that anyone with access to this file will be able to read the subscription-id aswell as all the access-keys.

This is not good, but may or may not be a direct threat in this situation since I use Azure CLI to authenticate.

But lets try to keep our secrets more secret by adding a `.gitignore` on any file with _tfstate_ or _backend.tfvars_ and uploading our state to azure instead.

### Remote backend configuration

2. Restore the backend config.

##### /main.tf

```
terraform {
  backend "azurerm" {
    key = "backend/backend.tfstate"
  }
}
```

The **key** value tells Terraform to automatically create a `backend` folder.

3. Next, populate the **`backend.tfvars`** file with the storage account details provided by the output at the end of the last `terraform apply`

##### /backend.tfvars

```
resource_group_name = ""
storage_account_name = ""
container_name = ""
access_key = ""
```

4. run **`terraform init -backend-config="../backend.tfvars"`** to use the new backend configuration.

   > `-backend-config` tells Terraform to use these variables at runtime.

   1. test by adding another resource group and run **`terraform apply -var-file="../terraform.tfvars`** again to push the state remotely.

   2. _If you run `plan or apply` you will lock the state. This means that if someone else tries to do the same they will get the following error_

   ```
   Error: Error locking state: Error acquiring the state lock: storage: service returned error: StatusCode=409,
   ErrorCode=LeaseAlreadyPresent,
   ErrorMessage=There is already a lease present.
   ```

   3. test it by opening a new terminal tab and running `apply` at the same time in both tabs

      > _the locked state remains until you accept the changes_

### Separating deployments into smaller units.

The below structure creates a virtual-network with 4 subnets in one configuration. Another creates a example internal loadbalancer which requests a specific subnet id from the vnet tfstate.

Separate deployments stored in Azure with their own `.tfstate`, are at the same time indedepent but can retrieve data from one and other.

##### Consider the following directory structure

```json
.
├── network
│   ├── lb
│   │   ├── data.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── vnet
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── backend.tfvars
├── backend.tfvars.backup
└── terraform.tfvars
```

5.  deploy the **`vnet`** directory first with the same steps as the previous **`terraform init, terraform apply`**

    An important file is the `outputs.tf`. It exports the subnet id's so we can retrieve them in the loadbalancer.

6.  The final step here is to `apply` our loadbalancer.

    1. cd into the **`lb`** directory

    ##### /data.tf

    ```
      data "terraform_remote_state" "remote" {
        backend = "azurerm"
        config = {
          resource_group_name  = "${var.resource_group_name}"
          storage_account_name = "${var.storage_account_name}"
          container_name       = "${var.container_name}"
          access_key           = "${var.access_key}"

          key = "dev/network/vnet.tfstate"
        }
      }
    ```

    2. **key** value needs to point to the _`vnet`_ backend state location
    3. use the data resource to get the subnet id

    ##### /main.tf

    ```sh
    subnet_id = "${lookup(data.terraform_remote_state.remote.subnets_id_map, "consul")}"
    ```

    the subnet id is returned in a map so we need to lookup the correct subnet by name to get it's id

    4. pass in the `backend.tfvars` file on **`terraform apply -var-file="../backend.tfvars" -var-file="../terraform.tfvars"`**


    reusing the backend configuration here keep our code DRY and means that we don't need to hardcode the storage account details anywhere else.

If all went well the loadbalancer is being created and it's private dynamic ip address will be assigned in an its acquired subnet address space.

---

### Final Words

Finally you should try to lock down access to the **`/backend`** folder on Azure. Ideally we should do after creating the backend storage. This makes use nobody can delete the entire tfstate by accident or otherwise.

Here is a summary of solutions to our inital problems.

- We have separated our infrastructure into logical units. (logical to me anyway!)

- We now have a tfstate file for each configuration centrally stored in Azure. And all changes are reflected there.

- State-locking is enabled, so no one can apply a configuration at the same time.

- The tfvars and tfstate files are exluded on push to github. Hiding our any secrets from the public.

- A team can get started right away by simply cloning the repo and filling in the secrets.

- We can also enable granular control over who has access to what in the storage account.

😁

Good luck with your Terraform!

---

#### Defining a local state file solution

- Instead of using a remote state you can also store it locally in the root directory.

  ```
  terraform {
    backend "local" {
      path = "../state/backend/backend.tfstate"
    }
  }
  ```

  - you don't need to pass in `--backend-config` here
  - use data nearly the same way

    ```
    data "terraform_remote_state" "core-network" {
      backend   = "local"
      config {
        path = "${path.root}/state/core-network/terraform.tfstate"
      }
    }
    ```
