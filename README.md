# Welcome to PACSOR

PACSOR is an advanced Docker-based DICOM SCP/SCU application designed for efficient handling and processing of medical images. Its primary functions include receiving DICOM images, sending them to Milvue applications, retrieving results, and then dispatching these results to one or multiple DICOM receivers.

## Usage

1. Clone the repository and navigate to the `milvue / pacsor` directory.

   ``` bash
   $ git clone https://github.com/milvue/pacsor.git
   ```

3. Run the `setup.sh` script to create new environment and compose files. This script will prompt you for the necessary settings and create a new `.env.xxx` file in the `env-files` directory, then it will create a symbolic link to this newly created `.env.xxx` file in the root directory.

   ``` bash
   $ bash ./scripts/setup.sh
   ```

   The script is a dialog-based script that will prompt you for the several settings.
   When set up, just select "Save configuration and exit" to generate the `.env` and `compose.yaml` files. 

   The script will then generate a new `.env` file with the format `.env.{CLIENT_NAME}`.

4. Selecting "Display current configuration" will display the current configuration.

5. Finally, launch `pacsor` by running `docker compose`:
   
   ``` bash
   $ docker compose up -d
   ```

## Additional Information

### Multi-core setting
The multi-core setting allows PACSOR to send DICOM images to multiple environments (e.g., production and precert) simultaneously. Then it retrieves the results and sends them to the appropriate PACS system, using the callback URL specified in the `.env` file.

To enable:

1. **Edit `compose.yaml`**:  
   - Uncomment the line that includes `pacsor/compose.multicore.yaml`.

2. **Edit `.env` file**:  
   - Fill in `API_URL_1` and `TOKEN_1` for `core1`.

3. **Configure `CALLBACK_URLS`** (optional):  
   - In the `.env` file, adjust or complete `CALLBACK_URLS` if needed to specify where results should be sent.

4. **Verify Configuration**:  
   - Run `docker compose config` to ensure everything is correctly set up.

5. **Start PACSOR**:  
   - Execute `docker compose up -d` to launch the application.

### Multi-destination Callbacks

The field `CALLBACK_URLS` in the `core` section allows PACSOR to send results to several PACS systems. For instance, if you have two services `storescu-1` and `storescu-2` with different PACS configurations, you can configure `core` to send results to these two PACS by setting `CALLBACK_URLS=http://storescu-1:8000,http://storescu-2:8000`.


> **WARNING**:
> If you create an other storescu service, you will need to edit `docker-compose.yml`  and add manually a new service. You will need also to set the `PACS_IP`, `PACS_PORT`, `PACS_AET` in order to fit the needed configuration.
  

## Running PACSOR

To operate PACSOR, the following Docker Compose commands are used:

-   **Starting PACSOR**:    
    -   `docker compose up -d`
    -   This command starts the PACSOR application in detached mode, allowing it to run in the background.
-   **Stopping PACSOR **:
    -   `docker compose down`
    -   Use this command to stop and remove the PACSOR containers.
-   **Purging All Volumes**:
    -   `docker compose down --volumes`
    -   This command will stop the PACSOR containers and remove all associated volumes. It's useful for a complete reset.
-   **Using a Specific `.env` File**:
    -   `docker compose --env-file .other.env.file up -d`
    -   If you need to start PACSOR with a different configuration, this command allows you to specify an alternative `.env` file.

- **Viewing Logs**:
	- `docker logs -f [container_name_or_id]`
	- To monitor real-time logs from a specific container, use this command. Replace `[container_name_or_id]` with the actual name or ID of the container you want to monitor.
