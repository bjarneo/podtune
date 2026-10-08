.pragma library

// The guide text. The Guide page shows every topic. Each info icon shows the summary of one topic.

var GROUPS = [
    { title: "Basics", topics: ["start", "presets", "warmth", "presence", "leveling"] },
    { title: "Voice test", topics: ["meter", "gain", "mute", "record", "takes"] },
    { title: "Headphones", topics: ["headphones", "monitorMix"] },
    { title: "Advanced", topics: ["hpf", "compressor", "aphex", "gate", "save", "device"] },
    { title: "App", topics: ["themes", "shortcuts"] }
]

var TOPICS = {
    start: {
        title: "Getting started",
        summary: "Set the level, record a reference take, then compare presets.",
        steps: [
            "Connect headphones to the PodMic USB.",
            "Select Check levels and speak at your normal volume.",
            "Adjust Input gain until speech peaks stay inside the shaded band.",
            "Select Record test and say a short phrase. Select the button again to stop.",
            "Select a preset and record the same phrase.",
            "Play both takes and compare them."
        ]
    },
    presets: {
        title: "Presets",
        summary: "A preset sets the compressor and the APHEX tone effects in one step.",
        body: [
            "A preset sets the compressor, Big Bottom, Aural Exciter, and high-pass filter. Factory presets keep your input gain, headphone settings, and noise gate.",
            "A card shows Active when the hardware matches the preset. It shows Edited after you change a control. Select Reset to return to the preset values.",
            "The three bars on each card show Warmth, Presence, and Leveling. When the row has more presets than fit, hold Shift and scroll, or swipe sideways on the touchpad."
        ]
    },
    warmth: {
        title: "Warmth",
        summary: "Adds low-end body with the APHEX Big Bottom effect.",
        body: [
            "Warmth sets the drive of the APHEX Big Bottom effect. Big Bottom adds weight to the low frequencies of your voice. A value of 0 turns the effect off.",
            "The device scale is steep. The effect is faint below 50 and grows quickly above 80. Big Bottom shows the drive in percent."
        ]
    },
    presence: {
        title: "Presence",
        summary: "Adds clarity to speech with the APHEX Aural Exciter.",
        body: [
            "Presence sets the mix and the tune frequency of the APHEX Aural Exciter. The exciter adds harmonics above the tune frequency, and this makes speech clearer. A value of 0 turns the effect off.",
            "A higher value also moves the tune frequency up. The device scale is steep, so the effect grows quickly above 80."
        ]
    },
    leveling: {
        title: "Leveling",
        summary: "Keeps speech consistent with the compressor.",
        body: [
            "Leveling sets the compressor threshold, ratio, and makeup gain together. Loud words become quieter, and the makeup gain raises the overall level. A higher value compresses more. A value of 0 turns the compressor off.",
            "To set each compressor value directly, select Advanced."
        ]
    },
    meter: {
        title: "Level meter",
        summary: "Shows the live input level and the target range for speech.",
        body: [
            "The waveform shows the peak level of the last five seconds. The shaded band marks the target range from −18 to −6 dBFS.",
            "Peak shows the highest level of the last 0.4 seconds. RMS shows the average level. The status tells you if the level is low, in the target range, high, or too high.",
            "The meter measures the signal level only. Listen for tone, distortion, and room noise yourself."
        ]
    },
    gain: {
        title: "Input gain",
        summary: "Sets the microphone preamp gain from 22 to 63 dB.",
        body: [
            "Input gain sets the analog gain before the DSP. Set it so that speech peaks stay inside the shaded band of the meter.",
            "Too much gain adds hiss and can clip. Too little gain gives a weak signal."
        ]
    },
    mute: {
        title: "Mute",
        summary: "Silences the microphone input on the device.",
        body: [
            "Mute silences the microphone on the device. Other apps also receive silence while Mute is on."
        ]
    },
    record: {
        title: "Voice test",
        summary: "Records a short test take so that you can compare settings.",
        body: [
            "Record test saves a mono 48 kHz WAV file. Each take stops after 60 seconds. Press Space to start or stop a take.",
            "Check levels shows the meter without a saved file. Takes stay on this computer."
        ]
    },
    takes: {
        title: "Takes",
        summary: "Play back, compare, and delete your test takes.",
        body: [
            "Each take shows the time, the preset, the length, the peak level, and the clipped samples. Clipped samples mean that the level was too high. If you see them, lower the input gain.",
            "Select the play button to listen through the headphone output of the PodMic USB. Trash moves the take to the system trash. Open folder shows the files."
        ]
    },
    headphones: {
        title: "Headphones",
        summary: "Monitor your voice and set the computer playback level.",
        body: [
            "Direct monitor sends the microphone signal to the headphone output of the PodMic USB without delay.",
            "Computer playback sets the level of audio from the computer, such as voice test playback. The dial on the microphone sets the headphone output level."
        ]
    },
    monitorMix: {
        title: "Monitor mix",
        summary: "Balances the microphone and the computer audio in the headphones.",
        body: [
            "Monitor mix is a raw device value from 0 to 255. The direction depends on the device. Compare both ends at a low headphone volume."
        ]
    },
    hpf: {
        title: "High-pass filter",
        summary: "Removes rumble below 60 Hz.",
        body: [
            "The high-pass filter removes low rumble from desks, traffic, and air conditioning. Keep it on for speech."
        ]
    },
    compressor: {
        title: "Compressor",
        summary: "Reduces loud peaks and keeps speech consistent.",
        body: [
            "The compressor lowers the level of sound above the threshold. The curve shows the input level against the output level."
        ],
        terms: [
            ["Threshold", "The level where compression starts."],
            ["Ratio", "How much the compressor reduces the level above the threshold. At 4:1, an input 4 dB above the threshold comes out 1 dB above it."],
            ["Attack", "How fast the compressor reacts to a loud sound."],
            ["Release", "How fast the compressor lets go when the sound becomes quieter."],
            ["Makeup gain", "Raises the level after compression."]
        ]
    },
    aphex: {
        title: "APHEX tone",
        summary: "Big Bottom and Aural Exciter enhance bass and clarity.",
        body: [
            "These effects add character to your voice. They are not a parametric EQ.",
            "The device scale is steep. A value of 50 % gives about 12 % of full strength, and 90 % gives about 40 %."
        ],
        terms: [
            ["Big Bottom", "Adds low-end weight. Drive sets the amount."],
            ["Aural Exciter", "Adds clarity. Mix sets the amount, and frequency sets where the effect starts."]
        ]
    },
    gate: {
        title: "Noise gate",
        summary: "Lowers the signal when you do not speak.",
        body: [
            "The gate closes when the level falls below the threshold. A threshold that is too high cuts the start of words.",
            "The app does not switch the gate on or off, because that command is not verified."
        ],
        terms: [
            ["Threshold", "The level where the gate opens."],
            ["Attack", "How fast the gate opens."],
            ["Release", "How fast the gate closes."]
        ]
    },
    save: {
        title: "Save preset",
        summary: "Stores the current hardware settings as your own preset.",
        body: [
            "Enter a name and select Save. Your preset stores every readable control, including input gain and headphone settings. Saved presets appear after the factory presets."
        ]
    },
    device: {
        title: "Device",
        summary: "Shows the connected microphone and reads its settings again.",
        body: [
            "The app reads each control back after it writes it. It shows an error if a value does not match.",
            "The microphone keeps the settings after the app closes. A power cycle can reset them. Press Ctrl+R to read the hardware state again."
        ]
    },
    themes: {
        title: "Themes",
        summary: "Use Dark, Light, or the colors of your Omarchy theme.",
        body: [
            "Omarchy mode follows the current Omarchy theme. It updates when you change the theme."
        ]
    },
    shortcuts: {
        title: "Keyboard shortcuts",
        summary: "Control the app from the keyboard.",
        keys: true,
        terms: [
            ["Space", "Start or stop a voice test."],
            ["Ctrl Z", "Undo a verified change."],
            ["Ctrl Shift Z", "Redo a change."],
            ["Ctrl R", "Read the hardware state again."],
            ["?", "Show the help."],
            ["Esc", "Close the guide, the help, or the Advanced panel."],
            ["Q", "Quit."]
        ]
    }
}

function order() {
    var ids = []
    for (var i = 0; i < GROUPS.length; i++) ids = ids.concat(GROUPS[i].topics)
    return ids
}

function summary(id) {
    return TOPICS[id] ? TOPICS[id].summary : ""
}
