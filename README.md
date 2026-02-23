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

Install Go (for building the server):

```bash
sudo apt install golang
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
└── test/           # VM testing utilities
    ├── gpioget         # Mock gpioget script
    ├── setup-vm.sh     # VM setup script
    └── press-button.sh # Simulate button press
```

## VM Testing

For testing without hardware, use the mock GPIO setup:

1. Run the setup script:
   ```bash
   ./test/setup-vm.sh
   ```

2. Ensure `~/.local/bin` is in your PATH:
   ```bash
   export PATH="$HOME/.local/bin:$PATH"
   ```

3. Start the services:
   ```bash
   ./stream.sh &
   ./nr-server &
   ./button.sh &
   ```

4. Control via mock GPIO:
   ```bash
   # Simulate button press
   ./test/press-button.sh

   # Mute audio
   echo 0 > ~/.gpio-mock/17

   # Unmute audio
   echo 1 > ~/.gpio-mock/17
   ```

## Troubleshooting

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
