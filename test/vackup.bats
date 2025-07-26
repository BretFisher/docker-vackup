#!/usr/bin/env bats

# vackup.bats - BATS tests for vackup

setup() {
  export VACKUP="$BATS_TEST_DIRNAME/../vackup"
  
  # Ensure script is executable
  chmod +x "$VACKUP"
  
  # Generate unique test identifiers to avoid conflicts
  TEST_TIMESTAMP=$(date +%s)
  TEST_PID=$$
  export TEST_PREFIX="vackup_test_${TEST_TIMESTAMP}_${TEST_PID}"
}

teardown() {
  # Clean up volumes with our test prefix (more targeted cleanup)
  docker volume ls -q --filter "name=${TEST_PREFIX}" | while read -r vol; do
    if [ -n "$vol" ] && docker volume rm "$vol" > /dev/null 2>&1; then
      : # Volume removed successfully
    fi
  done
  
  # Clean up images with our test prefix  
  docker image ls -q --filter "reference=${TEST_PREFIX}*" | while read -r img; do
    if [ -n "$img" ] && docker image rm "$img" > /dev/null 2>&1; then
      : # Image removed successfully
    fi
  done
  
  # Clean up test files and directories recursively
  rm -rf "${BATS_TEST_TMPDIR:?}"/*
}


# Helper function to create test data
create_test_data() {
  local vol_name="$1"
  local test_dir="$2"
  
  # Create test files with various characteristics for comprehensive testing
  echo "hello world" > "$test_dir/testfile.txt"
  echo "line1" > "$test_dir/multiline.txt"
  echo "line2" >> "$test_dir/multiline.txt"
  echo "special chars: !@#$%^&*()" > "$test_dir/special_chars.txt"
  mkdir -p "$test_dir/subdir"
  echo "nested file" > "$test_dir/subdir/nested.txt"
  
  # Test with files that have spaces in names (cross-platform compatibility)
  echo "space test" > "$test_dir/file with spaces.txt"
  
  # Copy all test data to volume
  docker run --rm -v "$vol_name":/data -v "$test_dir":/host busybox sh -c "cp -r /host/* /data/"
}

# Helper function to verify volume contents
verify_volume_contents() {
  local vol_name="$1"
  
  # Check that all expected files exist
  docker run --rm -v "$vol_name":/data busybox test -f /data/testfile.txt
  docker run --rm -v "$vol_name":/data busybox test -f /data/multiline.txt  
  docker run --rm -v "$vol_name":/data busybox test -f /data/special_chars.txt
  docker run --rm -v "$vol_name":/data busybox test -f "/data/file with spaces.txt"
  docker run --rm -v "$vol_name":/data busybox test -f /data/subdir/nested.txt
  
  # Verify file contents
  [ "$(docker run --rm -v "$vol_name":/data busybox cat /data/testfile.txt)" = "hello world" ]
}

@test "script is executable and shows usage" {
  [ -x "$VACKUP" ]
  run $VACKUP --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "export" ]]
  [[ "$output" =~ "import" ]]
  [[ "$output" =~ "save" ]]
  [[ "$output" =~ "load" ]]
}

@test "error handling for missing arguments" {
  run $VACKUP export
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Not enough arguments" ]]
  
  run $VACKUP import
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Not enough arguments" ]]
  
  run $VACKUP save
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Not enough arguments" ]]
  
  run $VACKUP load  
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Not enough arguments" ]]
}

@test "error handling for non-existent volume" {
  run $VACKUP export "non_existent_volume_$$" "$BATS_TEST_TMPDIR/test.tar.gz"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "does not exist" ]]
  
  run $VACKUP save "non_existent_volume_$$" "test_image"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "does not exist" ]]
}

@test "error handling for non-existent import file" {
  TEST_VOL="${TEST_PREFIX}_vol_$RANDOM"
  docker volume create "$TEST_VOL" > /dev/null
  
  run $VACKUP import "/non/existent/file.tar.gz" "$TEST_VOL"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Could not find or open tar file" ]]
}

@test "error handling for directory instead of file" {
  TEST_VOL="${TEST_PREFIX}_vol_$RANDOM"
  docker volume create "$TEST_VOL" > /dev/null
  
  run $VACKUP import "$BATS_TEST_TMPDIR" "$TEST_VOL"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "is a directory" ]]
}

@test "export command creates tarball with comprehensive data" {
  TEST_VOL="${TEST_PREFIX}_vol_$RANDOM"
  TEST_TAR="$BATS_TEST_TMPDIR/comprehensive_backup.tar.gz"
  
  docker volume create "$TEST_VOL" > /dev/null
  create_test_data "$TEST_VOL" "$BATS_TEST_TMPDIR"
  
  run $VACKUP export "$TEST_VOL" "$TEST_TAR"
  [ "$status" -eq 0 ]
  [ -f "$TEST_TAR" ]
  [[ "$output" =~ "Successfully tar'ed volume" ]]
  
  # Verify tarball contents
  tar -tzf "$TEST_TAR" | grep "testfile.txt"
  tar -tzf "$TEST_TAR" | grep "multiline.txt"
  tar -tzf "$TEST_TAR" | grep "special_chars.txt"
  tar -tzf "$TEST_TAR" | grep "file with spaces.txt"
  tar -tzf "$TEST_TAR" | grep "subdir/nested.txt"
  
  # Test tarball integrity
  tar -tzf "$TEST_TAR" > /dev/null
}

@test "export command handles relative and absolute paths" {
  TEST_VOL="${TEST_PREFIX}_vol_$RANDOM"
  docker volume create "$TEST_VOL" > /dev/null
  create_test_data "$TEST_VOL" "$BATS_TEST_TMPDIR"
  
  # Test with absolute path
  run $VACKUP export "$TEST_VOL" "$BATS_TEST_TMPDIR/absolute_path.tar.gz"
  [ "$status" -eq 0 ]
  [ -f "$BATS_TEST_TMPDIR/absolute_path.tar.gz" ]
  
  # Test with relative path (from temp dir)
  cd "$BATS_TEST_TMPDIR"
  run $VACKUP export "$TEST_VOL" "relative_path.tar.gz"
  [ "$status" -eq 0 ]
  [ -f "$BATS_TEST_TMPDIR/relative_path.tar.gz" ]
}

@test "import command restores comprehensive data accurately" {
  TEST_VOL="${TEST_PREFIX}_vol_$RANDOM"
  TEST_TAR="$BATS_TEST_TMPDIR/import_test.tar.gz"
  
  # Create and export test data
  docker volume create "$TEST_VOL" > /dev/null
  create_test_data "$TEST_VOL" "$BATS_TEST_TMPDIR"
  $VACKUP export "$TEST_VOL" "$TEST_TAR"
  
  # Remove volume and recreate empty
  docker volume rm "$TEST_VOL" > /dev/null 2>&1 || true
  docker volume create "$TEST_VOL" > /dev/null
  
  # Import and verify
  run $VACKUP import "$TEST_TAR" "$TEST_VOL"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Successfully unpacked" ]]
  
  # Verify all data was restored correctly
  verify_volume_contents "$TEST_VOL"
}

@test "import command creates volume if it doesn't exist" {
  TEST_VOL="${TEST_PREFIX}_vol_$RANDOM"
  TEST_TAR="$BATS_TEST_TMPDIR/create_vol_test.tar.gz"
  
  # Create test data in temporary volume
  TEMP_VOL="${TEST_PREFIX}_temp_$RANDOM"
  docker volume create "$TEMP_VOL" > /dev/null
  create_test_data "$TEMP_VOL" "$BATS_TEST_TMPDIR"
  $VACKUP export "$TEMP_VOL" "$TEST_TAR"
  docker volume rm "$TEMP_VOL" > /dev/null
  
  # Import to non-existent volume
  run $VACKUP import "$TEST_TAR" "$TEST_VOL"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "does not exist, creating" ]]
  [[ "$output" =~ "Successfully unpacked" ]]
  
  # Verify volume was created and data imported
  docker volume inspect "$TEST_VOL" > /dev/null
  verify_volume_contents "$TEST_VOL"
}

@test "save command creates image with volume data" {
  TEST_VOL="${TEST_PREFIX}_vol_$RANDOM"
  TEST_IMAGE="${TEST_PREFIX}_img:$RANDOM"
  
  docker volume create "$TEST_VOL" > /dev/null
  create_test_data "$TEST_VOL" "$BATS_TEST_TMPDIR"
  
  run $VACKUP save "$TEST_VOL" "$TEST_IMAGE"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Successfully copied volume" ]]
  
  # Verify image exists and contains data
  docker image inspect "$TEST_IMAGE" > /dev/null
  docker run --rm "$TEST_IMAGE" test -f /volume-data/testfile.txt
  docker run --rm "$TEST_IMAGE" test -f "/volume-data/file with spaces.txt"
  docker run --rm "$TEST_IMAGE" test -f /volume-data/subdir/nested.txt
  
  # Verify file contents in image
  [ "$(docker run --rm "$TEST_IMAGE" cat /volume-data/testfile.txt)" = "hello world" ]
}

@test "load command restores data from image to volume" {
  TEST_VOL="${TEST_PREFIX}_vol_$RANDOM"
  TEST_IMAGE="${TEST_PREFIX}_img:$RANDOM"
  
  # Create test data and save to image
  docker volume create "$TEST_VOL" > /dev/null
  create_test_data "$TEST_VOL" "$BATS_TEST_TMPDIR"
  $VACKUP save "$TEST_VOL" "$TEST_IMAGE"
  
  # Remove volume and recreate empty
  docker volume rm "$TEST_VOL" > /dev/null 2>&1 || true
  docker volume create "$TEST_VOL" > /dev/null
  
  # Load from image
  run $VACKUP load "$TEST_IMAGE" "$TEST_VOL"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Successfully copied" ]]
  
  # Verify all data was restored
  verify_volume_contents "$TEST_VOL"
}

@test "load command creates volume if it doesn't exist" {
  TEST_VOL="${TEST_PREFIX}_vol_$RANDOM"
  TEST_IMAGE="${TEST_PREFIX}_img:$RANDOM"
  
  # Create test image
  TEMP_VOL="${TEST_PREFIX}_temp_$RANDOM"
  docker volume create "$TEMP_VOL" > /dev/null
  create_test_data "$TEMP_VOL" "$BATS_TEST_TMPDIR"
  $VACKUP save "$TEMP_VOL" "$TEST_IMAGE"
  docker volume rm "$TEMP_VOL" > /dev/null
  
  # Load to non-existent volume
  run $VACKUP load "$TEST_IMAGE" "$TEST_VOL"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "does not exist, creating" ]]
  [[ "$output" =~ "Successfully copied" ]]
  
  # Verify volume was created and data loaded
  docker volume inspect "$TEST_VOL" > /dev/null
  verify_volume_contents "$TEST_VOL"
}

@test "round-trip consistency: export -> import" {
  TEST_VOL1="${TEST_PREFIX}_vol1_$RANDOM"
  TEST_VOL2="${TEST_PREFIX}_vol2_$RANDOM"
  TEST_TAR="$BATS_TEST_TMPDIR/roundtrip.tar.gz"
  
  # Create original data
  docker volume create "$TEST_VOL1" > /dev/null
  create_test_data "$TEST_VOL1" "$BATS_TEST_TMPDIR"
  
  # Export and import to new volume
  $VACKUP export "$TEST_VOL1" "$TEST_TAR"
  docker volume create "$TEST_VOL2" > /dev/null
  $VACKUP import "$TEST_TAR" "$TEST_VOL2"
  
  # Verify data consistency
  verify_volume_contents "$TEST_VOL2"
  
  # Compare file contents between volumes
  original_content=$(docker run --rm -v "$TEST_VOL1":/data busybox cat /data/testfile.txt)
  restored_content=$(docker run --rm -v "$TEST_VOL2":/data busybox cat /data/testfile.txt)
  [ "$original_content" = "$restored_content" ]
}

@test "round-trip consistency: save -> load" {
  TEST_VOL1="${TEST_PREFIX}_vol1_$RANDOM"
  TEST_VOL2="${TEST_PREFIX}_vol2_$RANDOM"  
  TEST_IMAGE="${TEST_PREFIX}_img:$RANDOM"
  
  # Create original data
  docker volume create "$TEST_VOL1" > /dev/null
  create_test_data "$TEST_VOL1" "$BATS_TEST_TMPDIR"
  
  # Save and load to new volume
  $VACKUP save "$TEST_VOL1" "$TEST_IMAGE"
  docker volume create "$TEST_VOL2" > /dev/null
  $VACKUP load "$TEST_IMAGE" "$TEST_VOL2"
  
  # Verify data consistency
  verify_volume_contents "$TEST_VOL2"
  
  # Compare file contents between volumes
  original_content=$(docker run --rm -v "$TEST_VOL1":/data busybox cat /data/testfile.txt)
  restored_content=$(docker run --rm -v "$TEST_VOL2":/data busybox cat /data/testfile.txt)
  [ "$original_content" = "$restored_content" ]
}
