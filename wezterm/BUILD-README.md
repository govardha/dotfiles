# Extract all WezTerm binaries
docker run --rm -v $(pwd):/output wezterm-builder bash -c "cp /build/target/release/wezterm* /output/"
