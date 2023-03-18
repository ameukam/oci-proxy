#!/usr/bin/env bash

# Copyright 2022 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit -o nounset -o pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
cd "${REPO_ROOT}"

TAG="${TAG:-"$(date +v%Y%m%d)-$(git describe --always --dirty)"}"
SERVICE_BASENAME="${SERVICE_BASENAME:-k8s-infra-oci-proxy}"
IMAGE_REPO="${IMAGE_REPO:-gcr.io/k8s-staging-infra-tools/archeio}"
PROJECT="${PROJECT:-k8s-infra-oci-proxy}"

REGIONS=(
    asia-east1
    asia-northeast1
    asia-northeast2
    asia-south1
    australia-southeast1
    europe-north1
    europe-southwest1
    europe-west1
    europe-west2
    europe-west4
    europe-west8
    europe-west9
    southamerica-west1
    us-central1
    us-east1
    us-east4
    us-east5
    us-south1
    us-west1
    us-west2
)

for REGION in "${REGIONS[@]}"; do
    gcloud --project="${PROJECT}" \
        run services update "${SERVICE_BASENAME}-${REGION}" \
        --image "${IMAGE_REPO}:${TAG}" \
        --region "${REGION}" \
        --concurrency 1000 \
        --max-instances 10 \
        `# NOTE: should match number of cores configured` \
        --update-env-vars GOMAXPROCS=1,DEFAULT_AWS_BASE_URL="https://d3dch67310fpds.cloudfront.net",UPSTREAM_REGISTRY_PATH=k8s-artifacts-prod/images,"UPSTREAM_REGISTRY_ENDPOINT=https://$REGION-docker.pkg.dev" \
        `# TODO: if we use this to deploy prod, we need to handle this differently` \
        --args=-v=3
done
