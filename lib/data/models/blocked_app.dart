class BlockedApp {
  const BlockedApp({required this.packageName, required this.appName});

  final String packageName;
  final String appName;

  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'appName': appName,
  };

  factory BlockedApp.fromJson(Map<String, dynamic> json) => BlockedApp(
    packageName: json['packageName'] as String,
    appName: json['appName'] as String,
  );
}
