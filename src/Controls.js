.pragma library

var CTRL = {
    gain: { min: 22, max: 63, step: 1, decimals: 0, unit: "dB" },
    headphones: { min: -60, max: 0, step: 1, decimals: 0, unit: "dB" },
    monitorMix: { min: 0, max: 255, step: 1, decimals: 0, unit: "/ 255" },
    compThreshold: { min: -60, max: 0, step: 0.5, decimals: 1, unit: "dB" },
    compRatio: { min: 1.5, max: 4.5, step: 0.1, decimals: 1, unit: ":1" },
    compAttack: { min: 0.1, max: 10, step: 0.1, decimals: 1, unit: "ms" },
    compRelease: { min: 5, max: 200, step: 1, decimals: 0, unit: "ms" },
    compGain: { min: 0, max: 9, step: 0.1, decimals: 1, unit: "dB" },
    bottomDrive: { min: 0, max: 100, step: 1, decimals: 0, unit: "%" },
    exciterMix: { min: 0, max: 100, step: 1, decimals: 0, unit: "%" },
    exciterTune: { min: 600, max: 5000, step: 25, decimals: 0, unit: "Hz" },
    gateThreshold: { min: -100, max: 0, step: 1, decimals: 0, unit: "dB" },
    gateAttack: { min: 1, max: 2000, step: 1, decimals: 0, unit: "ms" },
    gateRelease: { min: 1, max: 4000, step: 1, decimals: 0, unit: "ms" }
}

function num(value) {
    var n = Number(value)
    return isFinite(n) ? n : 0
}

function clamp(x, low, high) {
    return Math.min(high, Math.max(low, x))
}

function signed(x, decimals) {
    var text = Math.abs(x).toFixed(decimals)
    return (x < 0 && Number(text) !== 0 ? "−" : "") + text
}

function snap(key, x) {
    var c = CTRL[key]
    return clamp(Math.round((x - c.min) / c.step) * c.step + c.min, c.min, c.max)
}

function format(key, x) {
    var c = CTRL[key]
    var text = signed(snap(key, x), c.decimals)
    return c.unit === ":1" ? text + ":1" : text + " " + c.unit
}

function kHz(hz) {
    return (hz / 1000).toFixed(2).replace(/0$/, "").replace(/\.0$/, "")
}

function db(amplitude) {
    return 20 * Math.log10(Math.max(amplitude, 3.2e-5))
}

function tailPeak(list, count) {
    var peak = 0
    for (var i = Math.max(0, list.length - count); i < list.length; i++) peak = Math.max(peak, list[i])
    return peak
}

// Warmth, Presence, and Leveling map the APHEX and compressor controls to one 0 to 100 scale.
function macros(v) {
    var level = function(x) { return clamp(Math.round(x), 1, 100) }
    return {
        W: num(v.bottom) ? level(num(v.bottomDrive) / 0.4) : 0,
        P: num(v.exciter) ? level(num(v.exciterMix) / 0.4) : 0,
        L: num(v.compressor) ? level((-10 - num(v.compThreshold)) / 0.2) : 0
    }
}

function macroValues(key, m) {
    var n = {}
    if (key === "W") {
        n.bottom = m > 0 ? 1 : 0
        if (m > 0) n.bottomDrive = Math.round(m * 0.4)
    } else if (key === "P") {
        n.exciter = m > 0 ? 1 : 0
        if (m > 0) {
            n.exciterMix = Math.round(m * 0.4)
            n.exciterTune = Math.round((2000 + 22 * m) / 25) * 25
        }
    } else if (key === "L") {
        n.compressor = m > 0 ? 1 : 0
        if (m > 0) {
            n.compThreshold = Math.round((-10 - 0.2 * m) * 2) / 2
            n.compRatio = Math.round((1.5 + 0.02 * m) * 10) / 10
            n.compGain = Math.round(0.4 * m) / 10
        }
    }
    return n
}
