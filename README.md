# Welcome to PACSOR

PACSOR is an advanced Docker-based DICOM SCP/SCU application designed for efficient handling and processing of medical images. Its primary functions include receiving DICOM images, sending them to Milvue applications, retrieving results, and then dispatching these results to one or multiple DICOM receivers.

## History

| Date       | Version | Description                                                                                     | Identifier |
| ---------- | ------- | ----------------------------------------------------------------------------------------------- | ---------- |
| 2024-09-24 | 2.4.0   | fix output cleaning for multicore                                                               | cf0ba257   |
| 2025-03-06 | 2.5.0   | support multiple products and new HL7 service                                                   | 2aa45208   |
| 2025-03-21 | 2.5.1   | (hl7) add formatting of report for hl7 html format                                              | 06903bb1   |
| 2025-03-21 | 2.5.2   | Add Support to hybrid mode                                                                      | 9bafc995   |
| 2025-10-24 | 2.6.0   | Enhances reliability enables the detection and measures inference commands. Removed hybrid mode | f2544465   |
| 2025-10-27 | 2.6.1   | Fix study_instance_uid query from dicom_dir and fallback metadata query                         | 4f67fa3f   |
| 2025-11-03 | 2.7.0   | Add pubsub subscriber component to retrieve reports from external providers                     | 9bed6dd1   |
| 2025-11-06 | 2.8.0   | Fix output cleaning for studies with error                                                      | 7aaa7112   |
| 2025-11-13 | 2.9.0   | Enable dicom filtering before upload                                                            | 0c3f15e6   |
| 2026-02-12 | 2.10.0  | Improve callback logs  <br> Fix dicom filter in multicore case  <br> Enable different OBX segments according to report format <br> Use TCR_API_URL env var and remove /report root <br> Limit instance upload rate <br> Remove PREDICTION_ID <br> Add retry in case of TimeoutReady                                                                                                             | b9b15a9a   |
| 2026-04-08 | 2.10.1  | Fix hl7 optional segments + case where studies not on MVS                                       | 6f2dc31c   |
| 2026-06-08 | 2.10.2  | hl7 - add retries during GET JSON in case study is still running                                | cc958614   |
| 2026-06-11 | 2.11.0  | Add tcr-core module + fix minor bugs in hl7                                                     | d2a150f7   |
| 2026-10-20 | 2.11.1  | Fix accession number retrieved from pubsub integration                                          | 83fae064   |
| 2026-10-23 | 2.11.2  | Optionally keep input modality for secondary captures outputs                                   | a49ba44e   |

## Prerequisites

**Tested versions:**

- Ubuntu : version 22.04.1 LTS
- Docker Engine : version 24.0.6
- Docker Compose : version 2.29.6 [ (How to install a specific docker-compose version)](#1-how-to-install-a-specific-docker-compose-version)

## Installation

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

A study already sent to pacsor can be rerun without `docker compose down --volumes`. The request no longer goes through an HTTP route on the deployment: it is published by Milvue on the `relaunch_study` Web PubSub hub, and the optional `admin` service subscribes to it on the deployment side.

To make a deployment able to receive these requests:

1. **Enable the service**: uncomment `- pacsor/compose.admin.yaml` in the `include` list of `compose.yaml`.

2. **Check the `.env` file**: `admin` needs `TOKEN` and `PUBSUBOR_URL` (`https://pubsubor.milvue.com`, written by the setup script).

3. **Restart PACSOR**: `docker compose up -d`.

`admin` then joins the group derived from `TOKEN`, so it only receives the relaunch requests meant for this deployment, and forwards each of them to `core`, which asks the Milvue API to rerun the study. Check `docker logs -f admin` for the `joined group` line at startup and for one `Relaunch triggered for study` line per request.

The port published by `admin` serves its healthcheck only; there is nothing to call by hand on it.

> **WARNING**:
> A relaunch reruns the study from the instances the API already holds; it uploads nothing. To send the images again, see [NO_DUPLICATE_UPLOAD](#no_duplicate_upload).

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

### Dicom filtering before upload (v2.9.0+)

The field `DICOM_FILTERS` in the `core` section allows PACSOR to filter the dicoms to effectively send to the API and those to skip. The syntax is as following :

`DICOM_FILTERS=[{"tag":{"group":"<tag_group>","element":"<tag_element>"},"pattern":"<regex_pattern>","should_match":<bool>}]`

This states that dicoms with tag ABCD,EFGH (group=ABCD, element=EFGH) that match (if should_match is false) or don’t match (if should_match is true) the regex_pattern, should be skipped by pacsor.

Example:

`DICOM_FILTER=[{"tag":{"group":"0010","element":"0010"},"pattern":"^TEST.*","should_match":false},{"tag":{"group":"0008","element":"0060"},"pattern":"^SR$$","should_match":true}]`

According to the this setup, the following dicoms' behavior would be:

- PatientName=TEST, Modality=SR : skipped
- PatientName=NOT_A_TEST, Modality=SR : not skipped
- PatientName=NOT_A_TEST, Modality=DX : skipped
- PatientName=NOT_A_TEST, Modality=(not defined) : not skipped

### Duplicate skipping and upload rate

Three fields of the `core` service govern how received instances are pushed to the API.

| Parameter           | Default Value | Description                                                                 |
| ------------------- | ------------- | --------------------------------------------------------------------------- |
| NO_DUPLICATE_UPLOAD | true          | Skip an instance whose SOP Instance UID is already known to `core`          |
| ASYNC_UPLOAD_LIMIT  | 10            | Number of instance uploads allowed to run at the same time (v2.10.0+)       |
| ASYNC_UPLOAD_DELAY  | 30s           | Time an upload slot stays held after the upload completes (v2.10.0+)        |

#### NO_DUPLICATE_UPLOAD

With the default `true`, an instance whose SOP Instance UID already exists in the `core` database is not uploaded a second time: the incoming file is removed from the input volume and a `SkipDuplicate` entry is written to the logs. This protects against a PACS that re-sends the same instances, at the cost of making a resend a no-op.

Set it to `false` when you need the same DICOMs to be uploaded again — typically to reprocess a study end to end by re-sending it from the PACS. The field is read from the `.env` file:

```bash
NO_DUPLICATE_UPLOAD=false
```

> **WARNING**:
> In a multi-core setup, only `core` reads this field. The additional cores declared in `compose.multicore.yaml` always skip duplicates.

Note that a [Manual Study Relaunch](#manual-study-relaunch) asks the API to rerun a study it already holds, so it does not depend on this field.

#### ASYNC_UPLOAD_LIMIT and ASYNC_UPLOAD_DELAY

These two fields work as a pair. An upload takes one of the `ASYNC_UPLOAD_LIMIT` slots before posting the instance, and the slot is released only `ASYNC_UPLOAD_DELAY` after the post returns. `ASYNC_UPLOAD_LIMIT` therefore sets how many uploads run at once, and the pair together caps the sustained rate at `ASYNC_UPLOAD_LIMIT` instances per `ASYNC_UPLOAD_DELAY`. With the defaults, a study arriving as a burst is uploaded 10 instances at a time, at most 10 instances per 30 seconds.

Lower the limit or raise the delay when the link to the API is thin or when the API rate-limits bursts; do the reverse when instances pile up in the input volume on large studies and the network can absorb more.

`ASYNC_UPLOAD_DELAY` is a Go duration: a number followed by its unit, such as `30s`, `1m` or `500ms`. A value that cannot be parsed is reported in the `core` logs and the default is used instead.

Both fields keep their default unless they are declared, and they are not read from the `.env` file. A deployment that needs to change them adds them to the `environment` section of the service that uploads, in `pacsor/compose.pacsor.yaml`:

```yaml
  core:
    environment:
      GOMAXPROCS: 0
      ASYNC_UPLOAD_LIMIT: 4
      ASYNC_UPLOAD_DELAY: 1m
```

Then restart with `docker compose up -d`.

> **WARNING**:
> In a multi-core setup, each core uploads on its own and holds its own slots. Set the fields on the core concerned — the additional cores are declared in `compose.multicore.yaml`.

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
| TCR_API_URL               | https://app.report.milvue.com        | The URL for the TCR.                                                                                                        |
| HL7_TCR_OUT_FORMAT        | B64                                  | The output format for TechCare Report. It can be "B64", "PLAIN" or "HTML"                                                   |
| WEBPS_ENABLE              | false                                | A boolean indicating whether to enable report pubsub subscriber.                                                            |                                                                                         |
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

2. **Define pre-saved template**, define `LOAD_TEMPLATE_AT_INIT` in `compose.hl7.yaml` equal to the name of the py file (without extension) in the environment.
3. **Define pre-saved configuration**, define `LOAD_CONFIG_AT_INIT` in `compose.hl7.yaml` equal to the name of the JSON file (without extension) in the environment. The configuration can be loaded real-time using the command

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
