[![GitHub latest release][release-img]][release-url]
[![GitHub release date][release-date-img]][release-url]

# Batch-Encoder
A small personal project. A .bat file which uses FFmpeg to encode a folder full of video files.

## Dependencies:
- [FFmpeg](https://github.com/GyanD/codexffmpeg)
  - This will at some point be acquired for you, but currently must be downloaded manually first
<br></br>

## How to download/update:
### A) Auto-Updater
If you are using the program already (version 1.4 and above), update using the built-in auto-updater. [^1]
### B) Downloader
Grab the `b-e.updater.bat` file, either from Releases or by clicking [here](https://github.com/Adam-Kay/Batch-Encoder/releases/latest/download/b-e.updater.bat) to download directly. Place it in the desired folder and run it, and it will download the latest version of the program, and remove your old version if you have one.

Alternatively, this may be downloaded in a Windows terminal with the following command:
  ```pwsh
  curl -L -ssl-no-revoke -o updater.bat "https://github.com/Adam-Kay/Batch-Encoder/releases/latest/download/b-e.updater.bat"
  ```
### C) Manual Download
Download the <code>batch.encoder.v`x`.`x`.`x`.bat</code> file from Releases. Place it in the desired folder, delete any older versions you have, and run.
<br></br>

## Instructions for use:
1. Place into a folder with video files.
2. Run <code>batch.encoder.v`x`.`x`.`x`.bat</code>.
3. Follow the steps listed on-screen.
<br></br>

[^1]: <strong><p></p>Known Issues</strong><ul><!--
--><li>Versions prior to v1.6.3 have a known issue of struggling to update on corporate networks. This is resolved in later versions, but in these cases, the only options are to continue re-attempting until it works, or using the latest updater as outlined [in B](#b-downloader).<!--
--><li>Versions between 1.7.0 and 1.7.2 are susceptible to a bug where the updater could fail once it downloads changelog information. The resolution is to update with the latest updater as shown [in B](#b-downloader).</li>
</ul>

[release-img]: https://img.shields.io/github/release/Adam-Kay/Batch-Encoder.svg?style=for-the-badge&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQEAQAAADlauupAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAAAqo0jMgAAAAlwSFlzAAAAYAAAAGAA8GtCzwAAAAd0SU1FB+cMHBQVKAGFwf4AAAFlSURBVDjLxZM/S8NQFMXvI0WSTsVdBaeC2eLXcNJ8Fwe3Lk4VS4NDP0KhgzSL/6BbP0CcBJcS/yxdWooBc38OiU3Tpq6e6b137zncdzhXZA3o8THa68HLCywW6HwOUYS229BsLvuwbfC8gki9nhH/wvc3dDrQaKAPD5AkOdlxYDQqN8cxencHYQiTSbk2m/2ecoGbm6L48QGnp2BZ5a+dnEAcr88kqOtCmi7Jur8vFQDHQR8fNwW4vl7e1PdlC2A4rHKlJjKdCv2+mOlUzGAgWxFFwmJRejKvr/LvMHB5KRwero9mzPl5tReWJRIEwu6umPFYqgMzHG41U32/MP3iokLg6Qkcp5p8cACfn1nf1xe6t1ch8P6eBcmY1bHRs7OCDNBq5cXNeBZCYYje38PbW7l2e4vWarlAkmSL0WhAt1uksgppCldX6M7OiqueB7Zd3I+OsnRGETqfZ+v8/AxBgLruui8/vtYVt8juXQkAAAAASUVORK5CYII=
[release-url]: https://github.com/Adam-Kay/Batch-Encoder/releases
[release-date-img]: https://img.shields.io/github/release-date/Adam-Kay/Batch-Encoder?style=for-the-badge&label=%20&color=6666cc
