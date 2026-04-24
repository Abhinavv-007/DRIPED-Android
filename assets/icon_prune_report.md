# Icon Prune Report

Date: 2026-04-14

## Result

- Kept in active Flutter asset directory: `assets/icons/` -> 153 SVG files
- Moved out of the shipped asset directory: `assets/icons_archive/` -> 3270 SVG files

## Verification Rule

Icons were kept when they met at least one of these conditions:

1. They are already used or resolvable by the current app flows for subscriptions, service avatars, or payment methods.
2. They are clearly relevant to this product's scope: subscription brands, recurring-billing services, payment providers, banks, telecom providers, consumer apps, SaaS tools, streaming/media brands, gaming memberships, or productivity tools.
3. They are likely to be useful through the app's generic custom-name icon resolution for manually added subscriptions or payment methods.

Icons were moved to `assets/icons_archive/` when they did not meet the above criteria and were clearly outside this product's practical scope, especially low-level frameworks, libraries, infrastructure projects, programming-language logos, and unrelated brand marks.

## Source Of Truth

- Keep list: `assets/icon_keep_list.txt`
- Active app asset directory: `assets/icons/`
- Archived remainder: `assets/icons_archive/`
