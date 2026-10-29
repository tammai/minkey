# minkey

Bộ gõ tiếng Việt Telex cho macOS, gõ đúng cả trong Microsoft Teams, Slack và trình duyệt.
A Vietnamese Telex keyboard for macOS that types correctly in Microsoft Teams, Slack and the browser.

- Không gạch chân, không lặp chữ khi xoá giữa từ trong Teams.
- Bỏ dấu tự do, kiểm tra chính tả (tiếng Anh giữ nguyên), gõ tắt, nhớ Việt/Anh theo từng ứng dụng.
- Không cần quyền Trợ năng (Accessibility). Không lưu, không gửi nội dung bạn gõ.

## Install

Download the latest `.pkg` from [Releases](https://github.com/tammai/minkey/releases), open it, then add
**minkey** under System Settings → Keyboard → Text Input → Input Sources (Vietnamese). Requires macOS 13 or later.

## How it works

Most Vietnamese keyboards on the Mac either fake backspaces through an event tap, which races with web editors, or
underline the word being typed, which Teams duplicates when you press Delete. minkey uses InputMethodKit and replaces
only the characters that change, as finished text. Apps that can't report the text before the cursor, such as some
terminals, get underlined text instead. See [docs/compatibility.md](docs/compatibility.md) for tested apps.

## Develop

```sh
swift test                 # engine and delivery tests
scripts/install-dev.sh     # build and install for the current user
scripts/test-bundle.sh     # check the app bundle
```

The Telex engine (`Sources/MinkeyEngine`) is pure Swift and knows nothing about apps; delivery (`Sources/MinkeyKit`)
turns its words into edits; `Sources/Minkey` is the input method itself. Releases are cut with `scripts/release.sh`.

## Licence

MIT. minkey learns from OpenKey's documented Telex rules but contains none of its code.
