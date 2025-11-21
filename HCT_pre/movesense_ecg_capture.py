import asyncio, struct, time, csv, sys, json, socket
from bleak import BleakClient, BleakScanner, BleakError
from datetime import datetime, timezone

GSP_WRITE   = "34800001-7185-4d5d-b431-630e7050e8f0"
GSP_NOTIFY  = "34800002-7185-4d5d-b431-630e7050e8f0"

PACKET_TYPE_DATA = 2
PACKET_TYPE_DATA_PART2 = 3
REF_ECG = 100

def ts_iso(ts: float) -> str:
    return datetime.fromtimestamp(ts, tz=timezone.utc).isoformat()

class DataView:
    def __init__(self, array): self.array = array
    def __get_bytes(self, start, n): return bytes(self.array[start:start+n])
    def get_uint8(self, start): return int.from_bytes(self.__get_bytes(start,1),'little')
    def get_uint32(self,start): return struct.unpack('<I', self.__get_bytes(start,4))[0]
    def get_int32(self,start): return struct.unpack('<i', self.__get_bytes(start,4))[0]

async def scan_devices(timeout=6, name_substr="Movesense"):
    devices = await BleakScanner.discover(timeout=timeout)
    res = []
    for d in devices:
        if d.name and name_substr.lower() in d.name.lower():
            res.append({"name": d.name, "address": d.address, "rssi": d.rssi})
    return res

async def record_ecg(address, samplerate=200, csv_path="ecg.csv", seconds=0, udp_port=None):
    sample_idx = 0
    t0 = time.time()
    samples_buffer = []
    ongoing_packet = None
    events_buffer = []
    stop_flag = False

    async def drain_samples():
        nonlocal sample_idx
        if not samples_buffer and not events_buffer:
            return
        vals = samples_buffer.copy()
        samples_buffer.clear()
        for v in vals:
            t_rel, t_abs = sample_rel_abs()
            # 가장 가까운 이벤트 기록
            event_str = ''
            new_buf = []
            for ev_time, ev_name in events_buffer:
                if abs(ev_time - t_abs) < 0.15:  # 50ms 내 이벤트
                    event_str = ev_name
                else:
                    new_buf.append((ev_time, ev_name))
            events_buffer[:] = new_buf
            w.writerow([ts_iso(t_abs), f"{t_rel:.6f}", f"{v:.6f}", event_str])
            sample_idx += 1
        f.flush()
    
    # UDP 서버: MATLAB에서 이벤트 수신
    udp_task = None
    if udp_port:
        udp_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        udp_sock.bind(("127.0.0.1", udp_port))
        udp_sock.setblocking(False)

        async def udp_listener():
            nonlocal stop_flag
            while not stop_flag:
                try:
                    data, _ = udp_sock.recvfrom(1024)
                    text = data.decode()
                    events_buffer.append((time.time(), text))
                    if text == "STOP":
                        
                        print("[INFO] Received STOP signal from MATLAB. Exiting...")
                        await drain_samples()
                        stop_flag = True
                        break
                except BlockingIOError:
                    await asyncio.sleep(0.01)
        udp_task = asyncio.create_task(udp_listener())

    f = open(csv_path, "w", newline="")
    w = csv.writer(f)
    w.writerow(["timestamp_utc","t_rel_sec","ecg_mV","event"])
    f.flush()

    def sample_rel_abs(): return sample_idx / float(samplerate), t0 + sample_idx / float(samplerate)

    # async def drain_samples():
    #     nonlocal sample_idx
    #     if not samples_buffer and not events_buffer:
    #         return
    #     vals = samples_buffer.copy()
    #     samples_buffer.clear()
    #     for v in vals:
    #         t_rel, t_abs = sample_rel_abs()
    #         # 가장 가까운 이벤트 기록
    #         event_str = ''
    #         new_buf = []
    #         for ev_time, ev_name in events_buffer:
    #             if abs(ev_time - t_abs) < 0.05:  # 50ms 내 이벤트
    #                 event_str = ev_name
    #             else:
    #                 new_buf.append((ev_time, ev_name))
    #         events_buffer[:] = new_buf
    #         w.writerow([ts_iso(t_abs), f"{t_rel:.6f}", f"{v:.6f}", event_str])
    #         sample_idx += 1
    #     f.flush()

    async def on_notify(_, data: bytearray):
        nonlocal ongoing_packet
        d = DataView(data)
        packet_type = d.get_uint8(0)
        ref = d.get_uint8(1)
        if packet_type == PACKET_TYPE_DATA and ref == REF_ECG:
            timestamp = d.get_uint32(2)
            for i in range(16):
                sample_mV = d.get_int32(6+i*4) * 0.38e-3
                samples_buffer.append(sample_mV)
        elif packet_type == PACKET_TYPE_DATA_PART2 and ongoing_packet:
            d_full = DataView(ongoing_packet.array + data[2:])
            ongoing_packet = None
            timestamp = d_full.get_uint32(2)
            for i in range(8):
                sample_mV = d_full.get_int32(6+i*4) * 0.38e-3
                samples_buffer.append(sample_mV)
        else:
            ongoing_packet = d
    try: 
        async with BleakClient(address, timeout=20.0) as client:
            print(f"[INFO] Trying to connect to {address} ...")
            # await client.connect()
            if not client.is_connected:
                raise BleakError(f"Connection to {address} failed.")
            else:
                print("[INFO] Connected. Starting ECG recording.")
            await client.start_notify(GSP_NOTIFY, on_notify)
            await client.write_gatt_char(GSP_WRITE, bytearray([1, REF_ECG]) + bytearray(f"/Meas/ECG/{samplerate}\x00","ascii"), response=True)
            t_start = time.time()
            while not stop_flag and (seconds==0 or (time.time()-t_start)<seconds):
                await drain_samples()
                await asyncio.sleep(0.05)
            if stop_flag:
                print("[INFO] Final draining...")
                t_end = time.time()
                while time.time() - t_end < 0.5:  # 0.5초 정도
                    await drain_samples()
                    await asyncio.sleep(0.05)
            print("[INFO] Stopping ECG stream...")
            await drain_samples()
            await client.write_gatt_char(GSP_WRITE, bytearray([2, REF_ECG]), response=True)
            await client.stop_notify(GSP_NOTIFY)
            print("[INFO] ECG recprdomg stopped cleanly.")
    except BleakError as e:
        print(f"[ERROR] Could not connect to device: {e}", file=sys.stderr)
    except Exception as e:
        print(f"[ERROR] Recording failed: {e}", file=sys.stderr)
    finally:
        f.close()
        if udp_task: udp_task.cancel()
        if udp_port: udp_sock.close()
        print("[INFO] Program exiting now.")
        sys.exit(0)

def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--scan", action="store_true")
    ap.add_argument("--timeout", type=int, default=6)
    ap.add_argument("--name")
    ap.add_argument("--address")
    ap.add_argument("--samplerate", type=int, default=200)
    ap.add_argument("--csv")
    ap.add_argument("--seconds", type=int, default=0)
    ap.add_argument("--mv", action="store_true")
    ap.add_argument("--udp", type=int)
    args = ap.parse_args()

    if args.scan:
        devices = asyncio.run(scan_devices(args.timeout, args.name))
        if devices:
            devices.sort(key=lambda d: d['rssi'], reverse=True)
            # JSON 배열로 한 번에 출력
            print(json.dumps(devices))
        else:
            print("[]")
        sys.exit(0)
    if not args.address or not args.csv:
        print("Please specify --address and --csv for recording.", file=sys.stderr)
        sys.exit(1)
    try:
        asyncio.run(record_ecg(args.address, args.samplerate, args.csv, args.seconds, args.udp))
    except Exception as e:
        print(f"[ERROR] Failed to connect or record ECG: {e}", file=sys.stderr)
        sys.exit(2)
if __name__ == "__main__":
    main()
