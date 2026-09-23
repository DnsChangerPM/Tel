; Tel - Windows installer script (Inno Setup 6)
;
; Build on Windows:
;   flutter build windows --release
;   "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" /DMyAppVersion=1.2.0 tools\installer.iss
;
; The GitHub Actions workflow runs this automatically when Inno Setup is
; available on the runner, producing Tel-<version>-setup-x64.exe
;
; Compatibility: Windows 8.1 (6.3) up to Windows 11 - same range as the
; Flutter 3.19.6 Windows toolchain used by the release workflow.

#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif
#define MyAppName "Tel"
#define MyAppPublisher "DnsChangerPM"
#define MyAppURL "https://github.com/DnsChangerPM/Tel"
#define MyAppExeName "tel.exe"

[Setup]
AppId={{8F1B0D52-6B3E-4A0C-9C2E-4B2F0F5A9C11}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}/releases
; SourceDir makes every relative path below resolve from the repository root
SourceDir=..
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
LicenseFile=assets\fonts\OFL-Vazirmatn.txt
OutputDir=dist
OutputBaseFilename=Tel-{#MyAppVersion}-setup-x64
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; Windows 8.1 and newer; x64 only (Flutter Windows output is 64-bit)
MinVersion=6.3
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\{#MyAppExeName}
PrivilegesRequiredOverridesAllowed=dialog

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"; Flags: unchecked

[Files]
; Complete Flutter output: tel.exe + flutter_windows.dll + data folder
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
