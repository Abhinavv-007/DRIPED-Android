# Manual Logo Fix Report

Date: 2026-04-14

## Replaced From `new-logos`

The following active frontend assets were replaced with manually supplied logos:

| Active asset | Source file |
| --- | --- |
| `amazonpay.svg` | `amazon-pay-1.svg` |
| `applearcade.svg` | `apple-arcade.svg` |
| `applemusic.svg` | `apple-music.svg` |
| `applepay.svg` | `apple-pay-3.svg` |
| `appletv.svg` | `apple-tv.svg` |
| `fitbitpremium.svg` | `fitbit.svg` |
| `googlepay.svg` | `google-pay-logo-2020.svg` |
| `gpay.svg` | `google-pay-logo-2020.svg` |
| `googleworkspace.svg` | `logo-google-workspace.svg` |
| `youtubemusic.svg` | `youtube-music-1.svg` |

The previous versions for these slugs were archived under:

- `assets/icons_archive/manual_fix_20260414_1500/`

## Removed From Active Set

These logos were intentionally removed from the active icon bundle and should not be reintroduced into the frontend sync list:

- `kotak`
- `yesbank`
- `aubank`
- `shopifycollabs`

## Still Needs Manual Correction

These slugs are still present in the active icon bundle but are not yet the correct distinct product logos:

- `amazonmusic`
- `googleone`

The active files exist in `assets/icons`, but they still render the generic Amazon smile and Google `G` marks rather than the actual Amazon Music and Google One product logos.

These remain acceptable duplicates by design:

- `googlepay`
- `gpay`
- `binancepay` → reuse `binance`
