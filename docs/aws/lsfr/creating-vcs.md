# Creating virtual computers

While working on an [analysis module](../../contributing-to-analyses/analysis-modules/index.md), you can develop locally or on a virtual computer with Lightsail for Research (LSfR).

Virtual computers provide access to a set amount of virtual CPUs (vCPUs), memory, and storage through a web browser rather than a physical machine.
Using a virtual computer allows you to develop and run analyses that require more CPUs and memory than is available on your local machine.

!!! note

    You will need access to AWS to use LSfR.
    See [getting access to AWS](../../getting-started/accessing-resources/index.md#getting-access-to-aws) to learn how to get set up with AWS.

- The virtual computers provided through LSfR use the Ubuntu operating system.
- During setup, you will choose your desired configuration, including the amount of virtual CPUs, memory, and storage space.
    - You also have the option to add [additional storage to your virtual computer](./working-with-volumes.md).
- All virtual computers will have a set of pre-installed applications needed for working with OpenScPCA, including:
    - Git and GitKraken
    - The AWS command line interface, which has already been configured for you
    - R
    - Conda


!!! tip "More on virtual computers"

    Read more about [virtual computers with Lightsail for Research](https://docs.aws.amazon.com/lightsail-for-research/latest/ug/computers.html).

## How to create a virtual computer

Follow the below steps to create a virtual computer to use with LSfR.

1. Navigate to the [access portal URL from when you set up your user in IAM Identity center](../joining-aws.md)
After logging in, you will need to select your account and click on `ResearcherRestriction`.

    <figure markdown="span">
        ![Select region](../../img/creating-vcs-1.png){width="400"}
    </figure>

    This should bring you to the AWS Console and home page.
    Once in the AWS Console, be sure that you are in the `us-east-2` region, by selecting the drop-down menu in the tool bar.

    <figure markdown="span">
        ![Select region](../../img/creating-vcs-2.png){width="400"}
    </figure>

1. You will need to use the AWS Service Catalog to create virtual computers.
Creating an instance via LSfR is _not supported_.

    Open the AWS Service Catalog by using the search bar and typing, `service catalog`.

    <figure markdown="span">
        ![Select service catalog](../../img/creating-vcs-3.png){width="600"}
    </figure>

1. Select `LightsailInstance` in the product list, and click `Launch product`.

    <figure markdown="span">
        ![Launch product](../../img/creating-vcs-4.png){width="600"}
    </figure>

2. You will then choose the name and configurations for your virtual computer.

    - Start by providing a `Provisioned product name`.
    <!--TODO Do we want to provide guidance on names?-->
    - Pick an `Application` to use from the drop-down menu.
    This installs any additional applications along with the pre-installed applications.
        - If you are planning to develop in R, we recommend choosing `Rstudio`, which includes RStudio.
        - If you are planning to develop in Python, we recommend choosing `VSCodium`, which includes VSCodium, a distribution of Microsoft's editor VS Code.
        - For information on all application options, see [the LSfR documentation on Applications](https://docs.aws.amazon.com/lightsail-for-research/latest/ug/blueprints-plans.html).
    - Name your instance.
    It might be helpful to use the same name as the provisioned product.
    - Pick the size for your instance.
        - See the [table below outlining the total vCPUs and memory included with each instance size](#choosing-an-instance-size) to choose the most appropriate instance.
    - Set the `ShutdownIdlePercent` to 5 and the `ShutdownTimePeriod` to 10.
    This means if the instance is using less than 5% of the total available CPUs for at least 10 minutes, the instance will temporarily shut down.
    This _does not_ delete your instance; it temporarily stops any idle instances until you are ready to resume your work.

    <figure markdown="span">
        ![Configure instance](../../img/creating-vcs-5.png){width="600"}
    </figure>

3. Once you have configured your instance, click `Launch product`.
You have now created a virtual computer!

### Choosing an instance size

When creating your virtual computer, you will need to choose the instance size.
This specifies the total vCPUs and memory (RAM) available for use in your virtual computer.
All virtual computers will come with 50 GB of storage space.

- Remember that you will have a [monthly budget for any computational resources you use](../../getting-started/accessing-resources/getting-access-to-compute.md#monthly-budget).
- Before you request a plan with GPUs, you will need to put in a [request with the Data Lab team](../../getting-started/accessing-resources/getting-access-to-compute.md#gpu-instance-access).

Use the below table to help pick the most appropriate instance type for your computing needs:

| Name | vCPU | RAM | Hourly price (us-east-2) |
|------|------|-----|--------------------------|
| Standard-XL | 4 | 8 GB | $0.90 |
| Standard-2XL | 8 | 16 GB | $1.11 |
| Standard-4XL | 16 | 32 GB | $1.53 |
| GPU-XL | 4 | 16 GB | $2.37 |
| GPU-2XL | 8 | 32 GB | $2.64 |
| GPU-4XL | 16 | 64 GB | $3.18 |
