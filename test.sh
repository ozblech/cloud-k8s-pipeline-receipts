set -euo pipefail

echo "🔄 Fetching all tags..."
git fetch --tags

echo "🔍 Getting current commit SHA..."
CURRENT_SHA=$(git rev-parse HEAD)
SHORT_SHA=$(git rev-parse --short HEAD)

echo "🔍 Getting latest tag starting with 'v'..."
LATEST_TAG=$(git tag --sort=-creatordate | grep '^v' | head -n 1 || true)
LATEST_TAG=${LATEST_TAG:-v1.0.0}
echo "✅ Latest tag: $LATEST_TAG"

VERSION="${LATEST_TAG#v}"
echo "ℹ️ Parsed version: $VERSION"

echo "🟢 Outputting current image tag: ${VERSION}-${SHORT_SHA}"
echo "current_image_tag=${VERSION}-${SHORT_SHA}" 

echo "🔎 Checking if current commit is already tagged..."
EXISTING_TAG=$(git tag --points-at "$CURRENT_SHA" | grep '^v' | head -n 1 || true)

if [ -n "$EXISTING_TAG" ]; then
    echo "⚠️ Commit is already tagged with: $EXISTING_TAG. Skipping version bump."
    echo "new_image_tag=${VERSION}-${SHORT_SHA}"
    echo "new_version=${LATEST_TAG}"
else
    echo "🧮 Bumping patch version..."
    IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"
    NEW_VERSION="${MAJOR}.${MINOR}.$((PATCH + 1))"
    echo "✅ New version: v${NEW_VERSION}"

    echo "new_image_tag=${NEW_VERSION}-${SHORT_SHA}"
    echo "new_version=v${NEW_VERSION}"
fi