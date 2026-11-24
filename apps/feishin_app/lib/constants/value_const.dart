class ValueConst {
  static const app = 'Feishin Remote';
  static const playing = 'Now Playing';
  static const library = 'Library';
  static const queue = 'Queue';
  static const settings = 'Settings';
  static const connections = 'Connections';
  static const connect = 'Connect to Feishin';
  static const connectInstruction =
      'Enable Remote Control in Feishin desktop, then enter its network address.';
  static const lan = 'Local network';
  static const encrypted = 'Encrypted';
  static const lanNotice =
      'The address and credentials travel unencrypted. Use this option on a network you trust.';
  static const profileName = 'Profile name';
  static const address = 'Desktop address';
  static const localHint = '192.168.1.20:4333';
  static const secureHint = 'music.example.com';
  static const username = 'Username';
  static const password = 'Password';
  static const rememberPassword = 'Remember password on this device';
  static const saveConnect = 'Save and connect';
  static const noTrack = 'Nothing is playing';
  static const noTrackDetail = 'Choose something from your Feishin library.';
  static const noQueue = 'The queue is empty';
  static const queueUnavailable = 'Waiting for the desktop queue';
  static const noResults = 'No results';
  static const noItems = 'Nothing to show';
  static const emptyTip =
      'Try refreshing or check the library source in Feishin.';
  static const retry = 'Retry';
  static const loadMore = 'Load more';
  static const cancel = 'Cancel';
  static const playNow = 'Play now';
  static const playNext = 'Play next';
  static const addQueue = 'Add to queue';
  static const addPlaylist = 'Add to playlist';
  static const remove = 'Remove';
  static const clearQueue = 'Clear queue';
  static const replaceQueue = 'Replace the queue?';
  static const replaceMessage =
      'Playing this now replaces the current desktop queue.';
  static const clearMessage = 'Remove all items from the desktop queue?';
  static const volume = 'Desktop volume';
  static const disconnect = 'Disconnect';
  static const artworkTrust = 'Allow artwork from other hosts';
  static const artworkTrustHint =
      'Feishin may return covers hosted on your music server.';
  static const browseLibrary = 'Browse library';
  static const offlineLibrary = 'Not connected';
  static const offlineLibraryDetail =
      'Connect to a Feishin desktop to browse its library.';
  static const differentSearch = 'Try a different search.';
  static const refresh = 'Refresh';
  static const nowPlayingBadge = 'Now playing';
  static const play = 'Play';
  static const pause = 'Pause';
  static const next = 'Next track';
  static const previous = 'Previous track';
  static const shuffle = 'Shuffle';
  static const addFavorite = 'Add favorite';
  static const removeFavorite = 'Remove favorite';
  static const trackRating = 'Track rating';
  static const savedDesktops = 'Saved desktops';
  static const addDesktop = 'Add a desktop';
  static const active = 'Active';
  static const connected = 'Connected';
  static const connecting = 'Connecting to Feishin…';
  static const reconnecting = 'Reconnecting…';
  static const authFailed = 'Authentication failed';
  static const disconnected = 'Disconnected';
  static String repeat(String mode) => 'Repeat: $mode';
  static String volumePercent(double value) => '${value.round()} percent';
  static String queueSummary(int count, Duration total) {
    final minutes = total.inMinutes;
    final length = minutes >= 60
        ? '${minutes ~/ 60} h ${minutes % 60} min'
        : '$minutes min';
    return '$count ${count == 1 ? 'track' : 'tracks'} · $length';
  }
}
