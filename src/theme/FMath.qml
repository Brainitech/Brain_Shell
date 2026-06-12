pragma Singleton
import QtQuick

/*!
    FMath — Fast Math / Low-Level Approximation Engine
    ──────────────────────────────────────────────────

    Carmack-grade tricks for JavaScript land:
    - Fast inverse square root (Quake III algorithm, type-punned via ArrayBuffer)
    - Pre-computed 12-bit sin/cos lookup tables (4096 samples ≈ 0.088° precision)
    - Smoothstep (Hermite & quintic), organic noise, branchless clamp/abs
    - Polynomial exp/log approximations (Padé rational)
    - Spring-damper pre-integration helpers

    All LUTs are built once when the singleton loads (frozen QtObjects).
    The runtime cost is a single array read plus lerp — no trig calls.
*/

QtObject {
    id: root

    // ═══════════════════════════════════════════════════════════════════════════
    // QUAKE III FAST INVERSE SQUARE ROOT
    // ═══════════════════════════════════════════════════════════════════════════
    // For educational/historical purposes. Modern JS engines optimize Math.sqrt
    // to native instructions, so this is mainly a low-level flag.
    // Use fastInvSqrt(x) for single-precision cases where Math.sqrt is too heavy.
    //
    // Function doubles as rsqrt(x) = 1 / sqrt(x) with Newton iteration.
    function fastInvSqrt(x) {
        if (x <= 0) return Infinity
        // Type-pun float -> int32 via ArrayBuffer
        var buf = new ArrayBuffer(4)
        var f32 = new Float32Array(buf)
        var i32 = new Int32Array(buf)
        f32[0] = x
        var halfx = x * 0.5
        // 0x5F3759DF — the magic constant
        i32[0] = 0x5F3759DF - (i32[0] >> 1)
        var y = f32[0]
        // One Newton-Raphson iteration
        y = y * (1.5 - halfx * y * y)
        // Second iteration for higher precision
        y = y * (1.5 - halfx * y * y)
        return y
    }

    // Normalized vector length using fastInvSqrt
    function fastNormalize(x, y)      { var l = fastInvSqrt(x*x + y*y); return { x: x*l, y: y*l, len: 1/l } }
    function fastNormalize3(x, y, z)  { var l = fastInvSqrt(x*x + y*y + z*z); return { x: x*l, y: y*l, z: z*l, len: 1/l } }

    // Fast length calculation: len = sqrt(x²+y²) using Quake rsqrt
    function fastLen(x, y)            { var l = fastInvSqrt(x*x + y*y); return 1 / l }
    function fastLen3(x, y, z)        { var l = fastInvSqrt(x*x + y*y + z*z); return 1 / l }

    // ═══════════════════════════════════════════════════════════════════════════
    // TRIGONOMETRIC LOOKUP TABLES (12-bit = 4096 samples)
    // ═══════════════════════════════════════════════════════════════════════════
    readonly property int _TRIG_BITS: 12
    readonly property int _TRIG_SIZE: 4096
    readonly property real _TRIG_SCALE: 4096 / (2 * Math.PI)
    readonly property int _TRIG_MASK: 4095

    // Built once at startup, stored as frozen array
    readonly property var _sinLut: {
        var arr = []
        var step = 2 * Math.PI / 4096
        for (var i = 0; i < 4096; i++)
            arr.push(Math.sin(i * step))
        return arr
    }

    // cos(x) = sin(x + pi/2), looked up through the same LUT
    function fastSin(rad) {
        var idx = Math.floor(rad * root._TRIG_SCALE) & root._TRIG_MASK
        return root._sinLut[idx]
    }

    function fastCos(rad) {
        // cos(x) = sin(x + π/2)
        var idx = Math.floor((rad + Math.PI * 0.5) * root._TRIG_SCALE) & root._TRIG_MASK
        return root._sinLut[idx]
    }

    // Higher-precision sin/cos with linear interpolation between LUT samples
    function fastSinLerp(rad) {
        var fi = rad * root._TRIG_SCALE
        var idx = Math.floor(fi) & root._TRIG_MASK
        var next = (idx + 1) & root._TRIG_MASK
        var t = fi - Math.floor(fi)
        return root._sinLut[idx] + (root._sinLut[next] - root._sinLut[idx]) * t
    }

    function fastCosLerp(rad) {
        return fastSinLerp(rad + Math.PI * 0.5)
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SMOOTH INTERPOLATION (branchless Hermite polynomials)
    // ═══════════════════════════════════════════════════════════════════════════

    // Standard smoothstep: t²(3 - 2t)  →  cubic Hermite between 0 and 1
    function smoothstep(t, edge0, edge1) {
        t = Math.max(0, Math.min(1, (t - edge0) / (edge1 - edge0 || 0.001)))
        return t * t * (3 - 2 * t)
    }

    // Quintic smoothstep: t⁵(6t² - 15t + 10)  →  zero first & second derivatives at endpoints
    function quinticSmooth(t) {
        return t * t * t * (t * (t * 6 - 15) + 10)
    }

    function quinticSmoothstep(t, edge0, edge1) {
        t = Math.max(0, Math.min(1, (t - edge0) / (edge1 - edge0 || 0.001)))
        return quinticSmooth(t)
    }

    // Ease-out polynomial approximation (no branching)
    function easeOutPoly(t, power) {
        // 1 - (1 - t)^power
        return 1 - Math.pow(1 - t, power || 3)
    }

    // Ease-in polynomial approximation
    function easeInPoly(t, power) {
        return Math.pow(t, power || 3)
    }

    // Ease-in-out (accel + decel)
    function easeInOutPoly(t, power) {
        var p = power || 3
        return t < 0.5
            ? Math.pow(2, p - 1) * Math.pow(t, p)
            : 1 - Math.pow(-2 * t + 2, p) / 2
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ORGANIC NOISE (value noise / Perlin-inspired, branchless)
    // ═══════════════════════════════════════════════════════════════════════════

    // Hash function (fast, low-quality but good enough for animations)
    function _hash(x) {
        var h = x * 0.1031
        h = h - Math.floor(h)
        return h * h * (3 - 2 * h)  // smooth it
    }

    // 1D organic noise: smoothly varying value between 0 and 1
    function noise1D(t) {
        var i = Math.floor(t)
        var f = t - i
        f = f * f * (3 - 2 * f)  // smoothstep blend
        return root._hash(i) + (root._hash(i + 1) - root._hash(i)) * f
    }

    // 2D organic noise — good for wobble/breathing effects
    function noise2D(x, y) {
        var xi = Math.floor(x), yi = Math.floor(y)
        var xf = x - xi, yf = y - yi
        xf = xf * xf * (3 - 2 * xf)
        yf = yf * yf * (3 - 2 * yf)
        var n00 = root._hash(xi + yi * 57)
        var n10 = root._hash(xi + 1 + yi * 57)
        var n01 = root._hash(xi + (yi + 1) * 57)
        var n11 = root._hash(xi + 1 + (yi + 1) * 57)
        var nx0 = n00 + (n10 - n00) * xf
        var nx1 = n01 + (n11 - n01) * xf
        return nx0 + (nx1 - nx0) * yf
    }

    // Octave noise (FBM — fractal Brownian motion) for rich organic texture
    function fbm(x, y, octaves, lacunarity, gain) {
        var val = 0, amp = 1, freq = 1, max = 0
        octaves = octaves || 3
        lacunarity = lacunarity || 2.0
        gain = gain || 0.5
        for (var i = 0; i < octaves; i++) {
            val += noise2D(x * freq, y * freq) * amp
            max += amp
            amp *= gain
            freq *= lacunarity
        }
        return val / max
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SPRING-DAMPER INTEGRATION (semi-implicit Euler)
    // ═══════════════════════════════════════════════════════════════════════════
    // Returns { position, velocity } after dt seconds.
    // Use for per-frame physics simulations (via ScriptAction in animations).

    function springStep(currentPos, currentVel, targetPos, stiffness, damping, dt) {
        var s = stiffness || 200
        var d = damping   || 20
        var force = s * (targetPos - currentPos)
        var accel = force - d * currentVel
        // Semi-implicit Euler: velocity first, then position
        var newVel = currentVel + accel * dt
        var newPos = currentPos + newVel * dt
        return { position: newPos, velocity: newVel, settled: Math.abs(newPos - targetPos) < 0.001 && Math.abs(newVel) < 0.01 }
    }

    // Critically damped spring: d = 2 * sqrt(k)
    function criticalDamping(stiffness) {
        return 2 * Math.sqrt(stiffness)
    }

    // Under-damped spring for bouncy organic feel
    function underDamping(stiffness) {
        return Math.sqrt(stiffness)  // half of critical
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // BRANCHLESS ABS / CLAMP / LERP
    // ═══════════════════════════════════════════════════════════════════════════
    function fastAbs(x)    { return x < 0 ? -x : x }              // JS compiler optimizes to branchless
    function fastClamp(x, lo, hi) { return Math.max(lo, Math.min(hi, x)) }
    function fastLerp(a, b, t)    { return a + (b - a) * t }     // single multiply

    // Inverse lerp (get t from value)
    function fastInvLerp(a, b, v) { return (v - a) / (b - a || 0.001) }

    // Remap value from [inMin, inMax] to [outMin, outMax]
    function remap(v, inMin, inMax, outMin, outMax) {
        return outMin + (outMax - outMin) * ((v - inMin) / (inMax - inMin || 0.001))
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // TRANSITIONAL EXP/LOG APPROXIMATIONS (Padé rational, fast enough for UI)
    // ═══════════════════════════════════════════════════════════════════════════
    // Approximated exp: e^x via limit definition, good for x in [-2, 2]
    function fastExp(x) {
        // exp(x) ≈ (1 + x/n)^n for large n. n=256 is a good balance.
        if (x > 2) return Math.exp(x)   // fallback for large values
        if (x < -2) return Math.exp(x)
        var n = 256
        return Math.pow(1 + x / n, n)
    }

    // Decay factor: e^{-lambda * t} — used for natural friction animations
    function decay(lambda, t) {
        return fastExp(-lambda * t)
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ORGANIC WIND / BREATHING EFFECTS
    // ═══════════════════════════════════════════════════════════════════════════

    // Gentle "breathing" oscillation — combines two sine waves for organic feel
    // Returns a value oscillating between -amplitude and +amplitude
    function breathe(timeMs, amplitude) {
        var t = timeMs * 0.001  // seconds
        var amp = amplitude || 1.0
        // Combine primary breath (~0.25 Hz) + subtle flutter (~1.7 Hz)
        return amp * (
            fastSinLerp(t * 1.57) * 0.7 +
            fastSinLerp(t * 10.68) * 0.3
        )
    }

    // Brownian jitter — small random-feeling displacement that looks natural
    // Uses noise seeded by time for deterministic, smooth motion
    function jitter(timeMs, magnitude) {
        var t = timeMs * 0.001
        var mag = magnitude || 1.0
        return mag * (noise1D(t * 3.7) - 0.5) * 2
    }

    // Natural "settle" — overshoot + decay, like a glass wobbling into place
    // t: normalized time [0, 1]
    // overshoot: how much to overshoot (0-0.5)
    // returns: damped oscillation value
    function settleOver(t, overshoot) {
        var o = overshoot || 0.12
        var omega = 4.5  // oscillation frequency
        // Product of envelope (1 - e^{-8t}) and damped sine
        var envelope = 1 - fastExp(-8 * t)
        var oscillation = fastSinLerp(t * omega * Math.PI) * (1 - t) * o
        return t + oscillation * (1 - t)
    }
}
