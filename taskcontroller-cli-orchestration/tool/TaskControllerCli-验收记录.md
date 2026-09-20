# TaskControllerCli Acceptance Record

## Release Mode

Version `0.1.0` is framework-dependent for .NET Framework 4.8. The release package contains the executable, its managed dependencies, the desensitized sample, and command/compatibility references. It requires the .NET Framework 4.8 runtime but does not require Visual Studio or a desktop session.

## Acceptance Gates

- Build with the supplied VS2022 MSBuild path.
- Run `TaskController.Core.Tests.exe`.
- Run `test-cli.ps1` against a copied desensitized sample.
- Run `test-release-package.ps1` on the extracted package: it excludes WinForms/VS artifacts, verifies no `System.Windows.Forms` reference, and starts `--help`, `--version`, and packaged-sample `status --format json` with a minimal runtime `PATH`.

## Evidence

The release script `publish-cli.ps1` runs the build/test gate before packaging into `artifacts/release/TaskControllerCli-<version>.zip`. `test-release-package.ps1` verifies the extracted package. GitHub Actions now performs publish and isolated-package verification before uploading the release ZIP artifact.
