/// Page filters from Jira §13/§14. Names serialize into stored JSON.
enum ScanFilter {
  autoColor('Auto Color'),
  original('Original'),
  blackWhite('Black & White'),
  grayscale('Grayscale'),
  lighten('Lighten'),
  highContrast('High Contrast');

  const ScanFilter(this.label);
  final String label;

  bool get isPlus =>
      this == ScanFilter.lighten || this == ScanFilter.highContrast;
}

/// Camera modes from the complete MVP + V2 Jira scope.
enum CameraMode {
  count('Count'),
  measure('Measure'),
  qrCode('QR Code'),
  document('Document'),
  book('Book'),
  translate('Translate'),
  text('Text');

  const CameraMode(this.label);
  final String label;
}

enum LibraryViewMode { grid, list }

enum LibrarySortMode {
  dateCreated('Date Created'),
  dateModified('Date Modified'),
  name('Name');

  const LibrarySortMode(this.label);
  final String label;
}

enum ExportFormat {
  pdf('PDF', 'pdf'),
  jpg('JPG', 'jpg'),
  png('PNG', 'png'),
  txt('Text', 'txt');

  const ExportFormat(this.label, this.extension);
  final String label;
  final String extension;
}
