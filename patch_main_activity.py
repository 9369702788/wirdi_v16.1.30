from pathlib import Path
import re

candidates = list(Path("android/app/src/main/kotlin").rglob("MainActivity.kt"))
if not candidates:
    print("WARNING: MainActivity.kt not found -- audio_service media notification will not work")
else:
    for path in candidates:
        text = path.read_text()

        if "AudioServiceActivity" not in text:
            text = text.replace(
                "import io.flutter.embedding.android.FlutterActivity",
                "import com.ryanheise.audioservice.AudioServiceActivity",
            )
            text = text.replace(
                "class MainActivity : FlutterActivity()",
                "class MainActivity : AudioServiceActivity()",
            )
            text = text.replace(
                "class MainActivity: FlutterActivity()",
                "class MainActivity: AudioServiceActivity()",
            )
            print(f"{path}: patched to extend AudioServiceActivity")
        else:
            print(f"{path}: already extends AudioServiceActivity, skipping that step")

        if "dispatchKeyEvent" not in text:
            needed_imports = [
                "import android.app.NotificationManager",
                "import android.content.Context",
                "import android.os.Build",
                "import android.view.KeyEvent",
            ]
            insert_at = text.index(chr(10), text.index("package ")) + 1
            imports_block = chr(10) + chr(10).join(i for i in needed_imports if i not in text) + chr(10)
            if imports_block.strip():
                text = text[:insert_at] + imports_block + text[insert_at:]

            method_lines = [
                "    // BUGFIX: stop the Adhan notification sound when the user",
                "    // presses a volume key while the app is in the foreground.",
                "    override fun dispatchKeyEvent(event: KeyEvent): Boolean {",
                "        if (event.action == KeyEvent.ACTION_DOWN &&",
                "            (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP || event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN)) {",
                "            try {",
                "                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager",
                "                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {",
                "                    for (activeNotification in notificationManager.activeNotifications) {",
                '                        if (activeNotification.notification.channelId == "wirdi_prayer_adhan_v2") {',
                "                            notificationManager.cancel(activeNotification.id)",
                "                        }",
                "                    }",
                "                }",
                "            } catch (e: Exception) {",
                "                // Best-effort only -- never let this crash the app.",
                "            }",
                "        }",
                "        return super.dispatchKeyEvent(event)",
                "    }",
            ]
            override_method = chr(10) + chr(10).join(method_lines) + chr(10)

            bodyless = re.search(r"class\s+MainActivity\s*:\s*\w+\(\)\s*(?://.*)?$", text, re.MULTILINE)
            brace_open = re.search(r"class\s+MainActivity\s*:\s*\w+\(\)\s*\{", text)
            if brace_open:
                insert_pos = brace_open.end()
                text = text[:insert_pos] + override_method + text[insert_pos:]
                print(f"{path}: inserted dispatchKeyEvent() into existing class body")
            elif bodyless:
                line = bodyless.group(0)
                new_line = line.rstrip() + " {" + override_method + "}"
                text = text[:bodyless.start()] + new_line + text[bodyless.end():]
                print(f"{path}: added class body with dispatchKeyEvent()")
            else:
                print(f"WARNING: {path}: could not find MainActivity class declaration in an expected shape -- dispatchKeyEvent() NOT added, please check this file manually")
        else:
            print(f"{path}: dispatchKeyEvent() already present, skipping that step")

        path.write_text(text)
