# Net-Radio

An internet radio streaming system designed for single-board computers like the Raspberry Pi. Stream internet radio stations through connected speakers, controlled via a physical button or web interface.

## Features

- Stream internet radio stations with automatic reconnection
- Switch between multiple saved stations
- Physical button control for cycling stations
- Web interface for managing stations and playback
- GPIO-controlled mute/unmute for speaker power management
- Fallback to yt-dlp for streams requiring URL resolution

## Hardware Requirements

- Raspberry Pi (or similar SBC with GPIO)
- Audio output (3.5mm jack, HDMI, or USB audio)
- Speaker or powered amplifier
- Momentary push button (connected to GPIO 27)
- Optional: Relay/amplifier with control input (GPIO 17 for mute control)

### GPIO Pinout

| Pin | Function |
|-----|----------|
| GPIO 27 | Next station button (active low) |
| GPIO 17 | Unmute control (high = audio on) |

## Dependencies

Install the required packages:

```bash
sudo apt update
sudo apt install ffmpeg curl libgpiod-tools
```

Install yt-dlp (for streams requiring URL resolution):

```bash
sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
sudo chmod a+rx /usr/local/bin/yt-dlp
```

Install Go 1.22+ (required for HTTP route syntax):

```bash
# Debian/Ubuntu package may be too old; install from official release:
curl -LO https://go.dev/dl/go1.22.0.linux-arm64.tar.gz  # or amd64
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.22.0.linux-arm64.tar.gz
export PATH=/usr/local/go/bin:$PATH
```

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url> /home/pidio
   cd /home/pidio
   ```

2. Build the server:
   ```bash
   go build -o nr-server nr-server.go
   ```

3. Allow the server to bind to port 80 without root:
   ```bash
   sudo setcap CAP_NET_BIND_SERVICE=+eip /home/pidio/nr-server
   ```

4. Create the initial station file:
   ```bash
   echo "http://your-favorite-station-url" > station.txt
   ```

5. Install the systemd services:
   ```bash
   sudo cp systemd/*.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable stream.service server.service button.service
   sudo systemctl start stream.service server.service button.service
   ```

## Usage

### Web Interface

Access the web interface at `http://<device-ip>/`

From here you can:
- View the current station list
- Add new stations by entering a stream URL
- Click "Next Station" to cycle to the next station

### Physical Button

Press the button connected to GPIO 27 to cycle to the next station.

### Managing Stations

Stations are stored in `station.txt`, one URL per line. The first line is the currently playing station. When you press "Next Station", the list rotates so the next station moves to the top.

## File Structure

```
.
├── nr-server.go    # Web server (Go)
├── stream.sh       # Audio streaming script
├── button.sh       # Physical button handler
├── server.sh       # Server startup wrapper
├── index.html      # Web interface
├── station.txt     # Station URLs (created at runtime)
├── systemd/        # Systemd service files
│   ├── stream.service
│   ├── server.service
│   └── button.service
└── test/
    ├── gpioget         # Mock gpioget script
    ├── setup-vm.sh     # Local mock GPIO setup
    ├── press-button.sh # Simulate button press
    └── vm/             # QEMU VM testing
        ├── fetch-image.sh  # Download Debian cloud image
        ├── make-seed.sh    # Create cloud-init config
        ├── start-vm.sh     # Start VM
        ├── stop-vm.sh      # Stop VM
        ├── ssh-vm.sh       # SSH into VM
        └── copy-project.sh # Copy project to VM
```

## Testing

### Option 1: Local Mock GPIO

For quick testing on your dev machine:

```bash
./test/setup-vm.sh
./stream.sh &
./nr-server &
./button.sh &

# Simulate button press
./test/press-button.sh
```

### Option 2: QEMU VM (Cross-Platform)

Full Linux VM testing with Debian cloud image. Uses cloud-init for automated setup including mock GPIO, ffmpeg, and curl. Requires QEMU:

```bash
# macOS
brew install qemu

# Debian/Ubuntu
sudo apt install qemu-system
```

**Initial setup:**

```bash
cd test/vm
./fetch-image.sh    # Download Debian cloud image (~350MB)
./make-seed.sh      # Create cloud-init ISO with your SSH key
./start-vm.sh       # Start VM in background
```

Wait 60-90 seconds for first boot (cloud-init installs packages).

**Port forwarding:**
- `localhost:2222` → VM SSH (port 22)
- `localhost:8080` → VM HTTP (port 80)

**Copy project and run:**

```bash
# Copy files to VM
scp -P 2222 *.go *.sh *.html user@localhost:~/net-radio/

# SSH in
./ssh-vm.sh

# Inside VM: install Go 1.22 (Debian 12 ships 1.19, too old)
curl -LO https://go.dev/dl/go1.22.0.linux-arm64.tar.gz
sudo tar -C /usr/local -xzf go1.22.0.linux-arm64.tar.gz
export PATH=/usr/local/go/bin:$PATH

# Build and run
cd ~/net-radio
sudo mkdir -p /home/pidio && sudo cp index.html /home/pidio/
go build -o nr-server nr-server.go
sudo setcap CAP_NET_BIND_SERVICE=+eip ./nr-server
echo "http://stream.live.vc.bbcmedia.co.uk/bbc_radio_one" > station.txt
./nr-server &
```

**Access from host:** `http://localhost:8080`

**Stop VM:**

```bash
./stop-vm.sh
```

**Notes:**
- Go 1.22+ required (uses `GET /` route syntax added in 1.22)
- Server expects `index.html` at `/home/pidio/index.html` (hardcoded)
- Mock `gpioget` is installed at `/usr/local/bin/gpioget` by cloud-init
- GPIO state files: `test/mock-gpio/17` (unmute), `test/mock-gpio/27` (button)

## Troubleshooting

**VM: Server returns 404:**
- Ensure Go 1.22+ is installed (`go version`). The `GET /` route syntax requires 1.22+.
- Debian 12 ships Go 1.19; install from https://go.dev/dl/

**VM: "permission denied" on port 80:**
- Run: `sudo setcap CAP_NET_BIND_SERVICE=+eip ./nr-server`

**VM: "index.html: no such file or directory":**
- Server expects `/home/pidio/index.html`. Create with: `sudo mkdir -p /home/pidio && sudo cp index.html /home/pidio/`

**No audio output:**
- Check that GPIO 17 is correctly connected for unmute control
- Verify audio output configuration with `aplay -l`
- Test with `ffplay <stream-url>` directly

**Button not working:**
- Verify button is connected between GPIO 27 and ground
- Test with `gpioget gpiochip0 27`

**Server won't start on port 80:**
- Ensure capabilities are set: `sudo setcap CAP_NET_BIND_SERVICE=+eip /home/pidio/nr-server`

**Stream fails to play:**
- Some streams require yt-dlp for URL resolution; ensure it's installed
- Check the stream URL is valid and accessible

## License

MIT
