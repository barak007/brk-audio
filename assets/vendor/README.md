# Vendored runtime assets

These files are served locally by the website. Updating them requires rerunning the site checks and responsive browser validation.

| Asset                | Version          | Source                                              | License                                                          |
| -------------------- | ---------------- | --------------------------------------------------- | ---------------------------------------------------------------- |
| GSAP                 | 3.13.0           | `cdn.jsdelivr.net/npm/gsap@3.13.0/dist/gsap.min.js` | GreenSock standard license, linked in the file banner            |
| Manrope              | Fontsource 5.2.6 | `@fontsource-variable/manrope`                      | SIL Open Font License 1.1, stored in `fonts/LICENSE-Manrope.txt` |
| DM Mono              | Fontsource 5.2.6 | `@fontsource/dm-mono`                               | SIL Open Font License 1.1, stored in `fonts/LICENSE-DM-Mono.txt` |
| GoatCounter count.js | v4               | `gc.zgo.at/count.v4.js`                             | ISC license, linked in the file banner                           |

The source URLs are provenance records only. Pages do not request them at runtime. Once analytics is on, `count.js` sends each page view and tracked click to GoatCounter (see the site README).
