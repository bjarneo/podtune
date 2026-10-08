# Protocol reference

The app uses the coefficient tables from `borsuk85/RodePodMicUSB-linux`.
The build embeds these tables into the app binary.
The app implements its own C++ transport, state model, and audio test path.

Source: <https://github.com/borsuk85/RodePodMicUSB-linux>

Reference revision: `9c79097161663849ae9c711119d893699260dc89`.

The upstream `LICENSE` covers the coefficient tables and protocol reference.

## Geist fonts

The app embeds the Geist and Geist Mono fonts from the Geist project.
The SIL Open Font License 1.1 covers the fonts. See `geist/OFL.txt`.

Source: <https://github.com/vercel/geist-font>
