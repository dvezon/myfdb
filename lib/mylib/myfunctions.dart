String? driveFolderIdFromUrl(String? url) {
  if (url == null || url.trim().isEmpty) return null;

  final match = RegExp(
    r'drive\.google\.com\/drive\/folders\/([A-Za-z0-9_-]+)',
  ).firstMatch(url);

  return match?.group(1);
}
