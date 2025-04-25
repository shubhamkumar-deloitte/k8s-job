from flask import Flask, jsonify
from kubernetes import client, config
import time

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

    # Step 1: Delete all existing jobs in the "test" namespace
    existing_jobs = batch_v1.list_namespaced_job(namespace=namespace)
    
    for job in existing_jobs.items:
        print(f"Deleting existing job: {job.metadata.name}")
        batch_v1.delete_namespaced_job(name=job.metadata.name, namespace=namespace, propagation_policy="Background")

    # Step 2: Define the job specification (specify your containers, commands, etc.)
    job_spec = client.V1JobSpec(
        template=client.V1PodTemplateSpec(
            metadata=client.V1ObjectMeta(labels={"job-name": new_job_name}),
            spec=client.V1PodSpec(
                containers=[client.V1Container(
                    name="perl-container",
                    image=job_image,
                    command=["perl", "-Mbignum=bpi", "-wle", "print bpi(2000)"]
                )],
                restart_policy="Never"  # Ensure the job does not restart the pod
            )
        ),
        backoff_limit=4  # Maximum retry limit for failed pods
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

if __name__ == '__main__':
    # Run the Flask app
    app.run(host='0.0.0.0', port=5001, debug=True)
