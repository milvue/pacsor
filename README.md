# Welcome to PACSOR

PACSOR is an advanced Docker-based DICOM SCP/SCU application designed for efficient handling and processing of medical images. Its primary functions include receiving DICOM images, sending them to Milvue applications, retrieving results, and then dispatching these results to one or multiple DICOM receivers.

## History

| Date       | Version | Description                                                                                     | Identifier |
| ---------- | ------- | ----------------------------------------------------------------------------------------------- | ---------- |
| 2024-09-24 | 2.4.0   | fix output cleaning for multicore                                                               | cf0ba257   |
| 2025-03-06 | 2.5.0   | support multiple products and new HL7 service                                                   | 2aa45208   |
| 2025-03-21 | 2.5.1   | (hl7) add formating of report for hl7 html format                                               | 06903bb1   |
| 2025-03-21 | 2.5.2   | Add Support to hybrid mode                                                                      | 9bafc995   |
| 2025-10-24 | 2.6.0   | Enhances reliability enables the detection and measures inference commands. Removed hybrid mode | f2544465   |
| 2025-10-27 | 2.6.1   | Fix study_instance_uid query from dicom_dir and fallback metadata query                         | 4f67fa3f   |
| 2025-11-03 | 2.7.0   | Add pubusb subscriber component to retrieve reports from external providers                     | 9bed6dd1   |

## Prerequisites

**Tested versions:**

- Ubuntu : version 22.04.1 LTS
- Docker Engine : version 24.0.6
- Docker Compose : version 2.29.6 [ (How to install a specific docker-compose version)](#1-how-to-install-a-specific-docker-compose-version)

## Usage

1. Clone the repository and navigate to the `milvue / pacsor` directory.

   ```bash
   git clone https://github.com/milvue/pacsor.git
   ```

2. To configure a specific product, execute its corresponding setup script.
   For Milvue Suite, run `setup.sh`.
   For Product2, run `.setup.smarttrauma.sh`.
   The scripts follow a similar process: they generate a new environment and a compose file. The main distinction lies in the available environments for each product.

   In each case, the script will prompt you for the necessary settings and create a new `.env.xxx` file in the `env-files` directory, then it will create a symbolic link to this newly created `.env.xxx` file in the root directory.

   ```bash
   bash ./scripts/setup.sh
   ```

   The script is a dialog-based script that will prompt you for the several settings.
   When set up, just select "Save configuration and exit" to generate the `.env` and `compose.yaml` files.

   The script will then generate a new `.env` file with the format `.env.{CLIENT_NAME}`.

3. Selecting "Display current configuration" will display the current configuration.

4. Finally, launch `pacsor` by running `docker compose`:

   ```bash
   docker compose up -d
   ```

## How to Update

To update the PACSOR components to the latest version, follow these steps:

1. Navigate to the `milvue / pacsor` directory.

2. Pull the latest Docker images by running the following command:

   ```bash
   docker compose pull
   ```

   This command ensures that you are using the most up-to-date versions of all the Docker images defined in your compose.yaml file.

3. Once the images are updated, restart PACSOR by running:

   ```bash
   docker compose up -d
   ```

   This command will recreate the containers using the newly pulled images, ensuring that your PACSOR environment is running the latest updates.

## Additional Information

### Multi-core setting

The multi-core allows PACSOR to send DICOM images to multiple environments (e.g., production and precert) simultaneously. Then it retrieves the results and sends them to the appropriate PACS system, using the callback URL specified in the `.env` file.

To enable:

1. **Edit `compose.yaml`**:

   - Uncomment the line that includes `pacsor/compose.multicore.yaml`.

2. **Edit `.env` file**:

   - Fill in `API_URL_1` and `TOKEN_1` for `core1`.

3. **Configure `CALLBACK_URLS`** (optional):

   - In the `.env` file, adjust or complete `CALLBACK_URLS` if needed to specify where results should be sent.

4. **Verify Configuration**: Run `docker compose config` to ensure everything is correctly set up.

   ```bash
   docker compose config
   ```

5. **Start PACSOR**: Finally, launch `pacsor` by running `docker compose`:

   ```bash
   docker compose up -d
   ```

### Multi-destination Callbacks

The field `CALLBACK_URLS` in the `core` section allows PACSOR to send results to several PACS systems. For instance, if you have two services `storescu-1` and `storescu-2` with different PACS configurations, you can configure `core` to send results to these two PACS by setting `CALLBACK_URLS=http://storescu-1:8000,http://storescu-2:8000`.

> **WARNING**:
> If you create an other storescu service, you will need to edit `docker-compose.yml` and add manually a new service. You will need also to set the `PACS_IP`, `PACS_PORT`, `PACS_AET` in order to fit the needed configuration.

### HL7 settings

The `hl7` service, defined within `compose.hl7.yaml`, facilitates the sending of HL7 messages through `pacsor` logs and featuring also TechCare Report.
By default, this service is disabled. To activate it, users shall:

1. **Execute the setup script**:

   ```bash
   bash ./scripts/setup.sh
   ```

2. **Go through the setup process**: Ensure the existence of the `.env` and `compose.yaml` files at the end of the process

3. **Configure HL7 environment variables**: Fill the variable in the relevant `{client.name}.config` file in script folder

| Parameter                 | Default Value                        | Description                                                                                                                 |
| ------------------------- | ------------------------------------ | --------------------------------------------------------------------------------------------------------------------------- |
| HL7_ENABLE                | false                                | A boolean indicating whether to enable HL7 message service                                                                  |
| HL7_RECEIVING_APPLICATION | empty                                | The receiving application name for HL7 messages.                                                                            |
| HL7_RECEIVING_FACILITY    | empty                                | The receiving facility name for HL7 messages.                                                                               |
| HL7_RIS_IP                | empty                                | The IP address of the Radiology Information System (RIS).                                                                   |
| HL7_RIS_PORT              | empty                                | The port number used to communicate with the RIS.                                                                           |
| HL7_LANGUAGE              | FR                                   | The language code for HL7 messages. It can be "EN" or "FR". It only applies to MilvueSuite HL7 messages (not to the report) |
| HL7_INCLUDE_TCR           | false                                | A boolean indicating whether to include TechCare Report                                                                     |
| HL7_TCR_URL               | https://app.report.milvue.com/report | The URL for the TCR.                                                                                                        |
| HL7_TCR_OUT_FORMAT        | B64                                  | The output format for TechCare Report. It can be "B64", "PLAIN" or "HTML"                                                   |
| WEBPS_ENABLE              | false                                | A boolean indicating whether to enable report pubsub subscriber.                                                            |
| WEBPS_REPORTOR_URL        | empty                                | The URL used to get pubsub access.                                                                                          |
| WEBPS_PROVIDERS           | empty                                | List of provider names to retrieve reports                                                                                  |

4. **Re-run the setup script**: to actuate the edits made in the `{client.name}.config` file and resulting in the population of the `.env` with the specified HL7 environment variables defined above.

5. **Start PACSOR**: Finally, launch `pacsor` by running `docker compose`:

   ```bash
   docker compose up -d
   ```

6. **Check the HL7 configuration**: The user can visualize the current HL7 configuration

   ```bash
   docker exec "HL7_service_container" curl http://localhost:8000/config/
   ```

**DETECTION_INFERENCE_COMMAND and MEASURES_INFERENCE_COMMAND**

The `compose.hl7.yaml` includes a feature to define the product that we want to activate, this can be activated by 4 parameters:

| Parameter                   | Default Value | Description                                                                                   |
| --------------------------- | ------------- | --------------------------------------------------------------------------------------------- |
| INCLUDE_DETECTIONS_FINDINGS | true          | Enable detections.                                                                            |
| DETECTION_INFERENCE_COMMAND | smarturgences | Configure the product for detection. It can be: smarturgences, detection, smartchest, trauma. |
| INCLUDE_MEASURES_FINDINGS   | true          | Enable measures                                                                               |
| MEASURE_INFERENCE_COMMAND   | smartxpert    | Configure the product for measures. It can be: smartxpert, measures.                          |

**HL7 LOAD CONFIGURATION AND TEMPLATE**

The `compose.hl7.yaml` file has two fields which allow to load customizable template and configuration.

- `config.json`: it allows the user to create customizable configuration for the HL7 like above that can be easily loaded
- `template.py`: it allows the user to customize HL7 sections

1. **Add the volume for the pre-saved files**, the user shall define the volume in the `compose.hl7.yaml`

   ```hl7:
         volumes:
            - <current_directory/config_files/>:/home/custom/
   ```

   This is the hierarchy:

   ```
   |_ <current_directory>
    |_ <conf>
        |_ <custom_config>.json
        |_ <custom_template>.py
   ```

2. **Define pre-saved template**, define `LOAD_TEMPLATE_AT_INIT` in `compose.hl7.yaml` equal to the name of the py file (without extention) in the environment.
3. **Define pre-saved configuration**, define `LOAD_CONFIG_AT_INIT` in `compose.hl7.yaml` equal to the name of the JSON file (without extention) in the environment. The configuration can be loaded real-time using the command

```bash
 docker exec "HL7_service_container" curl -X POST http://localhost:8000/config/load/{JSON_file_without_extension}
```

There

> **WARNING**:
> The configuration file defined in `LOAD_CONFIG_AT_INIT` has highest priority than the configuration defined in the `.env` file

**HTML messages**:
The report section within the HL7 message support the HTML encoding having formatting with no indents. The procedure is as follows:

1. **Set `HL7_TCR_OUT_FORMAT`**, set the environment variable in `.env` file to `HTML`
2. **Retrieve the HTML report**, once the user received back the HL7 message it will contain the HTML message in the report section `CRHTML`
3. **De-code the HTML report**, if the user wants to read easily the HTML code, this is possible by [de-coding](https://www.base64decode.org) the portion of code after `^Base64^` and before `||||||`
4. **Save the decoded HTML report**, the user shall copy-paste the html code and save it in a .html file

## Running PACSOR

To operate PACSOR, the following Docker Compose commands are used:

- **Starting PACSOR**:
  - `docker compose up -d`
  - This command starts the PACSOR application in detached mode, allowing it to run in the background.
- **Stopping PACSOR**:
  - `docker compose down`
  - Use this command to stop and remove the PACSOR containers.
- **Purging All Volumes**:
  - `docker compose down --volumes`
  - This command will stop the PACSOR containers and remove all associated volumes. It's useful for a complete reset.
- **Using a Specific `.env` File**:

  - `docker compose --env-file .other.env.file up -d`
  - If you need to start PACSOR with a different configuration, this command allows you to specify an alternative `.env` file.

- **Viewing Logs**:
  - `docker logs -f [container_name_or_id]`
  - To monitor real-time logs from a specific container, use this command. Replace `[container_name_or_id]` with the actual name or ID of the container you want to monitor.

### Manual Study Relaunch

This feature allows to manually relaunch a study that has already been sent to pacsor without running `docker compose down --volumes` by running the command on `http://admin:PORT/relaunch/{study_instance_uid}` for any exam that has been sent previously.

## Advanced Usage

### 1. How to install a specific docker-compose version

#### 1.1 Download the specific version of docker-compose

```bash
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.29.6/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
```

#### 1.2 Apply the executable permission to the binary

For only your user :

```bash
   chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
```

For all users :

```bash
sudo cp $DOCKER_CONFIG/cli-plugins/docker-compose /usr/local/lib/docker/cli-plugins/
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
```

#### 1.3 Check the version of docker-compose

```bash
docker compose version
```

Expected output:

```bash
Docker Compose version v2.29.6
```
