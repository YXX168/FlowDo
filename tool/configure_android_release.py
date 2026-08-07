"""Inject the CI-only release signing config into Flutter's Android template."""

from __future__ import annotations

import sys
from pathlib import Path


SIGNING_CONFIG = """    signingConfigs {
        create(\"release\") {
            storeFile = file(requireNotNull(System.getenv(\"FLOWDO_KEYSTORE_PATH\")))
            storePassword = requireNotNull(System.getenv(\"FLOWDO_KEYSTORE_PASSWORD\"))
            keyAlias = requireNotNull(System.getenv(\"FLOWDO_KEY_ALIAS\"))
            keyPassword = requireNotNull(System.getenv(\"FLOWDO_KEY_PASSWORD\"))
            storeType = System.getenv(\"FLOWDO_KEYSTORE_TYPE\") ?: \"PKCS12\"
        }
    }

"""


def configure(path: Path) -> None:
    source = path.read_text(encoding="utf-8")
    marker = "    buildTypes {"
    debug_signing = 'signingConfig = signingConfigs.getByName("debug")'

    if marker not in source:
        raise RuntimeError(f"Could not find buildTypes block in {path}")
    if debug_signing not in source:
        raise RuntimeError(f"Could not find Flutter's debug release signing in {path}")

    source = source.replace(marker, SIGNING_CONFIG + marker, 1)
    source = source.replace(
        debug_signing,
        'signingConfig = signingConfigs.getByName("release")',
        1,
    )
    path.write_text(source, encoding="utf-8")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: configure_android_release.py <build.gradle.kts>")
    configure(Path(sys.argv[1]))
