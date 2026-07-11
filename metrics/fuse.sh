#!/usr/bin/env bash

# ==============================================================================
# FileLocker Automated Evaluation & Benchmarking Script
# Tailored specifically for fort++ and openfort FUSE integration
# ==============================================================================

# --- 1. CONFIGURATION & PATHS ---
# Build paths based on current directory
ROOT_DIR=$(pwd)
FORT_EXEC="$ROOT_DIR/fort++"
OPENFORT_EXEC="$ROOT_DIR/openfort"

# Test directories
BENCH_DIR="$ROOT_DIR/benchmark_playground"
CONFIG_DIR="$BENCH_DIR/vault_config"
MOUNT_DIR="$BENCH_DIR/vault_mount"
NATIVE_DIR="$BENCH_DIR/native_out"
RAM_LOG="$BENCH_DIR/peak_ram.log"

# Test File Sizes in Megabytes (MB)
FILE_SIZES=(100 500 1000)

echo "====================================================================================================="
echo " 🔒 Starting FileLocker System Evaluation Pipeline..."
echo "====================================================================================================="

# --- 2. SANITY CHECKS ---
if [ ! -f "$FORT_EXEC" ] || [ ! -f "$OPENFORT_EXEC" ]; then
    echo "❌ Error: Executables not found! Please run 'make' first to build fort++ and openfort."
    exit 1
fi

# Clean up any previous broken runs
fusermount -u "$MOUNT_DIR" 2>/dev/null
rm -rf "$BENCH_DIR"
mkdir -p "$CONFIG_DIR" "$MOUNT_DIR" "$NATIVE_DIR"

# --- 3. INITIALIZE VAULT & MOUNT FUSE ---
echo "⚙️  Step 1: Initializing vault configuration using fort++..."
"$FORT_EXEC" init "$CONFIG_DIR" >/dev/null 2>&1

if [ ! -f "$CONFIG_DIR/lazylocking.conf" ]; then
    echo "❌ Error: Failed to generate lazylocking.conf in $CONFIG_DIR."
    exit 1
fi

echo "🗂️  Step 2: Mounting encrypted FUSE filesystem using openfort..."
"$OPENFORT_EXEC" "$CONFIG_DIR" "$MOUNT_DIR"
sleep 1 # Allow OS kernel a moment to register the mount

# Verify FUSE mount is active
if ! mount | grep -q "$MOUNT_DIR"; then
    echo "❌ Error: FUSE mount failed at $MOUNT_DIR. Check permissions or run 'sudo modprobe fuse'."
    exit 1
fi
echo "✅ FUSE successfully mounted at $MOUNT_DIR!"

# --- 4. RAM MONITORING HELPER FUNCTIONS ---
start_ram_monitor() {
    echo "0" > "$RAM_LOG"
    local pid=$(pgrep -x "openfort" | head -n 1)
    if [ -n "$pid" ]; then
        (
            while true; do
                local current=$(ps -o rss= -p "$pid" 2>/dev/null | tr -d ' ')
                if [ -n "$current" ]; then
                    local peak=$(cat "$RAM_LOG" 2>/dev/null || echo "0")
                    if [ "$current" -gt "$peak" ]; then
                        echo "$current" > "$RAM_LOG"
                    fi
                fi
                sleep 0.05
            done
        ) &
        RAM_MONITOR_PID=$!
    else
        RAM_MONITOR_PID=""
    fi
}

stop_ram_monitor() {
    if [ -n "$RAM_MONITOR_PID" ]; then
        kill "$RAM_MONITOR_PID" 2>/dev/null
        wait "$RAM_MONITOR_PID" 2>/dev/null
    fi
}

# --- 5. EXECUTE BENCHMARKS ---
printf "\n%-10s | %-13s | %-13s | %-16s | %-16s | %-12s | %-10s\n" "Size (MB)" "Native Time" "FUSE Time" "Native Speed" "FileLocker Speed" "Overhead" "Peak RAM"
echo "---------------------------------------------------------------------------------------------------------------------"

for SIZE in "${FILE_SIZES[@]}"; do
    TEST_FILE="$BENCH_DIR/dummy_${SIZE}MB.bin"
    NATIVE_OUT="$NATIVE_DIR/out_${SIZE}MB.bin"
    FUSE_OUT="$MOUNT_DIR/out_${SIZE}MB.bin"

    # Step A: Generate random dummy test file
    if [ ! -f "$TEST_FILE" ]; then
        dd if=/dev/urandom of="$TEST_FILE" bs=1M count="$SIZE" status=none
    fi

    # Step B: Benchmark Native Disk Copy (Unencrypted Baseline)
    sync; sudo sysctl -w vm.drop_caches=3 >/dev/null 2>&1
    
    START_TIME=$(date +%s.%N)
    cp "$TEST_FILE" "$NATIVE_OUT"
    sync # Ensure bytes physically flush to disk
    END_TIME=$(date +%s.%N)
    NATIVE_TIME=$(awk -v start="$START_TIME" -v end="$END_TIME" 'BEGIN { printf "%.3f", end - start }')

    # Step C: Benchmark FUSE Transparent Encryption + Track Daemon RAM
    sync; sudo sysctl -w vm.drop_caches=3 >/dev/null 2>&1
    
    start_ram_monitor
    START_TIME=$(date +%s.%N)
    cp "$TEST_FILE" "$FUSE_OUT"
    sync # Ensure FUSE encrypts, encodes URL-safe names, and flushes to storage
    END_TIME=$(date +%s.%N)
    stop_ram_monitor
    FUSE_TIME=$(awk -v start="$START_TIME" -v end="$END_TIME" 'BEGIN { printf "%.3f", end - start }')

    # Step D: Calculate Performance Metrics
    NATIVE_SPEED=$(awk -v size="$SIZE" -v time="$NATIVE_TIME" 'BEGIN { printf "%.2f MB/s", size / time }')
    FUSE_SPEED=$(awk -v size="$SIZE" -v time="$FUSE_TIME" 'BEGIN { printf "%.2f MB/s", size / time }')
    
    # Overhead Formula: ((FUSE Time - Native Time) / Native Time) * 100
    OVERHEAD=$(awk -v nat="$NATIVE_TIME" -v fuse="$FUSE_TIME" 'BEGIN { 
        if (nat > 0) printf "%.1f%%", ((fuse - nat) / nat) * 100; else printf "0.0%"; 
    }')

    # Convert Peak RAM from KB to MB
    PEAK_RAM_KB=$(cat "$RAM_LOG" 2>/dev/null || echo "0")
    if [ "$PEAK_RAM_KB" -gt 0 ]; then
        PEAK_RAM_MB=$(awk -v kb="$PEAK_RAM_KB" 'BEGIN { printf "%.1f MB", kb / 1024 }')
    else
        PEAK_RAM_MB="N/A*"
    fi

    # Step E: Print Row
    printf "%-10s | %-13s | %-13s | %-16s | %-16s | %-12s | %-10s\n" "$SIZE" "${NATIVE_TIME}s" "${FUSE_TIME}s" "$NATIVE_SPEED" "$FUSE_SPEED" "$OVERHEAD" "$PEAK_RAM_MB"

    # Cleanup output files to prevent filling up disk space
    rm -f "$NATIVE_OUT" "$FUSE_OUT"
done

# --- 6. CLEANUP & UNMOUNT ---
echo "---------------------------------------------------------------------------------------------------------------------"
echo "🧹 Cleaning up: Unmounting FUSE filesystem and deleting test data..."
fusermount -u "$MOUNT_DIR"
rm -rf "$BENCH_DIR"

