# Builds UDamagePickup.wav, UDamageRewardV2's UDamage pickup sound: an
# original take on the stock one's shape (made from scratch here, no stock
# audio data), as loud but without its hard clipping.
#   - a 58 Hz bass hum, gliding up from 54 Hz as it swells in, in two humps
#     with a dip between; driven into soft (tanh) saturation, which rounds the
#     peaks off instead of flattening them, for the same buzz and loudness
#   - a metallic shimmer of fixed bell-like partials (912 Hz to 3.7 kHz),
#     brightness sweeping low-high-low across them, ringing out to ~1.4 s
#   - a final soft limiter and normalising to a 0.95 peak
# Also writes UDamagePickupRev.wav, the same played backwards.
# 44.1 kHz, 16-bit mono. Rebuild UDamageRewardV2 after.
#   powershell -File MakeUDamagePickup.ps1

Add-Type -TypeDefinition @"
using System;
using System.IO;

public static class UDamagePickupSynth
{
    const int SR = 44100;

    // value at t from keyframes (times, values), smoothstepped between them
    static double Key(double[] ts, double[] vs, double t)
    {
        if (t <= ts[0]) return vs[0];
        for (int i = 1; i < ts.Length; i++)
            if (t < ts[i])
            {
                double u = (t - ts[i - 1]) / (ts[i] - ts[i - 1]);
                u = u * u * (3 - 2 * u);
                return vs[i - 1] + (vs[i] - vs[i - 1]) * u;
            }
        return vs[vs.Length - 1];
    }

    static void WriteWav(string path, short[] data)
    {
        int n = data.Length;
        using (var bw = new BinaryWriter(File.Create(path)))
        {
            bw.Write(new char[] { 'R', 'I', 'F', 'F' }); bw.Write(36 + n * 2);
            bw.Write(new char[] { 'W', 'A', 'V', 'E', 'f', 'm', 't', ' ' }); bw.Write(16);
            bw.Write((short)1); bw.Write((short)1); bw.Write(SR); bw.Write(SR * 2);
            bw.Write((short)2); bw.Write((short)16);
            bw.Write(new char[] { 'd', 'a', 't', 'a' }); bw.Write(n * 2);
            for (int i = 0; i < n; i++)
                bw.Write(data[i]);
        }
    }

    public static string Make(string path, string revPath)
    {
        double dur = 1.5;
        int n = (int)(dur * SR);
        double[] bass = new double[n], shim = new double[n], mix = new double[n];

        // bass: level in two humps, saturated
        double[] bt = { 0, 0.04, 0.10, 0.28, 0.36, 0.44, 0.50, 0.58, 0.66, 0.72, 0.80, 0.90, 1.0 };
        double[] bv = { 0, 0.05, 1.0,  1.0,  0.5,  0.12, 0.45, 0.70, 0.75, 0.45, 0.08, 0.02, 0 };
        double drive = 4.5, ph = 0;
        for (int i = 0; i < n; i++)
        {
            double t = (double)i / SR;
            double f = 54 + 5 * (1 - Math.Exp(-t / 0.05)) - Key(new double[] { 0.2, 0.6 }, new double[] { 0, 1 }, t);
            ph += 2 * Math.PI * f / SR;
            bass[i] = Math.Tanh(drive * Key(bt, bv, t) * Math.Sin(ph)) / Math.Tanh(drive);
        }

        // shimmer: partials weighted by closeness (in octaves) to a moving
        // brightness centre, each with its own slow flutter and a detuned twin
        double[] pf = { 862, 912, 1388, 1653, 1872, 1980, 2345, 2845, 3100, 3686 };
        double[] pa = { 0.5, 1.0, 0.6,  0.35, 0.7,  0.6,  0.6,  0.55, 0.5,  0.45 };
        double[] ct = { 0.20, 0.28, 0.34, 0.40, 0.45, 0.52, 0.60, 0.68, 0.76, 0.90, 1.00, 1.30 };
        double[] cv = { 880,  900,  2300, 3000, 1600, 950,  1950, 2400, 1400, 1100, 1900, 1500 };
        double[] st = { 0, 0.18, 0.26, 0.32, 0.45, 0.58, 0.64 };
        double[] sv = { 0, 0.05, 0.5,  0.8,  0.9,  0.85, 0.55 };
        double peak = 0;
        for (int i = 0; i < n; i++)
        {
            double t = (double)i / SR;
            double c = Key(ct, cv, t);
            double w = Key(new double[] { 0.7, 0.9 }, new double[] { 0.35, 0.8 }, t);
            double lvl = t < 0.64 ? Key(st, sv, t) : 0.55 * Math.Exp(-(t - 0.64) / 0.13);
            if (t > dur - 0.05) lvl *= (dur - t) / 0.05;
            double s = 0;
            for (int k = 0; k < pf.Length; k++)
            {
                double d = Math.Log(pf[k] / c, 2);
                double g = pa[k] * Math.Exp(-d * d / (2 * w * w));
                double flutter = 1 + 0.25 * Math.Sin(2 * Math.PI * (5 + 0.7 * k) * t + k * 1.3);
                s += g * flutter * (Math.Sin(2 * Math.PI * pf[k] * t + k * 0.9) + 0.5 * Math.Sin(2 * Math.PI * pf[k] * 1.003 * t + k * 2.1));
            }
            shim[i] = s * lvl;
            peak = Math.Max(peak, Math.Abs(shim[i]));
        }

        // mix, soft-limit, normalise
        double mpeak = 0;
        for (int i = 0; i < n; i++)
        {
            mix[i] = Math.Tanh(2.0 * (0.75 * bass[i] + 1.1 * shim[i] / peak));
            mpeak = Math.Max(mpeak, Math.Abs(mix[i]));
        }

        short[] data = new short[n];
        for (int i = 0; i < n; i++)
            data[i] = (short)Math.Round(mix[i] / mpeak * 0.95 * 32767);
        WriteWav(path, data);
        Array.Reverse(data);
        WriteWav(revPath, data);
        return "wrote " + path + "\n" + "wrote " + revPath;
    }
}
"@

[UDamagePickupSynth]::Make((Join-Path $PSScriptRoot 'UDamagePickup.wav'), (Join-Path $PSScriptRoot 'UDamagePickupRev.wav'))
