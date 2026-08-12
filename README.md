# Cake Wallet Polyseed RNG Tester

Purpose
-------
This small Flutter/Dart app is intended as a control for Ember Diagnostics.

It uses Dart's `Random.secure()` and generates 10,000 decimal digits (0-9).
It does NOT generate a wallet, seed phrase, private key, or Polyseed.

Why this primitive
------------------
Cake Wallet 6.4.0's Monero Polyseed path calls `Polyseed.create()`, and the
Polyseed implementation uses Dart `Random.secure()` for its random material.
The Android Dart runtime obtains secure random bytes through its platform crypto
implementation; the Android implementation reads from `/dev/urandom`.

Important methodological point
------------------------------
The tester uses `Random.secure().nextInt(10)` for the displayed digits. This
avoids the modulo bias that would result from taking a random byte and doing
`byte % 10`.

The output is therefore a convenient 0-9 representation of the same secure
random primitive, suitable for Ember Diagnostics. It is NOT claiming to
reproduce Polyseed's complete 15-byte seed construction.

Controls
--------
- GENERATE 10,000: creates a fresh independent sample.
- COPY: copies the complete 10,000-digit sample.
- CLEAR: removes it from the app.

No network permission, wallet functions, analytics, or persistent storage are
included by this project.
