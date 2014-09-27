gcutil adddisk --zone="us-central1-a" \
	--disk_type=pd-standard  \
	--size_gb=50 \
	$1-docker

gcutil addinstance --zone="us-central1-a" \
	--machine_type="n1-standard-2"  \
	--network="default" \
	--external_ip_address="ephemeral" \
	--service_account_scopes="https://www.googleapis.com/auth/devstorage.read_only" \
	--image="coreos-alpha-444-0-0-v20140919" \
	--persistent_boot_disk="true" \
	--auto_delete_boot_disk="true" \
	--metadata_from_file=user-data:cloud-config.yaml \
	--authorized_ssh_keys=core:~/.ssh/google_compute_engine.pub,core:~/.ssh/deis.pub \
	--tags deis \
	--service_account_scopes="https://www.googleapis.com/auth/devstorage.read_only" \
	--disk="$1-docker,deviceName=docker,mode=READ_WRITE" $1
