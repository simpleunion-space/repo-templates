import hashlib
import json
import os
import shutil
import subprocess
import tempfile
import unittest
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "src"
POWERSHELL_GENERATOR = ROOT / "make" / "New-RepositoryFromTemplate.ps1"
BASH_GENERATOR = ROOT / "make" / "New-RepositoryFromTemplate.sh"
PROFILES = (
    "base",
    "net",
    "net-consoleapp",
    "net-webapp",
    "net-desktopapp",
    "python",
    "unity",
    "iac-base",
    "ansible",
    "salt",
)
CATALOG_COMPONENTS = tuple(f"{profile}-template" for profile in PROFILES)
BUILD_COMPONENTS = {
    "net": ("TemplateProject.Core",),
    "net-consoleapp": ("TemplateProject.Core", "TemplateProject.ConsoleApp"),
    "net-webapp": ("TemplateProject.Core", "TemplateProject.WebApp"),
    "net-desktopapp": ("TemplateProject.Core", "TemplateProject.DesktopApp"),
    "python": ("templateproject",),
    "unity": ("TemplateProject",),
}
MIRRORED_COMPONENT_PROFILES = frozenset(BUILD_COMPONENTS)
REQUIRED_DIRECTORY_PATHS = ("src", "make", "tests", "tools")
REQUIRED_FILE_PATHS = (
    "README.md",
    "README_EN.md",
    "AGENTS.md",
    "AGENTS_EN.md",
    "CODESTYLE.md",
    "CODESTYLE_EN.md",
    "make/Makefile",
    "tools/scripts/verify.sh",
    "tools/scripts/verify-template.sh",
    "tools/scripts/build.sh",
    "tools/scripts/tests.sh",
    "tools/docker/Dockerfile",
    "tools/docker/verify.yaml",
    "tools/docker/build.yaml",
    "tools/docker/tests.yaml",
    "tools/docker/compose.yaml",
)


def tree_files(root: Path) -> dict[str, bytes]:
    return {
        path.relative_to(root).as_posix(): path.read_bytes()
        for path in sorted(root.rglob("*"))
        if path.is_file()
    }


def tree_directories(root: Path) -> set[str]:
    return {
        path.relative_to(root).as_posix() for path in root.rglob("*") if path.is_dir()
    }


def tree_snapshot(root: Path) -> dict[str, tuple[str, str | None]]:
    snapshot = {path: ("directory", None) for path in tree_directories(root)}
    snapshot.update(
        {
            path: ("file", hashlib.sha256(content).hexdigest())
            for path, content in tree_files(root).items()
        }
    )
    return snapshot


def snapshot_drift(
    before: dict[str, tuple[str, str | None]],
    after: dict[str, tuple[str, str | None]],
) -> set[str]:
    return {
        path for path in set(before) | set(after) if before.get(path) != after.get(path)
    }


def direct_directories(root: Path) -> set[str]:
    return {path.name for path in root.iterdir() if path.is_dir()}


def has_real_content(root: Path) -> bool:
    return any(path.is_file() and path.name != ".gitkeep" for path in root.rglob("*"))


def has_unsafe_path_characters(path: str) -> bool:
    return any(character in path for character in "*?[]<>|:")


def unresolved_token_paths(root: Path) -> set[str]:
    return {
        path.relative_to(root).as_posix()
        for path in root.rglob("*")
        if "{{" in path.name
    }


class TemplateCatalogTests(unittest.TestCase):
    def run_generator(self, command: list[str]) -> subprocess.CompletedProcess[str]:
        return subprocess.run(command, text=True, capture_output=True, check=False)

    def assert_component_mirroring(self, repository: Path) -> None:
        self.assertEqual(
            direct_directories(repository / "src"),
            direct_directories(repository / "tests"),
        )

    def assert_identical_tree(self, left: Path, right: Path) -> None:
        self.assertEqual(tree_directories(left), tree_directories(right))
        self.assertEqual(tree_files(left), tree_files(right))

    def assert_generated_common_layout(self, repository: Path, profile: str) -> None:
        for directory in REQUIRED_DIRECTORY_PATHS + ("tools/scripts", "tools/docker"):
            self.assertTrue((repository / directory).is_dir(), directory)
        for file in REQUIRED_FILE_PATHS:
            self.assertTrue((repository / file).is_file(), file)
        self.assertFalse((repository / "tools" / "verify.ps1").exists())

        if profile in MIRRORED_COMPONENT_PROFILES:
            self.assert_component_mirroring(repository)
        else:
            self.assertEqual(set(), direct_directories(repository / "tests"), profile)
            self.assertEqual(
                {".gitkeep"}, set(tree_files(repository / "tests")), profile
            )

        self.assertEqual(
            has_real_content(SOURCE / "base-template" / "docs"),
            (repository / "docs").is_dir(),
        )

        build_components = BUILD_COMPONENTS.get(profile)
        if build_components is None:
            self.assertFalse((repository / "build").exists(), profile)
        else:
            self.assertEqual(
                set(build_components), direct_directories(repository / "build")
            )
            for component in build_components:
                self.assertTrue(
                    (repository / "build" / component / ".gitkeep").is_file()
                )

    def test_catalog_layout_and_documents(self) -> None:
        for name in (
            "README.md",
            "README_EN.md",
            "AGENTS.md",
            "AGENTS_EN.md",
            "CODESTYLE.md",
            "CODESTYLE_EN.md",
        ):
            self.assertTrue((ROOT / name).is_file(), name)
        for name in (
            "README.md",
            "README_EN.md",
            "development.md",
            "development_EN.md",
            "architecture.md",
            "architecture_EN.md",
        ):
            self.assertTrue((ROOT / "docs" / name).is_file(), name)
        for directory in REQUIRED_DIRECTORY_PATHS + (
            "docs",
            "tools/scripts",
            "tools/docker",
        ):
            self.assertTrue((ROOT / directory).is_dir(), directory)
        self.assertFalse((ROOT / "build").exists())
        self.assertFalse((ROOT / "base-template").exists())
        self.assertFalse((ROOT / "iac-template").exists())
        self.assertFalse((ROOT / "tools" / "New-RepositoryFromTemplate.ps1").exists())
        self.assertFalse((ROOT / "tools" / "New-RepositoryFromTemplate.sh").exists())
        self.assertTrue(POWERSHELL_GENERATOR.is_file())
        self.assertTrue(BASH_GENERATOR.is_file())
        self.assertEqual(set(CATALOG_COMPONENTS), direct_directories(SOURCE))
        self.assertEqual(set(), direct_directories(ROOT / "tests"))
        self.assertEqual(
            {"test_templates.py"},
            {path.name for path in (ROOT / "tests").iterdir() if path.is_file()},
        )
        for markdown in ROOT.rglob("*.md"):
            relative_parts = markdown.relative_to(ROOT).parts
            if relative_parts[0] in {"temp", ".tmp"} or markdown.name.endswith(
                "_EN.md"
            ):
                continue
            self.assertTrue(
                markdown.with_name(f"{markdown.stem}_EN.md").is_file(), markdown
            )

    def test_profile_manifests_form_an_acyclic_graph(self) -> None:
        base = json.loads(
            (SOURCE / "base-template" / ".template" / "template.json").read_text(
                encoding="utf-8"
            )
        )
        self.assertEqual(2, base["schemaVersion"])
        manifests = {}
        for profile in PROFILES[1:]:
            manifest = json.loads(
                (
                    SOURCE / f"{profile}-template" / ".template" / "profile.json"
                ).read_text(encoding="utf-8")
            )
            self.assertEqual(profile, manifest["id"])
            self.assertEqual(2, manifest["schemaVersion"])
            self.assertEqual(
                base["schemaVersion"], manifest["requiredBaseSchemaVersion"]
            )
            manifests[profile] = manifest

        self.assertEqual("net", manifests["net-consoleapp"]["parentProfile"])
        self.assertEqual("net", manifests["net-webapp"]["parentProfile"])
        self.assertEqual("net", manifests["net-desktopapp"]["parentProfile"])
        self.assertEqual("iac-base", manifests["ansible"]["parentProfile"])
        self.assertEqual("iac-base", manifests["salt"]["parentProfile"])

        for manifest in (base, *manifests.values()):
            for requirement in manifest["pathRequirements"]:
                self.assertEqual({"path", "kind", "status"}, set(requirement))
                self.assertIn(requirement["kind"], {"file", "directory"})
                self.assertIn(requirement["status"], {"required", "optional"})
                self.assertFalse(Path(requirement["path"]).is_absolute())
                self.assertNotIn("..", Path(requirement["path"]).parts)
                self.assertFalse(has_unsafe_path_characters(requirement["path"]))

        for profile, manifest in manifests.items():
            seen = set()
            current = profile
            while current != "base":
                self.assertNotIn(current, seen)
                seen.add(current)
                parent = manifests[current]["parentProfile"]
                expected = (
                    base["schemaVersion"]
                    if parent == "base"
                    else manifests[parent]["schemaVersion"]
                )
                self.assertEqual(
                    expected, manifests[current]["requiredParentSchemaVersion"]
                )
                current = parent

        expected_paths = {
            "net": "build/{{PROJECT_NAME}}.Core",
            "net-consoleapp": "build/{{PROJECT_NAME}}.ConsoleApp",
            "net-webapp": "build/{{PROJECT_NAME}}.WebApp",
            "net-desktopapp": "build/{{PROJECT_NAME}}.DesktopApp",
            "python": "build/{{PYTHON_PACKAGE}}",
            "unity": "build/{{PROJECT_NAME}}",
        }
        for profile, build_path in expected_paths.items():
            requirements = {
                (item["path"], item["kind"]): item["status"]
                for item in manifests[profile]["pathRequirements"]
            }
            self.assertEqual("required", requirements[(build_path, "directory")])
            self.assertEqual(
                "required", requirements[(f"{build_path}/.gitkeep", "file")]
            )

    def test_generators_create_identical_profiles(self) -> None:
        self.assertIsNotNone(shutil.which("pwsh"))
        self.assertIsNotNone(shutil.which("bash"))
        for profile in PROFILES:
            with (
                self.subTest(profile=profile),
                tempfile.TemporaryDirectory() as temporary,
            ):
                temporary_root = Path(temporary)
                powershell_destination = temporary_root / "powershell"
                bash_destination = temporary_root / "bash"
                powershell = self.run_generator(
                    [
                        "pwsh",
                        "-NoProfile",
                        "-File",
                        str(POWERSHELL_GENERATOR),
                        "-Profile",
                        profile,
                        "-Name",
                        "TemplateProject",
                        "-Destination",
                        str(powershell_destination),
                    ]
                )
                bash = self.run_generator(
                    [
                        "bash",
                        str(BASH_GENERATOR),
                        "--profile",
                        profile,
                        "--name",
                        "TemplateProject",
                        "--destination",
                        str(bash_destination),
                    ]
                )
                self.assertEqual(0, powershell.returncode, powershell.stderr)
                self.assertEqual(0, bash.returncode, bash.stderr)
                powershell_snapshot = tree_snapshot(powershell_destination)
                bash_snapshot = tree_snapshot(bash_destination)
                self.assertEqual(powershell_snapshot, bash_snapshot)
                self.assert_identical_tree(powershell_destination, bash_destination)
                self.assertFalse(
                    any(
                        b"{{" in content
                        for content in tree_files(bash_destination).values()
                    )
                )
                self.assertFalse(unresolved_token_paths(powershell_destination))
                self.assertFalse(unresolved_token_paths(bash_destination))
                self.assert_generated_common_layout(powershell_destination, profile)
                self.assert_generated_common_layout(bash_destination, profile)
                self.assertEqual(
                    powershell_snapshot, tree_snapshot(powershell_destination)
                )
                self.assertEqual(bash_snapshot, tree_snapshot(bash_destination))

    @unittest.skipUnless(
        os.environ.get("TEMPLATE_BIND_MOUNT_ROOT"),
        "requires the Compose-provided host bind mount",
    )
    def test_generators_handle_bind_mounted_destinations(self) -> None:
        bind_mount_root = Path(os.environ["TEMPLATE_BIND_MOUNT_ROOT"])
        self.assertTrue(bind_mount_root.is_dir())
        profiles = ("net-consoleapp", "net-webapp", "net-desktopapp")
        # Keep run-specific evidence under ignored cache. The public generators
        # must both publish safely to a Windows host bind mount.
        bind_run_root = bind_mount_root / f"template-bind-mount-{uuid.uuid4().hex}"
        bind_run_root.mkdir()
        published_snapshots: dict[Path, dict[str, tuple[str, str | None]]] = {}
        with tempfile.TemporaryDirectory(
            prefix="template-bind-reference-"
        ) as temporary:
            reference_root = Path(temporary)
            references: dict[str, Path] = {}
            for profile in profiles:
                reference_destination = reference_root / profile
                bash = self.run_generator(
                    [
                        "bash",
                        str(BASH_GENERATOR),
                        "--profile",
                        profile,
                        "--name",
                        "TemplateProject",
                        "--destination",
                        str(reference_destination),
                    ]
                )
                self.assertEqual(0, bash.returncode, bash.stderr)
                self.assertFalse(unresolved_token_paths(reference_destination))
                self.assert_generated_common_layout(reference_destination, profile)
                references[profile] = reference_destination

            for attempt in range(2):
                for profile in profiles:
                    with self.subTest(attempt=attempt, profile=profile):
                        powershell_destination = (
                            bind_run_root / str(attempt) / profile / "powershell"
                        )
                        bash_destination = (
                            bind_run_root / str(attempt) / profile / "bash"
                        )
                        powershell = self.run_generator(
                            [
                                "pwsh",
                                "-NoProfile",
                                "-File",
                                str(POWERSHELL_GENERATOR),
                                "-Profile",
                                profile,
                                "-Name",
                                "TemplateProject",
                                "-Destination",
                                str(powershell_destination),
                            ]
                        )
                        bash = self.run_generator(
                            [
                                "bash",
                                str(BASH_GENERATOR),
                                "--profile",
                                profile,
                                "--name",
                                "TemplateProject",
                                "--destination",
                                str(bash_destination),
                            ]
                        )
                        self.assertEqual(0, powershell.returncode, powershell.stderr)
                        self.assertEqual(0, bash.returncode, bash.stderr)
                        powershell_snapshot = tree_snapshot(powershell_destination)
                        bash_snapshot = tree_snapshot(bash_destination)
                        published_snapshots[powershell_destination] = (
                            powershell_snapshot
                        )
                        published_snapshots[bash_destination] = bash_snapshot
                        self.assertEqual(powershell_snapshot, bash_snapshot)
                        self.assertFalse(unresolved_token_paths(powershell_destination))
                        self.assertFalse(unresolved_token_paths(bash_destination))
                        self.assert_generated_common_layout(
                            powershell_destination, profile
                        )
                        self.assert_generated_common_layout(bash_destination, profile)
                        self.assert_identical_tree(
                            powershell_destination, references[profile]
                        )
                        self.assert_identical_tree(
                            bash_destination, references[profile]
                        )
                        self.assert_identical_tree(
                            powershell_destination, bash_destination
                        )

            for destination, snapshot in published_snapshots.items():
                with self.subTest(post_generation_drift=destination):
                    current_snapshot = tree_snapshot(destination)
                    self.assertEqual(
                        snapshot,
                        current_snapshot,
                        "post-generation tree drift: "
                        + ", ".join(sorted(snapshot_drift(snapshot, current_snapshot))),
                    )

    def test_tree_snapshot_detects_post_generation_drift(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary) / "base"
            result = self.run_generator(
                [
                    "bash",
                    str(BASH_GENERATOR),
                    "--profile",
                    "base",
                    "--name",
                    "TemplateProject",
                    "--destination",
                    str(destination),
                ]
            )
            self.assertEqual(0, result.returncode, result.stderr)
            before = tree_snapshot(destination)
            (destination / "external-change.txt").write_text(
                "external", encoding="utf-8"
            )
            self.assertEqual(
                {"external-change.txt"},
                snapshot_drift(before, tree_snapshot(destination)),
            )

    def test_generated_profile_layouts(self) -> None:
        expected_paths = {
            "base": ("src/.gitkeep", "tests/.gitkeep"),
            "net": (
                "src/TemplateProject.slnx",
                "src/TemplateProject.Core/TemplateMarker.cs",
                "tests/TemplateProject.Core/TemplateIntegrityTests.cs",
                "build/TemplateProject.Core/.gitkeep",
            ),
            "net-consoleapp": (
                "src/TemplateProject.ConsoleApp/Program.cs",
                "tests/TemplateProject.ConsoleApp/ProgramTests.cs",
                "build/TemplateProject.ConsoleApp/.gitkeep",
            ),
            "net-webapp": (
                "src/TemplateProject.WebApp/Pages/Index.cshtml",
                "tests/TemplateProject.WebApp/HealthEndpointTests.cs",
                "build/TemplateProject.WebApp/.gitkeep",
            ),
            "net-desktopapp": (
                "src/TemplateProject.DesktopApp/App.axaml",
                "src/TemplateProject.DesktopApp/MainWindow.axaml",
                "tests/TemplateProject.DesktopApp/ApplicationIdentityTests.cs",
                "build/TemplateProject.DesktopApp/.gitkeep",
            ),
            "python": (
                "src/templateproject/__init__.py",
                "tests/templateproject/test_package.py",
                "build/templateproject/.gitkeep",
            ),
            "unity": (
                "src/TemplateProject/Assets/TemplateProject/Editor/TemplateBuild.cs",
                "src/TemplateProject/Assets/TemplateProject/Scenes/Bootstrap.unity",
                "tests/TemplateProject/unity-runner.env",
                "build/TemplateProject/.gitkeep",
            ),
            "iac-base": (
                "src/modules/.gitkeep",
                "src/environments/.gitkeep",
                "tests/.gitkeep",
            ),
            "ansible": (
                ".ansible-lint",
                "src/playbooks/.gitkeep",
                "src/roles/.gitkeep",
                "src/inventories/.gitkeep",
                "tests/.gitkeep",
            ),
            "salt": (
                ".salt-lint",
                "src/states/.gitkeep",
                "src/pillar/.gitkeep",
                "tests/.gitkeep",
            ),
        }
        with tempfile.TemporaryDirectory() as temporary:
            temporary_root = Path(temporary)
            for profile, paths in expected_paths.items():
                destination = temporary_root / profile
                result = self.run_generator(
                    [
                        "bash",
                        str(BASH_GENERATOR),
                        "--profile",
                        profile,
                        "--name",
                        "TemplateProject",
                        "--destination",
                        str(destination),
                    ]
                )
                self.assertEqual(0, result.returncode, result.stderr)
                for path in paths:
                    self.assertTrue((destination / path).exists(), path)
                if profile not in BUILD_COMPONENTS:
                    self.assertFalse((destination / "build").exists(), profile)

    def test_generators_reject_nonempty_destination_and_old_iac_profile(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary) / "not-empty"
            destination.mkdir()
            (destination / "existing.txt").write_text("keep", encoding="utf-8")
            file_destination = Path(temporary) / "destination-file"
            file_destination.write_text("keep-file", encoding="utf-8")
            for command in (
                [
                    "bash",
                    str(BASH_GENERATOR),
                    "--profile",
                    "base",
                    "--name",
                    "TemplateProject",
                    "--destination",
                    str(destination),
                ],
                [
                    "pwsh",
                    "-NoProfile",
                    "-File",
                    str(POWERSHELL_GENERATOR),
                    "-Profile",
                    "base",
                    "-Name",
                    "TemplateProject",
                    "-Destination",
                    str(destination),
                ],
            ):
                self.assertNotEqual(0, self.run_generator(command).returncode)
            self.assertEqual(
                "keep", (destination / "existing.txt").read_text(encoding="utf-8")
            )
            for command in (
                [
                    "bash",
                    str(BASH_GENERATOR),
                    "--profile",
                    "base",
                    "--name",
                    "TemplateProject",
                    "--destination",
                    str(file_destination),
                ],
                [
                    "pwsh",
                    "-NoProfile",
                    "-File",
                    str(POWERSHELL_GENERATOR),
                    "-Profile",
                    "base",
                    "-Name",
                    "TemplateProject",
                    "-Destination",
                    str(file_destination),
                ],
            ):
                self.assertNotEqual(0, self.run_generator(command).returncode)
            self.assertEqual("keep-file", file_destination.read_text(encoding="utf-8"))
            old_iac = self.run_generator(
                [
                    "bash",
                    str(BASH_GENERATOR),
                    "--profile",
                    "iac",
                    "--name",
                    "TemplateProject",
                    "--destination",
                    str(Path(temporary) / "iac"),
                ]
            )
            self.assertNotEqual(0, old_iac.returncode)

    def test_compose_scripts_and_linter_templates(self) -> None:
        for profile in PROFILES:
            template = SOURCE / f"{profile}-template"
            self.assertFalse(any(template.rglob("verify.ps1")), profile)
        for yaml_file, script in (
            ("verify.yaml", "verify.sh"),
            ("build.yaml", "build.sh"),
            ("tests.yaml", "tests.sh"),
        ):
            content = (
                SOURCE / "base-template" / "tools" / "docker" / yaml_file
            ).read_text(encoding="utf-8")
            self.assertIn(f"tools/scripts/{script}", content)

        self.assertIn(
            "unittest",
            (ROOT / "tools" / "scripts" / "verify.sh").read_text(encoding="utf-8"),
        )
        catalog_tests = (ROOT / "tools" / "scripts" / "tests.sh").read_text(
            encoding="utf-8"
        )
        for command in ("shellcheck", "yamllint", "ruff", "Invoke-ScriptAnalyzer"):
            self.assertIn(command, catalog_tests)
        self.assertIn(
            "no build step",
            (ROOT / "tools" / "scripts" / "build.sh").read_text(encoding="utf-8"),
        )

        for verify in SOURCE.glob("*-template/overlay/tools/scripts/verify.sh"):
            content = verify.read_text(encoding="utf-8")
            self.assertNotIn("tools/scripts/build.sh", content)
            self.assertNotIn("tools/scripts/tests.sh", content)
        console_tests = (
            SOURCE
            / "net-consoleapp-template"
            / "overlay"
            / "tools"
            / "scripts"
            / "tests.sh"
        ).read_text(encoding="utf-8")
        self.assertIn("dotnet run", console_tests)
        self.assertIn("grep -Fx", console_tests)
        self.assertEqual(1, console_tests.count("dotnet run"))
        root_verify = (ROOT / "tools" / "docker" / "verify.yaml").read_text(
            encoding="utf-8"
        )
        self.assertIn("TEMPLATE_BIND_MOUNT_ROOT", root_verify)
        self.assertIn("../../.cache/template-bind-mount", root_verify)
        for profile, linter in (("ansible", "ansible-lint"), ("salt", "salt-lint")):
            tests = (
                SOURCE
                / f"{profile}-template"
                / "overlay"
                / "tools"
                / "scripts"
                / "tests.sh"
            ).read_text(encoding="utf-8")
            self.assertIn(linter, tests)
            compose = (
                SOURCE
                / f"{profile}-template"
                / "overlay"
                / "tools"
                / "docker"
                / "tests.yaml"
            ).read_text(encoding="utf-8")
            self.assertIn("tools/scripts/tests.sh", compose)
            self.assertIn(":ro", compose)

        unity_build = (
            SOURCE / "unity-template" / "overlay" / "tools" / "scripts" / "build.sh"
        ).read_text(encoding="utf-8")
        self.assertIn("UNITY_BUILD_TARGET", unity_build)
        self.assertIn("-executeMethod", unity_build)
        self.assertIn(
            "UNITY_BUILD_TARGET",
            (
                SOURCE
                / "unity-template"
                / "overlay"
                / "tools"
                / "docker"
                / "build.yaml"
            ).read_text(encoding="utf-8"),
        )
        self.assertIn(
            'Avalonia" Version="12.1.1',
            (
                SOURCE
                / "net-desktopapp-template"
                / "overlay"
                / "Directory.Packages.props"
            ).read_text(encoding="utf-8"),
        )
        powershell_generator = POWERSHELL_GENERATOR.read_text(encoding="utf-8")
        self.assertIn("GetTempPath", powershell_generator)
        self.assertIn("FileMode]::CreateNew", powershell_generator)
        bash_generator = BASH_GENERATOR.read_text(encoding="utf-8")
        self.assertIn("mktemp -d", bash_generator)
        self.assertIn("set -C", bash_generator)
        self.assertNotIn("-mindepth", bash_generator)

    def test_git_diff_has_no_whitespace_errors(self) -> None:
        for command in (
            ["git", "-C", str(ROOT), "diff", "--check"],
            ["git", "-C", str(ROOT), "diff", "--cached", "--check"],
        ):
            with self.subTest(command=command):
                result = subprocess.run(
                    command,
                    text=True,
                    capture_output=True,
                    check=False,
                )
                self.assertEqual(0, result.returncode, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
