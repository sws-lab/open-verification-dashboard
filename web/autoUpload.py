import requests
import json
import os


def upload_proof_obligation(server_url, project_id, revision, name, file_path):
    with open(file_path, "r") as file:
        content = json.load(file)

        response = requests.put(
            f"{server_url}/api/proofObligations",
            json={
                "name": name,
                "projectId": project_id,
                "revision": revision,
                "proofObligation": content,
            },
            headers={"Accept": "application/json"},
        )

    if response.status_code == 200:
        print(
            f"Successfully uploaded proof obligation '{name}' for project {project_id} revision {revision}."
        )
        return response.json().get("id", -1)
    else:
        print(
            f"Failed to upload proof obligation '{name}'. Status code: {response.status_code}"
        )
        if response.headers.get("Content-Type") == "application/json":
            print("Response:", json.dumps(response.json(), indent=2))
        return -1


def compare_proof_obligations(server_url, id1, id2, open_in_browser):
    response = requests.post(
        f"{server_url}/api/proofObligations/compare",
        json={"proofObligationId1": id1, "proofObligationId2": id2},
    )
    if response.status_code == 200:
        comparison_result = response.json()
        print(f"Comparison result between {id1} and {id2}:")
        url = f"{server_url}/projects/analysis/{comparison_result['id']}"
        print(url)
        if open_in_browser:
            import webbrowser

            webbrowser.open(url)

        return comparison_result["id"]
    else:
        print(
            f"Failed to compare proof obligations {id1} and {id2}. Status code: {response.status_code}"
        )
        if response.headers.get("Content-Type") == "application/json":
            print("Response:", json.dumps(response.json(), indent=2))
        return -1


def upload_proof_obligations(server_url, project_id, revision, proof_obligations):
    uploaded_ids = []
    for name, file_path in proof_obligations:
        if not os.path.exists(file_path):
            print(f"File {file_path} does not exist. Skipping upload.")
            continue
        uploaded_id = upload_proof_obligation(
            server_url, project_id, revision, name, file_path
        )
        if uploaded_id == -1:
            print(f"Failed to upload proof obligation '{name}'.")
            exit(1)
        uploaded_ids.append(uploaded_id)
    return uploaded_ids


def upload_and_compare_proof_obligations(
    server_url, project_id, revision, proof_obligations, compare
):
    uploaded_ids = upload_proof_obligations(
        server_url, project_id, revision, proof_obligations
    )

    if compare and len(uploaded_ids) >= 2:
        print("Comparing proof obligations...")
        if len(uploaded_ids) == 2:
            compare_proof_obligations(
                server_url, uploaded_ids[0], uploaded_ids[1], True
            )
        else:
            for i in range(len(uploaded_ids)):
                for j in range(i + 1, len(uploaded_ids)):
                    compare_proof_obligations(
                        server_url, uploaded_ids[i], uploaded_ids[j], False
                    )
    else:
        print(
            "No comparison requested or not enough proof obligations uploaded for comparison."
        )


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Upload a proof obligation to the server."
    )
    parser.add_argument(
        "--server_url",
        type=str,
        default="http://localhost:5173",
        metavar="<URL>",
        help="URL of the server to upload the proof obligation to.",
    )
    parser.add_argument(
        "--project",
        type=int,
        required=True,
        nargs=2,
        metavar=("<ID>", "<REVISON>"),
        help="Project ID and revision to which the proof obligation belongs.",
    )
    parser.add_argument(
        "--proof-obligation",
        nargs=2,
        metavar=("<NAME>", "<FILE>"),
        action="append",
        required=True,
        help="Name and file of the proof obligations to upload. Can be specified multiple times.",
    )
    parser.add_argument(
        "--compare",
        action="store_true",
        help="If two proof obligations are provided, it also compares them. If more than two are provided, it compares every pair.",
    )
    args = parser.parse_args()

    print(f"Uploading proof obligations to {args.server_url}...")
    upload_and_compare_proof_obligations(
        args.server_url,
        args.project[0],
        args.project[1],
        args.proof_obligation,
        args.compare,
    )
