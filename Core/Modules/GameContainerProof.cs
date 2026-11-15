using System;
using System.IO;
using System.IO.Compression;
using System.Text;
using System.Collections.Generic;
using System.Threading;

// Bounded, read-only identification of original game containers.
// File names, hashes and historical download sizes are not allowlists.
public static class PCVRGameContainerProof
{
    private sealed class Entry { public string Name; public string RawName; public long Offset; public long Length; }
    private sealed class Index
    {
        public bool Mpq;
        public Dictionary<string, Entry> Entries = new Dictionary<string, Entry>(StringComparer.OrdinalIgnoreCase);
        public HashSet<string> Maps = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        public Dictionary<string, bool> ReadableZipMembers = new Dictionary<string, bool>(StringComparer.OrdinalIgnoreCase);
    }
    private sealed class Cached { public long Length; public long Write; public Index Index; }
    private static readonly Dictionary<string, Cached> Cache = new Dictionary<string, Cached>(StringComparer.OrdinalIgnoreCase);
    private static readonly object CacheSync = new object();
    private sealed class CompletedProof { public long Length; public long Write; }
    private static readonly Dictionary<string, CompletedProof> Completed = new Dictionary<string, CompletedProof>(StringComparer.Ordinal);
    private static readonly object[] ReadGates = MakeReadGates();
    private static readonly HashSet<string> Warming = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
    private static readonly SemaphoreSlim WarmSlots = new SemaphoreSlim(6);
    private static object[] MakeReadGates()
    {
        object[] gates = new object[64];
        for (int i = 0; i < gates.Length; i++) gates[i] = new object();
        return gates;
    }
    // This only primes the same read-only proof used by Test. It never
    // changes game/state files or independently claims a game is installed.
    public static void Warm(string path, string format, string[] required, string[] excluded, string[] maps)
    {
        string key;
        try { key = Path.GetFullPath(path) + "|" + format; } catch { return; }
        lock (CacheSync) { if (!Warming.Add(key)) return; }
        ThreadPool.QueueUserWorkItem(delegate
        {
            WarmSlots.Wait();
            try { Test(path, format, required, excluded, maps); }
            catch { }
            finally { WarmSlots.Release(); lock (CacheSync) { Warming.Remove(key); } }
        });
    }
    private const int MaximumEntries = 200000;
    private static readonly uint[] MpqCryptTable = MakeMpqCryptTable();
    private static uint[] MakeMpqCryptTable()
    {
        uint[] table = new uint[1280]; uint seed = 0x100001;
        for (int low = 0; low < 256; low++)
            for (int high = 0; high < 5; high++)
            {
                seed = (seed * 125 + 3) % 0x2AAAAB; uint upper = (seed & 65535) << 16;
                seed = (seed * 125 + 3) % 0x2AAAAB; table[low + high * 256] = upper | (seed & 65535);
            }
        return table;
    }
    private static uint MpqHash(string name, int kind)
    {
        uint one = 0x7FED7FED, two = 0xEEEEEEEE;
        foreach (byte c in Encoding.ASCII.GetBytes(name.Replace('/', '\\').ToUpperInvariant()))
        { one = unchecked(MpqCryptTable[kind + c] ^ (one + two)); two = unchecked(c + one + two + (two << 5) + 3); }
        return one;
    }
    private static string MpqName(uint first, uint second)
    { return "mpq/" + first.ToString("X8") + second.ToString("X8"); }
    private static byte[] MpqDecrypt(byte[] bytes, uint key)
    {
        uint seed = 0xEEEEEEEE;
        for (int at = 0; at < bytes.Length; at += 4)
        {
            seed = unchecked(seed + MpqCryptTable[0x400 + (key & 255)]);
            uint word = BitConverter.ToUInt32(bytes, at) ^ unchecked(key + seed);
            key = unchecked(((~key << 21) + 0x11111111) | (key >> 11));
            seed = unchecked(word + seed + (seed << 5) + 3);
            Array.Copy(BitConverter.GetBytes(word), 0, bytes, at, 4);
        }
        return bytes;
    }
    private static bool ContainsEntry(Index index, string name)
    { return index.Entries.ContainsKey(index.Mpq ? MpqName(MpqHash(name, 0x100), MpqHash(name, 0x200)) : name.Replace('\\', '/')); }
    private sealed class RegionStream : Stream
    {
        private readonly Stream source;
        private readonly long origin;
        public RegionStream(Stream stream, long start) { source = stream; origin = start; source.Position = start; }
        public override bool CanRead { get { return true; } }
        public override bool CanSeek { get { return true; } }
        public override bool CanWrite { get { return false; } }
        public override long Length { get { return source.Length - origin; } }
        public override long Position { get { return source.Position - origin; } set { Seek(value, SeekOrigin.Begin); } }
        public override int Read(byte[] buffer, int offset, int count) { return source.Read(buffer, offset, (int)Math.Min(count, Length - Position)); }
        public override long Seek(long offset, SeekOrigin kind)
        {
            long target = kind == SeekOrigin.Begin ? offset : kind == SeekOrigin.Current ? Position + offset : Length + offset;
            if (target < 0 || target > Length) throw new IOException();
            source.Position = origin + target; return target;
        }
        public override void Flush() { }
        public override void SetLength(long value) { throw new NotSupportedException(); }
        public override void Write(byte[] buffer, int offset, int count) { throw new NotSupportedException(); }
    }
    private static Stream ZipRegion(Stream stream)
    {
        stream.Position = 0;
        byte[] head = new byte[4]; if (stream.Read(head, 0, 4) != 4) throw new InvalidDataException();
        if (head[0] == 80 && head[1] == 75) return new RegionStream(stream, 0);
        if (head[0] != 77 || head[1] != 90) throw new InvalidDataException();
        // A fused LÖVE executable keeps ZIP offsets relative to its appended archive.
        // Expose that exact region without loading or executing the PE image.
        int length = (int)Math.Min(stream.Length, 65557);
        byte[] tail = new byte[length]; stream.Position = stream.Length - length;
        int read = 0; while (read < length) { int n = stream.Read(tail, read, length - read); if (n == 0) throw new EndOfStreamException(); read += n; }
        for (int at = length - 22; at >= 0; at--)
        {
            if (tail[at] != 80 || tail[at + 1] != 75 || tail[at + 2] != 5 || tail[at + 3] != 6) continue;
            if (at + 22 + BitConverter.ToUInt16(tail, at + 20) != length) continue;
            long directoryLength = BitConverter.ToUInt32(tail, at + 12), directoryOffset = BitConverter.ToUInt32(tail, at + 16);
            long prefix = stream.Length - length + at - directoryLength - directoryOffset;
            if (prefix <= 0 || !Bounds(prefix, directoryOffset + directoryLength, stream.Length)) throw new InvalidDataException();
            stream.Position = prefix;
            byte[] magic = new byte[4]; if (stream.Read(magic, 0, 4) != 4 || magic[0] != 80 || magic[1] != 75 || magic[2] != 3 || magic[3] != 4) throw new InvalidDataException();
            return new RegionStream(stream, prefix);
        }
        throw new InvalidDataException();
    }
    private static string Name(byte[] bytes, int offset, int count)
    {
        int end = offset;
        while (end < offset + count && bytes[end] != 0) end++;
        return Encoding.ASCII.GetString(bytes, offset, end - offset).Replace('\\', '/');
    }
    private static bool Bounds(long offset, long length, long total)
    { return offset >= 0 && length >= 0 && offset <= total && length <= total - offset; }
    private static uint Big32(byte[] bytes, int offset)
    { return ((uint)bytes[offset] << 24) | ((uint)bytes[offset + 1] << 16) | ((uint)bytes[offset + 2] << 8) | bytes[offset + 3]; }
    private static ulong Big64(byte[] bytes, int offset)
    { return ((ulong)Big32(bytes, offset) << 32) | Big32(bytes, offset + 4); }
    private static byte[] ReadAt(Stream stream, long offset, int count)
    {
        if (!Bounds(offset, count, stream.Length)) throw new InvalidDataException();
        stream.Position = offset; byte[] bytes = new byte[count]; int done = 0;
        while (done < count) { int n = stream.Read(bytes, done, count - done); if (n <= 0) throw new EndOfStreamException(); done += n; }
        return bytes;
    }
    private static byte[] DiscHeader(Stream stream)
    {
        // Container offsets follow Dolphin's DiscIO readers and WiaAndRvz.md.
        // Read one bounded header/block, never execute tools or expand a disc.
        if (stream.Length < 0x440) return null;
        byte[] head = ReadAt(stream, 0, 128);
        string magic = Encoding.ASCII.GetString(head, 0, 4);
        if (magic == "RVZ\x01" || magic == "WIA\x01")
        {
            uint infoLength = Big32(head, 12), type = Big32(head, 72);
            if (infoLength < 144 || infoLength > 1048576 || !Bounds(72, infoLength, stream.Length) ||
                Big64(head, 44) != (ulong)stream.Length || Big64(head, 36) < 0x440 || (type != 1 && type != 2)) return null;
            return ReadAt(stream, 88, 128);
        }
        if (magic == "CISO")
        {
            uint block = BitConverter.ToUInt32(head, 4);
            if (block < 128 || block > 33554432 || (block & (block - 1)) != 0 || head[8] != 1 ||
                !Bounds(0x8000, block, stream.Length)) return null;
            return ReadAt(stream, 0x8000, 128);
        }
        if (magic == "WBFS")
        {
            int hdShift = head[8], wbfsShift = head[9];
            if (hdShift < 9 || hdShift > 20 || wbfsShift < 15 || wbfsShift > 28 || head[12] != 1) return null;
            long sector = 1L << hdShift, cluster = 1L << wbfsShift;
            // The disc-info header must agree with its first mapped data block.
            byte[] map = ReadAt(stream, sector + 256, 2); int first = (map[0] << 8) | map[1];
            if (first == 0 || !Bounds(first * cluster, 128, stream.Length)) return null;
            byte[] disc = ReadAt(stream, sector, 128), stored = ReadAt(stream, first * cluster, 128);
            for (int i = 0; i < 128; i++) if (disc[i] != stored[i]) return null;
            return disc;
        }
        if (BitConverter.ToUInt32(head, 0) == 0xB10BC001)
        {
            ulong dataLength = BitConverter.ToUInt64(head, 8), discLength = BitConverter.ToUInt64(head, 16);
            uint blockSize = BitConverter.ToUInt32(head, 24), blocks = BitConverter.ToUInt32(head, 28);
            if (blocks == 0 || blocks > MaximumEntries || blockSize < 128 || blockSize > 33554432 ||
                (blockSize & (blockSize - 1)) != 0 || discLength < 0x440 ||
                (discLength + blockSize - 1) / blockSize != blocks) return null;
            long start = 32 + (long)blocks * 12;
            if (dataLength > Int64.MaxValue || !Bounds(start, (long)dataLength, stream.Length)) return null;
            const ulong flag = 0x8000000000000000;
            ulong first = BitConverter.ToUInt64(ReadAt(stream, 32, 8), 0), offset = first & ~flag;
            ulong next = blocks > 1 ? BitConverter.ToUInt64(ReadAt(stream, 40, 8), 0) & ~flag : dataLength;
            if (next <= offset || next > dataLength || next - offset > 33554432) return null;
            byte[] block = ReadAt(stream, start + (long)offset, (int)(next - offset));
            if ((first & flag) != 0) { if (block.Length < 128) return null; Array.Resize(ref block, 128); return block; }
            // GCZ uses zlib. .NET Framework DeflateStream consumes raw DEFLATE.
            if (block.Length < 6 || (block[0] & 15) != 8 || ((block[0] << 8) + block[1]) % 31 != 0 || (block[1] & 32) != 0) return null;
            using (MemoryStream compressed = new MemoryStream(block, 2, block.Length - 6))
            using (DeflateStream inflate = new DeflateStream(compressed, CompressionMode.Decompress))
            {
                byte[] disc = new byte[128]; int done = 0;
                while (done < disc.Length) { int n = inflate.Read(disc, done, disc.Length - done); if (n <= 0) return null; done += n; }
                return disc;
            }
        }
        // ISO, GCM and NKit ISO retain the original disc header at offset zero.
        return head;
    }
    private static uint Crc32(Stream stream, long offset, long length)
    {
        stream.Position = offset; uint crc = 0xFFFFFFFF; byte[] buffer = new byte[8192];
        while (length > 0)
        {
            int got = stream.Read(buffer, 0, (int)Math.Min(length, buffer.Length));
            if (got <= 0) throw new EndOfStreamException();
            for (int i = 0; i < got; i++)
            {
                crc ^= buffer[i];
                for (int bit = 0; bit < 8; bit++) crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
            }
            length -= got;
        }
        return crc ^ 0xFFFFFFFF;
    }
    private static byte[] IsoData(Stream stream, int stride, int skip, long sector, int length)
    {
        if (length < 0 || length > 131072 || sector < 0) throw new InvalidDataException();
        byte[] bytes = new byte[length]; int at = 0;
        while (at < length)
        {
            int count = Math.Min(2048, length - at);
            byte[] part = ReadAt(stream, sector * stride + skip, count);
            Array.Copy(part, 0, bytes, at, count); at += count; sector++;
        }
        return bytes;
    }
    private static bool ReadPsxDisc(Stream stream, Index index)
    {
        int[] strides = { 2352, 2352, 2048 }, skips = { 24, 16, 0 };
        byte[] pvd = null; int stride = 0, skip = 0;
        for (int i = 0; i < strides.Length; i++)
        {
            if (!Bounds(16L * strides[i] + skips[i], 2048, stream.Length)) continue;
            byte[] candidate = ReadAt(stream, 16L * strides[i] + skips[i], 2048);
            if (candidate[0] == 1 && candidate[6] == 1 && Encoding.ASCII.GetString(candidate, 1, 5) == "CD001")
            { pvd = candidate; stride = strides[i]; skip = skips[i]; break; }
        }
        if (pvd == null || pvd[156] < 34) return false;
        uint rootSector = BitConverter.ToUInt32(pvd, 158), rootLength = BitConverter.ToUInt32(pvd, 166);
        if (rootSector < 16 || rootLength == 0 || rootLength > 131072) return false;
        byte[] directory = IsoData(stream, stride, skip, rootSector, (int)rootLength);
        for (int at = 0; at < directory.Length;)
        {
            int size = directory[at];
            if (size == 0) { at = (at / 2048 + 1) * 2048; continue; }
            if (size < 34 || !Bounds(at, size, directory.Length) || directory[at + 32] > size - 33) return false;
            string name = Encoding.ASCII.GetString(directory, at + 33, directory[at + 32]);
            uint sector = BitConverter.ToUInt32(directory, at + 2), length = BitConverter.ToUInt32(directory, at + 10);
            bool folder = (directory[at + 25] & 2) != 0;
            if (!folder && length > 0 && name != "\0" && name != "\x01")
            {
                name = name.Split(';')[0].TrimEnd('.');
                long physicalStart = (long)sector * stride + skip;
                long finalSector = sector + ((long)length - 1) / 2048;
                long finalBytes = ((long)length - 1) % 2048 + 1;
                if (!SafeName(name) || !Bounds(finalSector * stride + skip, finalBytes, stream.Length)) return false;
                Add(index, new Entry { Name = "file/" + name, Offset = physicalStart, Length = length });
            }
            at += size;
        }
        return index.Entries.Count > 0;
    }
    private sealed class WudLayout { public long Length; public int Sector; public long Data; }
    private static WudLayout WudStructure(Stream stream)
    {
        if (stream.Length < 32) return null;
        byte[] header = ReadAt(stream, 0, 32);
        if (Encoding.ASCII.GetString(header, 0, 4) != "WUX0") return new WudLayout { Length = stream.Length };
        if (BitConverter.ToUInt32(header, 4) != 0x1099D02E) return null;
        uint sector = BitConverter.ToUInt32(header, 8); ulong length = BitConverter.ToUInt64(header, 16);
        if (sector < 256 || sector > 16777216 || (sector & (sector - 1)) != 0 || length < 131072 || length > 0x1000000000000) return null;
        ulong entries = (length + sector - 1) / sector;
        // Read directory metadata in chunks, never allocate from an unchecked
        // virtual-disc size or expand the user's encrypted game data.
        if (entries > 8388608 || !Bounds(32, (long)entries * 4, stream.Length)) return null;
        long data = ((32 + (long)entries * 4 + sector - 1) / sector) * sector;
        if (data >= stream.Length) return null;
        for (long at = 0; at < (long)entries; at += 2048)
        {
            int count = (int)Math.Min(2048, (long)entries - at);
            byte[] part = ReadAt(stream, 32 + at * 4, count * 4);
            for (int i = 0; i < count; i++)
            {
                uint physical = BitConverter.ToUInt32(part, i * 4);
                if (!Bounds(data + (long)physical * sector, sector, stream.Length)) return null;
            }
        }
        return new WudLayout { Length = (long)length, Sector = (int)sector, Data = data };
    }
    private static byte[] WudData(Stream stream, WudLayout layout, long offset, int count)
    {
        if (!Bounds(offset, count, layout.Length)) throw new InvalidDataException();
        if (layout.Sector == 0) return ReadAt(stream, offset, count);
        byte[] result = new byte[count]; int done = 0;
        while (done < count)
        {
            long logical = offset / layout.Sector; int within = (int)(offset % layout.Sector);
            uint physical = BitConverter.ToUInt32(ReadAt(stream, 32 + logical * 4, 4), 0);
            int n = Math.Min(count - done, layout.Sector - within);
            Array.Copy(ReadAt(stream, layout.Data + (long)physical * layout.Sector + within, n), 0, result, done, n);
            done += n; offset += n;
        }
        return result;
    }
    private static bool SafeName(string name)
    {
        if (String.IsNullOrEmpty(name) || name.Length > 1024 || name.StartsWith("/") || name.IndexOf(':') >= 0) return false;
        foreach (string part in name.Split('/')) if (part == "..") return false;
        return true;
    }
    private static string PakMemberName(string name)
    {
        if (String.IsNullOrEmpty(name) || name.StartsWith("/") || name.IndexOf(':') >= 0) throw new InvalidDataException();
        List<string> parts = new List<string>();
        foreach (string part in name.Split('/'))
        {
            if (part == "" || part == ".") continue;
            if (part == "..")
            {
                if (parts.Count == 0) throw new InvalidDataException();
                parts.RemoveAt(parts.Count - 1);
            }
            else parts.Add(part);
        }
        return String.Join("/", parts.ToArray());
    }
    private static void Add(Index index, Entry entry)
    {
        if (!SafeName(entry.Name)) throw new InvalidDataException();
        if (entry.Length > 0) index.Entries[entry.Name] = entry;
    }
    private static bool ZipMembersReadable(Index index, string[] required)
    {
        foreach (string group in required ?? new string[0])
        {
            bool found = false;
            foreach (string name in group.Split('|'))
            {
                bool readable;
                if (index.ReadableZipMembers.TryGetValue(name.Replace('\\', '/'), out readable) && readable) { found = true; break; }
            }
            if (!found) return false;
        }
        return true;
    }
    private static void ReadZipMembers(Index index, ZipArchive zip, string[] required)
    {
        foreach (string group in required ?? new string[0])
        {
            foreach (string name in group.Split('|'))
            {
                string key = name.Replace('\\', '/');
                Entry indexed;
                if (!index.Entries.TryGetValue(key, out indexed)) continue;
                bool readable;
                if (!index.ReadableZipMembers.TryGetValue(key, out readable))
                {
                    readable = false;
                    try
                    {
                        ZipArchiveEntry entry = zip.GetEntry(indexed.RawName);
                        if (entry != null) using (Stream member = entry.Open()) { readable = member.ReadByte() >= 0; }
                    }
                    catch { readable = false; }
                    index.ReadableZipMembers[key] = readable;
                }
                if (readable) break;
            }
        }
    }
    private static Index Read(string path, string format, string[] required)
    {
        string key = Path.GetFullPath(path) + "|" + format;
        int gate = (StringComparer.OrdinalIgnoreCase.GetHashCode(key) & Int32.MaxValue) % ReadGates.Length;
        lock (ReadGates[gate]) { return ReadCore(path, format, required); }
    }
    private static Index ReadCore(string path, string format, string[] required)
    {
        FileInfo before = new FileInfo(path);
        if (!before.Exists || before.Length == 0) return null;
        string key = Path.GetFullPath(path) + "|" + format;
        Cached saved;
        lock (CacheSync)
        {
            if (Cache.TryGetValue(key, out saved) && saved.Length == before.Length && saved.Write == before.LastWriteTimeUtc.Ticks) return saved.Index;
        }
        Index index = new Index();
        using (FileStream stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
        using (BinaryReader reader = new BinaryReader(stream, Encoding.ASCII))
        {
            long total = stream.Length;
            if (format == "WIIU_DISC")
            {
                // Cemu's public HeaderA product and independent HeaderB
                // volume structure. Neither a filename nor the emulator is
                // evidence. No key file or encrypted partition is accessed.
                WudLayout layout = WudStructure(stream);
                if (layout == null || layout.Length < 131072) return null;
                string product = Encoding.ASCII.GetString(WudData(stream, layout, 0, 22));
                if (!System.Text.RegularExpressions.Regex.IsMatch(product, "^WUP-P-[A-Z0-9]{4}-[0-9]{2}-[0-9]{3}[A-Z]{3}-[0-9]$")) return null;
                if (Big32(WudData(stream, layout, 0x10000, 4), 0) != 0xCC549EB9) return null;
                Add(index, new Entry { Name = "product/" + product.Substring(0, 10), Offset = 0, Length = 22 });
                Add(index, new Entry { Name = "volume/WIIU-DISC", Offset = 0x10000, Length = 4 });
            }
            else if (format == "PSX_DISC")
            {
                if (!ReadPsxDisc(stream, index)) return null;
            }
            else if (format == "MPQ")
            {
                // MPQ's standard encrypted directory tables, documented by
                // StormLib. No filename list, historical hash or native DLL
                // is needed to identify two known original game resources.
                if (total < 32) return null;
                long origin = 0; byte[] header = ReadAt(stream, 0, 32);
                if (Encoding.ASCII.GetString(header, 0, 4) == "MPQ\x1B")
                { origin = BitConverter.ToUInt32(header, 8); if (origin > 1048576) return null; header = ReadAt(stream, origin, 32); }
                if (Encoding.ASCII.GetString(header, 0, 4) != "MPQ\x1A") return null;
                uint headerLength = BitConverter.ToUInt32(header, 4), archiveLength = BitConverter.ToUInt32(header, 8);
                ushort version = BitConverter.ToUInt16(header, 12);
                if (version > 1 || headerLength < 32 || !Bounds(origin, archiveLength, total) || archiveLength < headerLength) return null;
                if (version == 1)
                { byte[] extra = ReadAt(stream, origin + 32, 12); if (BitConverter.ToUInt16(extra, 8) != 0 || BitConverter.ToUInt16(extra, 10) != 0) return null; }
                uint hashOffset = BitConverter.ToUInt32(header, 16), blockOffset = BitConverter.ToUInt32(header, 20);
                uint hashes = BitConverter.ToUInt32(header, 24), blocks = BitConverter.ToUInt32(header, 28);
                if (hashes == 0 || hashes > MaximumEntries || blocks == 0 || blocks > MaximumEntries ||
                    hashOffset < headerLength || blockOffset < headerLength ||
                    !Bounds(hashOffset, (long)hashes * 16, archiveLength) || !Bounds(blockOffset, (long)blocks * 16, archiveLength)) return null;
                byte[] hashTable = MpqDecrypt(ReadAt(stream, origin + hashOffset, (int)hashes * 16), 0xC3AF3770);
                byte[] blockTable = MpqDecrypt(ReadAt(stream, origin + blockOffset, (int)blocks * 16), 0xEC83B3A3);
                index.Mpq = true;
                for (int i = 0; i < hashes; i++)
                {
                    int at = i * 16; uint blockId = BitConverter.ToUInt32(hashTable, at + 12);
                    if (blockId == UInt32.MaxValue || blockId == UInt32.MaxValue - 1) continue;
                    if (blockId >= blocks) return null;
                    int b = (int)blockId * 16; uint offset = BitConverter.ToUInt32(blockTable, b), packed = BitConverter.ToUInt32(blockTable, b + 4);
                    uint length = BitConverter.ToUInt32(blockTable, b + 8), flags = BitConverter.ToUInt32(blockTable, b + 12);
                    if ((flags & 0x80000000) == 0 || (flags & 0x02000000) != 0 || length == 0) continue;
                    if (packed == 0 || offset < headerLength || !Bounds(offset, packed, archiveLength)) return null;
                    Add(index, new Entry { Name = MpqName(BitConverter.ToUInt32(hashTable, at), BitConverter.ToUInt32(hashTable, at + 4)), Offset = origin + offset, Length = length });
                }
            }
            else if (format == "DRAMATIC_PINBALL")
            {
                // Publisher-generated original ROM plus the two colour
                // layers for each board. The metadata SHA text is syntax,
                // never compared with a historical release/ROM allowlist.
                const int rom = 1048576, board = 16512;
                if (total != 47 + rom + 4 * board) return null;
                byte[] header = ReadAt(stream, 0, 47);
                if (Encoding.ASCII.GetString(header, 0, 7) != "DSPIN1\n" ||
                    !System.Text.RegularExpressions.Regex.IsMatch(Encoding.ASCII.GetString(header, 7, 40), "^[0-9a-fA-F]{40}$")) return null;
                Add(index, new Entry { Name = "original-rom", Offset = 47, Length = rom });
                Add(index, new Entry { Name = "red-board", Offset = 47 + rom, Length = 2 * board });
                Add(index, new Entry { Name = "blue-board", Offset = 47 + rom + 2 * board, Length = 2 * board });
            }
            else if (format == "STARFOX_BUNDLE")
            {
                // The author stores original ROM, original symbols, EX ROM,
                // EX symbols in this locally generated asset container.
                // Accept every manifest/version; its own CRCs only validate
                // the current container, never a historical download identity.
                if (total < 48 || total > 67108864) return null;
                byte[] header = ReadAt(stream, 0, 44);
                if (Encoding.ASCII.GetString(header, 0, 8) != "SFOXAS01") return null;
                long end = 44; uint[] sizes = new uint[4];
                for (int i = 0; i < 4; i++) { sizes[i] = BitConverter.ToUInt32(header, 12 + i * 4); if (!Bounds(end, sizes[i], total - 4)) return null; end += sizes[i]; }
                if (end != total - 4 || sizes[0] < 0x8000 || sizes[2] < 0x8000 || sizes[1] == 0 || sizes[3] == 0) return null;
                if (Crc32(stream, 0, end) != BitConverter.ToUInt32(ReadAt(stream, end, 4), 0)) return null;
                string[] names = { "original-rom", "original-symbols", "starfox-ex-rom", "starfox-ex-symbols" };
                long at = 44;
                for (int i = 0; i < 4; i++)
                {
                    if (Crc32(stream, at, sizes[i]) != BitConverter.ToUInt32(header, 28 + i * 4)) return null;
                    Add(index, new Entry { Name = names[i], Offset = at, Length = sizes[i] }); at += sizes[i];
                }
            }
            else if (format == "NINTENDO_DISC")
            {
                byte[] header = DiscHeader(stream); if (header == null) return null;
                if (Big32(header, 24) != 0x5D1C9EA3 && Big32(header, 28) != 0xC2339F3D) return null;
                string id = Encoding.ASCII.GetString(header, 0, 6);
                string title = Name(header, 32, 96).Trim();
                if (!System.Text.RegularExpressions.Regex.IsMatch(id, "^[A-Z0-9]{6}$") || String.IsNullOrEmpty(title)) return null;
                Add(index, new Entry { Name = "disc/" + id, Offset = 0, Length = 6 });
                Add(index, new Entry { Name = "title/" + title, Offset = 32, Length = 96 });
                Add(index, new Entry { Name = Big32(header, 28) == 0xC2339F3D ? "system/gamecube" : "system/wii", Offset = 24, Length = 8 });
            }
            else if (format == "N64")
            {
                // Identify the original cartridge without hashes, execution or
                // treating a renamed port/ROM file as sufficient evidence.
                // 0x1000 is the format's header+IPL boundary, not a release size.
                if (total <= 0x1000) return null;
                byte[] header = reader.ReadBytes(64);
                if (header.Length != 64) return null;
                if (header[0] == 0x37 && header[1] == 0x80 && header[2] == 0x40 && header[3] == 0x12)
                    for (int i = 0; i < 64; i += 2) { byte b = header[i]; header[i] = header[i + 1]; header[i + 1] = b; }
                else if (header[0] == 0x40 && header[1] == 0x12 && header[2] == 0x37 && header[3] == 0x80)
                    for (int i = 0; i < 64; i += 4) { Array.Reverse(header, i, 4); }
                if (header[0] != 0x80 || header[1] != 0x37 || header[2] != 0x12 || header[3] != 0x40) return null;
                string title = Encoding.ASCII.GetString(header, 32, 20).Trim(' ', '\0');
                string cartridge = Encoding.ASCII.GetString(header, 59, 4);
                if (String.IsNullOrEmpty(title) || !System.Text.RegularExpressions.Regex.IsMatch(cartridge, "^[A-Z0-9]{4}$")) return null;
                Add(index, new Entry { Name = "title/" + title, Offset = 32, Length = 20 });
                Add(index, new Entry { Name = "cartridge/" + cartridge, Offset = 59, Length = 4 });
            }
            else if (format == "WAD")
            {
                if (total < 12) return null;
                string magic = Encoding.ASCII.GetString(reader.ReadBytes(4));
                if (magic != "IWAD" && magic != "PWAD") return null;
                int count = reader.ReadInt32(); long offset = reader.ReadInt32();
                if (count <= 0 || count > MaximumEntries || offset < 12 || !Bounds(offset, (long)count * 16, total)) return null;
                stream.Position = offset; byte[] directory = reader.ReadBytes(count * 16);
                if (directory.Length != count * 16) return null;
                List<Entry> ordered = new List<Entry>();
                for (int i = 0; i < count; i++)
                {
                    int at = i * 16;
                    Entry e = new Entry { Name = Name(directory, at + 8, 8), Offset = BitConverter.ToInt32(directory, at), Length = BitConverter.ToInt32(directory, at + 4) };
                    if (!Bounds(e.Offset, e.Length, total)) return null;
                    if (!String.IsNullOrEmpty(e.Name)) { ordered.Add(e); Add(index, e); }
                }
                for (int i = 0; i < ordered.Count; i++)
                {
                    string map = ordered[i].Name;
                    if (!System.Text.RegularExpressions.Regex.IsMatch(map, "^(E[0-9]M[0-9]|MAP[0-9][0-9])$", System.Text.RegularExpressions.RegexOptions.IgnoreCase)) continue;
                    Dictionary<string, long> geometry = new Dictionary<string, long>(StringComparer.OrdinalIgnoreCase);
                    bool hexen = false;
                    for (int j = i + 1; j < ordered.Count && j <= i + 12; j++)
                    {
                        Entry e = ordered[j];
                        if (System.Text.RegularExpressions.Regex.IsMatch(e.Name, "^(E[0-9]M[0-9]|MAP[0-9][0-9])$", System.Text.RegularExpressions.RegexOptions.IgnoreCase)) break;
                        geometry[e.Name] = e.Length;
                        if (e.Name.Equals("BEHAVIOR", StringComparison.OrdinalIgnoreCase)) hexen = true;
                    }
                    long things, lines, sides, vertices, sectors;
                    if (geometry.TryGetValue("THINGS", out things) && geometry.TryGetValue("LINEDEFS", out lines) &&
                        geometry.TryGetValue("SIDEDEFS", out sides) && geometry.TryGetValue("VERTEXES", out vertices) &&
                        geometry.TryGetValue("SECTORS", out sectors) && things > 0 && things % (hexen ? 20 : 10) == 0 &&
                        lines >= 3 * (hexen ? 16 : 14) && lines % (hexen ? 16 : 14) == 0 &&
                        sides >= 30 && sides % 30 == 0 && vertices >= 12 && vertices % 4 == 0 && sectors >= 26 && sectors % 26 == 0)
                        index.Maps.Add(map);
                }
            }
            else if (format == "GRP")
            {
                if (total < 16 || Encoding.ASCII.GetString(reader.ReadBytes(12)) != "KenSilverman") return null;
                int count = reader.ReadInt32();
                if (count <= 0 || count > MaximumEntries || !Bounds(16, (long)count * 16, total)) return null;
                byte[] directory = reader.ReadBytes(count * 16); long offset = 16 + (long)count * 16;
                if (directory.Length != count * 16) return null;
                for (int i = 0; i < count; i++)
                {
                    long length = BitConverter.ToUInt32(directory, i * 16 + 12);
                    if (!Bounds(offset, length, total)) return null;
                    Add(index, new Entry { Name = Name(directory, i * 16, 12), Offset = offset, Length = length });
                    offset += length;
                }
            }
            else if (format == "PAK")
            {
                if (total < 12 || Encoding.ASCII.GetString(reader.ReadBytes(4)) != "PACK") return null;
                long offset = reader.ReadInt32(); int length = reader.ReadInt32();
                if (length <= 0 || length % 64 != 0 || length / 64 > MaximumEntries || !Bounds(offset, length, total)) return null;
                stream.Position = offset; byte[] directory = reader.ReadBytes(length);
                if (directory.Length != length) return null;
                for (int i = 0; i < length; i += 64)
                {
                    // Original Quake II uses e.g. tank/../ctank texture aliases.
                    // Resolve only inside this read-only archive, never on disk.
                    Entry e = new Entry { Name = PakMemberName(Name(directory, i, 56)), Offset = BitConverter.ToInt32(directory, i + 56), Length = BitConverter.ToInt32(directory, i + 60) };
                    if (!Bounds(e.Offset, e.Length, total)) return null;
                    Add(index, e);
                }
            }
            else if (format == "ZIP")
            {
                using (Stream region = ZipRegion(stream))
                using (ZipArchive zip = new ZipArchive(region, ZipArchiveMode.Read, true))
                {
                    if (zip.Entries.Count == 0 || zip.Entries.Count > MaximumEntries) return null;
                    foreach (ZipArchiveEntry entry in zip.Entries)
                    {
                        string name = entry.FullName.Replace('\\', '/');
                        if (name.EndsWith("/")) continue;
                        if (entry.Length > 0 && entry.CompressedLength == 0) return null;
                        Add(index, new Entry { Name = name, RawName = entry.FullName, Length = entry.Length });
                    }
                    // The archive is already open and indexed. Check the exact
                    // requested members here instead of opening and indexing
                    // a second copy of a large OTR/O2R/IPK3 for every caller.
                    ReadZipMembers(index, zip, required);
                }
            }
            else return null;
        }
        FileInfo after = new FileInfo(path);
        if (!after.Exists || after.Length != before.Length || after.LastWriteTimeUtc != before.LastWriteTimeUtc) return null;
        lock (CacheSync)
        {
            int totalEntries = index.Entries.Count;
            foreach (Cached c in Cache.Values) totalEntries += c.Index.Entries.Count;
            if (Cache.Count >= 32 || totalEntries > 500000) Cache.Clear();
            Cache[key] = new Cached { Length = after.Length, Write = after.LastWriteTimeUtc.Ticks, Index = index };
        }
        return index;
    }
    public static bool Test(string path, string format, string[] required, string[] excluded, string[] maps)
    {
        try
        {
            FileInfo before = new FileInfo(path);
            if (!before.Exists || before.Length == 0) return false;
            StringBuilder key = new StringBuilder(Path.GetFullPath(path));
            foreach (string[] group in new string[][] { new string[] { format }, required, excluded, maps })
            {
                key.Append('|');
                foreach (string value in group ?? new string[0]) { key.Append(value.Length).Append(':').Append(value); }
            }
            string proofKey = key.ToString();
            CompletedProof saved;
            lock (CacheSync)
            {
                if (Completed.TryGetValue(proofKey, out saved) && saved.Length == before.Length && saved.Write == before.LastWriteTimeUtc.Ticks) return true;
            }
            // Keep the completed, exact content proof independently of the
            // much larger directory index. The latter has a strict memory
            // bound and may be evicted while other games are inspected.
            if (!TestCore(path, format, required, excluded, maps)) return false;
            FileInfo after = new FileInfo(path);
            if (!after.Exists || after.Length != before.Length || after.LastWriteTimeUtc != before.LastWriteTimeUtc) return false;
            lock (CacheSync)
            {
                if (Completed.Count >= 512) Completed.Clear();
                Completed[proofKey] = new CompletedProof { Length = after.Length, Write = after.LastWriteTimeUtc.Ticks };
            }
            return true;
        }
        catch { return false; }
    }
    private static bool TestCore(string path, string format, string[] required, string[] excluded, string[] maps)
    {
        try
        {
            Index index = Read(path, format, required);
            if (index == null) return false;
            lock (index)
            {
            foreach (string name in excluded ?? new string[0]) if (ContainsEntry(index, name)) return false;
            foreach (string group in required ?? new string[0])
            {
                bool found = false;
                foreach (string name in group.Split('|')) if (ContainsEntry(index, name)) { found = true; break; }
                if (!found) return false;
            }
            foreach (string name in maps ?? new string[0]) if (!index.Maps.Contains(name)) return false;
            // Verify selected ZIP members can actually be opened, including fused LÖVE executables.
            if (format == "ZIP" && !ZipMembersReadable(index, required))
            {
                using (FileStream stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                using (Stream region = ZipRegion(stream))
                using (ZipArchive zip = new ZipArchive(region, ZipArchiveMode.Read))
                {
                    ReadZipMembers(index, zip, required);
                    if (!ZipMembersReadable(index, required)) return false;
                }
            }
            return true;
            }
        }
        catch { return false; }
    }
}
