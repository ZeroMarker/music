"""Record the Canon arrangement using the Ubuntu Sonic Pi 3.2 server and JACK."""

import argparse
import json
import math
import os
from pathlib import Path
import signal
import socket
import struct
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parent.parent
SONIC_PI_SERVER = Path('/usr/lib/sonic-pi/app/server/ruby/bin/sonic-pi-server.rb')


def osc_string(value):
    data = value.encode() + b'\0'
    return data.ljust((len(data) + 3) // 4 * 4, b'\0')


def wait_for_log(process, log, marker, timeout):
    deadline = time.monotonic() + timeout
    while process.poll() is None and time.monotonic() < deadline:
        if marker in log.read_text(errors='replace'):
            return
        time.sleep(0.2)
    raise RuntimeError(f'{marker} missing from {log.name}\n{log.read_text(errors="replace")}')


def stop_group(process):
    # The Sonic Pi server can leave its Erlang scheduler in the process group.
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        process.wait()


def record(duration, output, work, gui):
    env = dict(os.environ, SONIC_PI_HOME=str(work), JACK_DEFAULT_SERVER=f'canon-{os.getpid()}')
    # Reserve distinct loopback ports until the server is ready to bind them.
    with_port = [socket.socket(socket.AF_INET, socket.SOCK_DGRAM) for _ in range(7)]
    try:
        for port_socket in with_port:
            port_socket.bind(('127.0.0.1', 0))
        server_port, sc_port, cues, erlang, midi_out, midi_in, web = [sock.getsockname()[1] for sock in with_port]
    finally:
        for port_socket in with_port:
            port_socket.close()

    def send(address, *values):
        packet = osc_string(address) + osc_string(',i' + 's' * len(values)) + struct.pack('>i', 0)
        gui.sendto(packet + b''.join(map(osc_string, values)), ('127.0.0.1', server_port))

    jack_log, sonic_log = work / 'jack.log', work / 'sonic-pi.log'
    with jack_log.open('w') as log:
        jack = subprocess.Popen(['jackd', '-r', '-n', env['JACK_DEFAULT_SERVER'], '--port-max', '64',
                                 '-d', 'dummy', '-r', '44100', '-p', '1024'],
                                env=env, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
    try:
        wait_for_log(jack, jack_log, 'starting in non-realtime mode', 10)
        ports = (server_port, gui.getsockname()[1], sc_port, sc_port, cues, erlang, midi_out, midi_in, web)
        with sonic_log.open('w') as log:
            sonic = subprocess.Popen(['stdbuf', '-oL', '-eL', 'ruby', str(SONIC_PI_SERVER), '-u', *map(str, ports)],
                                     env=env, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        try:
            wait_for_log(sonic, sonic_log, 'successfully booted', 30)
            # Use run_file so the score does not have to fit in one OSC datagram.
            (work / 'score.rb').symlink_to(ROOT / 'canon/sonic_pi.rb')
            send('/start-recording')
            time.sleep(0.5)
            send('/run-code', f'run_file "{work / "score.rb"}"')
            gui.settimeout(0.25)
            deadline = time.monotonic() + duration + 1
            while time.monotonic() < deadline:
                if sonic.poll() is not None:
                    raise RuntimeError('Sonic Pi exited during recording')
                try:
                    message = gui.recv(65_535)
                except TimeoutError:
                    continue
                if message.startswith((b'/error\0', b'/syntax_error\0')):
                    raise RuntimeError(message.decode(errors='replace').replace('\0', ' ').strip())
            send('/stop-all-jobs')
            send('/stop-recording')
            time.sleep(0.5)
            recording = work / 'capture.wav'
            send('/save-recording', str(recording))
            deadline = time.monotonic() + 15
            while not recording.is_file():
                if time.monotonic() >= deadline or sonic.poll() is not None:
                    raise RuntimeError('Sonic Pi did not save a recording')
                time.sleep(0.2)
            send('/exit')
            sonic.wait(timeout=10)
            output.parent.mkdir(parents=True, exist_ok=True)
            subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', recording, '-t', str(duration),
                            '-c:a', 'pcm_s16le', output], check=True)
        finally:
            stop_group(sonic)
    finally:
        stop_group(jack)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'canon/canon_sonic_pi.wav')
    parser.add_argument('--duration', type=float)
    args = parser.parse_args()
    project = json.loads((ROOT / 'canon/project.json').read_text())
    duration = project['renderDurationSeconds'] if args.duration is None else args.duration
    if not math.isfinite(duration) or duration < 2:
        parser.error('--duration must be at least 2 seconds')
    if not SONIC_PI_SERVER.is_file():
        parser.error('install sonic-pi-server, JACK and FFmpeg on Ubuntu 24.04')
    with tempfile.TemporaryDirectory(prefix='canon-sonic-') as work, socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as gui:
        gui.bind(('127.0.0.1', 0))
        record(duration, args.output, Path(work), gui)
    print(f'Wrote {args.output}')


if __name__ == '__main__':
    main()
