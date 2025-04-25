import json
from flask import Flask, request, jsonify
from kubernetes import client, config

app = Flask(__name__)

# Load kubeconfig (can also use config.load_incluster_config() inside a cluster)
config.load_incluster_config()

# Initialize Kubernetes API clients
batch_v1 = client.BatchV1Api()

@app.route('/job', methods=['GET'])
def create_job():
    # Variables
    namespace = "test"
    new_job_name = "new-job"
    job_image = "perl"  # Example container image, change as needed
    configmap_name= "event-config"
    configmap_key= "event"

    # Step 1: Delete all existing jobs in the "test" namespace
    existing_jobs = batch_v1.list_namespaced_job(namespace=namespace)
    
    for job in existing_jobs.items:
        print(f"Deleting existing job: {job.metadata.name}")
        batch_v1.delete_namespaced_job(name=job.metadata.name, namespace=namespace, propagation_policy="Background")

    # Step 2: Define the job specification
    job_spec = client.V1JobSpec(
        template=client.V1PodTemplateSpec(
            spec=client.V1PodSpec(
                containers=[
                    client.V1Container(
                        name="pi",
                        image=job_image,
                        command=["perl", "-Mbignum=bpi", "-wle", "print bpi(2000)"],
                        env=[
                            client.V1EnvVar(
                                name="event",
                                value_from=client.V1EnvVarSource(
                                    config_map_key_ref=client.V1ConfigMapKeySelector(
                                        name=configmap_name,
                                        key=configmap_key
                                    )
                                )
                            )
                        ]
                    )
                ],
                restart_policy="Never"
            )
        ),
        backoff_limit=4
    )

    # Step 3: Define the job metadata and apply the job spec
    job_metadata = client.V1ObjectMeta(name=new_job_name)

    # Create the new Job object
    new_job = client.V1Job(
        api_version="batch/v1",
        kind="Job",
        metadata=job_metadata,
        spec=job_spec
    )

    # Step 4: Create the new job in the "test" namespace
    batch_v1.create_namespaced_job(namespace=namespace, body=new_job)

    # Return a response
    return jsonify({"message": f"Created a new job '{new_job_name}' in namespace '{namespace}'."})

def update_configmap(namespace, configmap_name, key, new_value):
    # Create an API client
    api_instance = client.CoreV1Api()

    try:
        # Retrieve the existing ConfigMap
        configmap = api_instance.read_namespaced_config_map(name=configmap_name, namespace=namespace)

        # Convert the new value to a JSON string
        json_value = json.dumps(new_value)

        # Update the key-value pair
        if key in configmap.data:
            configmap.data[key] = json_value
        else:
            print(f"Key '{key}' not found in ConfigMap '{configmap_name}'. Adding it.")
            configmap.data[key] = json_value

        # Update the ConfigMap in the cluster
        api_instance.patch_namespaced_config_map(name=configmap_name, namespace=namespace, body=configmap)
        print(f"ConfigMap '{configmap_name}' updated successfully.")
    except client.exceptions.ApiException as e:
        print(f"Exception when calling CoreV1Api->patch_namespaced_config_map: {e}")
        raise

@app.route('/update-config', methods=['POST'])
def update_config():
    try:
        # Get the JSON payload from the request
        payload = request.json

        # Define the namespace and ConfigMap name
        namespace = "test"
        configmap_name = "event-config"
        key = "event"

        # Update the ConfigMap with the payload
        update_configmap(namespace, configmap_name, key, payload)

        return jsonify({"message": "ConfigMap updated successfully"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Run the Flask app
    app.run(host='0.0.0.0', port=5001, debug=True)
