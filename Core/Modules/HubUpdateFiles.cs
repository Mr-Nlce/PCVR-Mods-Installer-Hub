using System;
using System.Collections.Generic;
using System.IO;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;
using Microsoft.Win32.SafeHandles;

public static class HubUpdateFiles
{
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern SafeFileHandle CreateFile(string path, uint access, uint share,
        IntPtr security, uint creation, uint flags, IntPtr template);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern uint GetFinalPathNameByHandle(SafeFileHandle file, StringBuilder path,
        uint length, uint flags);

    public static string ResolveDirectory(string directory)
    {
        const uint shareAll = 7;
        const uint openExisting = 3;
        const uint openDirectory = 0x02000000;
        using (var file = CreateFile(ExtendedPath(Path.GetFullPath(directory)), 0, shareAll, IntPtr.Zero, openExisting, openDirectory, IntPtr.Zero))
        {
            if (file.IsInvalid) throw new Win32Exception(Marshal.GetLastWin32Error());
            var path = new StringBuilder(512);
            var size = GetFinalPathNameByHandle(file, path, (uint)path.Capacity, 0);
            if (size >= path.Capacity)
            {
                path.Capacity = checked((int)size + 1);
                size = GetFinalPathNameByHandle(file, path, (uint)path.Capacity, 0);
            }
            if (size == 0 || size >= path.Capacity) throw new Win32Exception(Marshal.GetLastWin32Error());
            var result = path.ToString();
            if (result.StartsWith(@"\\?\UNC\", StringComparison.OrdinalIgnoreCase))
                return @"\\" + result.Substring(8);
            if (result.StartsWith(@"\\?\", StringComparison.Ordinal))
                return result.Substring(4);
            return result;
        }
    }

    private static string ExtendedPath(string path)
    {
        if (path.StartsWith(@"\\?\", StringComparison.Ordinal)) return path;
        return path.StartsWith(@"\\", StringComparison.Ordinal) ? @"\\?\UNC\" + path.Substring(2) : @"\\?\" + path;
    }

    private static readonly StringComparer Names = StringComparer.OrdinalIgnoreCase;
    private static readonly HashSet<string> PreservedDirectories = new HashSet<string>(Names)
    {
        "UserData", "Logs", "cache", "CustomGames", "Saves", "SaveGames"
    };
    private static readonly HashSet<string> PreservedFiles = new HashSet<string>(Names)
    {
        "version.txt", ".shortcut_created", ".update_available", ".hub-settings.json",
        "HubStateBackup.json", "HubStateFallback.json", "RustWindow.json", ".vrv_source"
    };

    private sealed class Replacement
    {
        public string Source;
        public string Target;
        public bool TargetExists;
        public string Saved;
        public bool Replaced;
    }

    public static void Apply(string source, string destination, string version)
    {
        source = Path.GetFullPath(source);
        destination = Path.GetFullPath(destination);
        var sameVolume = Names.Equals(Path.GetPathRoot(source), Path.GetPathRoot(destination));
        source = ExtendedPath(source);
        destination = ExtendedPath(destination);
        var plan = new List<Replacement>();
        PlanDirectory(source, destination, plan);
        var versionPath = Path.Combine(destination, "Core", "version.txt");
        var versionSource = Path.Combine(source, "Core", "version.txt");
        File.WriteAllText(versionSource, version, new UTF8Encoding(false));
        plan.Add(new Replacement { Source = versionSource, Target = versionPath, TargetExists = CheckTarget(versionPath) });

        // Keep only files being replaced, by renaming them on the install volume.
        var recovery = Path.Combine(destination, ".pcvr-update-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(recovery);
        var incoming = Path.Combine(recovery, "incoming");
        var created = new List<string>();
        var next = 0;
        var keepRecovery = false;
        try
        {
            EnsureDirectory(Path.Combine(destination, "Core", "UserData"), created);
            foreach (var entry in plan)
            {
                EnsureDirectory(Path.GetDirectoryName(entry.Target), created);
                if (!sameVolume) File.Copy(entry.Source, incoming, false);
                if (entry.TargetExists)
                {
                    var saved = Path.Combine(recovery, (next++).ToString());
                    File.Move(entry.Target, saved);
                    entry.Saved = saved;
                }
                File.Move(sameVolume ? entry.Source : incoming, entry.Target);
                entry.Replaced = true;
            }
        }
        catch (Exception error)
        {
            var rollbackErrors = new List<string>();
            for (var i = plan.Count - 1; i >= 0; i--)
            {
                var entry = plan[i];
                try
                {
                    if (entry.Replaced && File.Exists(entry.Target)) File.Delete(entry.Target);
                    if (entry.Saved != null) File.Move(entry.Saved, entry.Target);
                }
                catch (Exception rollbackError)
                {
                    rollbackErrors.Add(entry.Target + ": " + rollbackError.Message);
                }
            }
            for (var i = created.Count - 1; i >= 0; i--)
            {
                try { Directory.Delete(created[i]); }
                catch (IOException) { }
                catch (UnauthorizedAccessException) { }
            }
            keepRecovery = rollbackErrors.Count > 0;
            if (keepRecovery)
            {
                try
                {
                    using (var report = File.CreateText(Path.Combine(recovery, "restore.tsv")))
                    {
                        foreach (var entry in plan)
                        {
                            if (entry.Saved != null && File.Exists(entry.Saved))
                                report.WriteLine(entry.Saved + "\t" + entry.Target);
                        }
                    }
                }
                catch (IOException) { }
                catch (UnauthorizedAccessException) { }
                throw new IOException("The update could not restore every file. Recovery folder: " + recovery
                    + Environment.NewLine + String.Join(Environment.NewLine, rollbackErrors), error);
            }
            throw new IOException("The update could not replace a program file. The previous installation was restored. "
                + error.Message, error);
        }
        finally
        {
            if (!keepRecovery)
            {
                try { Directory.Delete(recovery, true); }
                catch (IOException) { }
                catch (UnauthorizedAccessException) { }
            }
        }
    }

    private static void PlanDirectory(string source, string destination, List<Replacement> plan)
    {
        var attributes = Attributes(destination);
        if (attributes.HasValue && ((attributes.Value & FileAttributes.ReparsePoint) != 0 ||
            (attributes.Value & FileAttributes.Directory) == 0))
            throw new IOException("The update cannot write to this folder: " + destination);
        foreach (var file in Directory.EnumerateFiles(source))
        {
            var name = Path.GetFileName(file);
            if (PreservedFiles.Contains(name) || name.StartsWith(".installed_", StringComparison.OrdinalIgnoreCase) ||
                name.StartsWith(".launch_exe", StringComparison.OrdinalIgnoreCase)) continue;
            var target = Path.Combine(destination, name);
            plan.Add(new Replacement { Source = file, Target = target, TargetExists = CheckTarget(target) });
        }
        foreach (var directory in Directory.EnumerateDirectories(source))
        {
            var name = Path.GetFileName(directory);
            if (!PreservedDirectories.Contains(name))
                PlanDirectory(directory, Path.Combine(destination, name), plan);
        }
    }

    private static bool CheckTarget(string target)
    {
        var attributes = Attributes(target);
        if (attributes.HasValue &&
            (attributes.Value & (FileAttributes.ReparsePoint | FileAttributes.Directory | FileAttributes.ReadOnly)) != 0)
            throw new IOException("The update cannot replace this program file: " + target);
        return attributes.HasValue;
    }

    private static FileAttributes? Attributes(string path)
    {
        try { return File.GetAttributes(path); }
        catch (FileNotFoundException) { return null; }
        catch (DirectoryNotFoundException) { return null; }
    }

    private static void EnsureDirectory(string path, List<string> created)
    {
        if (Directory.Exists(path)) return;
        EnsureDirectory(Path.GetDirectoryName(path), created);
        Directory.CreateDirectory(path);
        created.Add(path);
    }
}
