export const repositoryUrl = 'https://github.com/lucaslus/floatick';

// Update this alongside the published release. Keep the label and binary in sync.
export const stableRelease = {
  version: '0.3.4',
  date: '2026-08-13',
};

export const previewRelease = {
  version: '0.4.0',
  sourceUrl: `${repositoryUrl}/tree/refactor/tauri`,
};

export const latestDownloadUrl =
  `${repositoryUrl}/releases/download/v${stableRelease.version}/Floatick-macos-universal.dmg`;
