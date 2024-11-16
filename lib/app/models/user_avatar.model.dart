
class UserAvatar {
  final String id;
  final String type;
  final String path;
  final String name;
  final String mime;
  final int? size;
  final int? width;
  final int? height;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserAvatar({
    required this.id,
    required this.type,
    required this.path,
    required this.name,
    required this.mime,
    required this.size,
    this.width,
    this.height,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserAvatar.fromJson(Map<String, dynamic> json) {
    return UserAvatar(
      id: json['id'],
      type: json['type'],
      path: json['path'],
      name: json['name'],
      mime: json['mime'],
      size: json['size'],
      width: json['width'],
      height: json['height'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['type'] = type;
    data['path'] = path;
    data['name'] = name;
    data['mime'] = mime;
    data['size'] = size;
    data['width'] = width;
    data['height'] = height;
    data['createdAt'] = createdAt.toIso8601String();
    data['updatedAt'] = updatedAt.toIso8601String;
    return data;
  }

  String get avatarUrl => 'https://i.iwara.tv/image/avatar/$id/$id.jpg';
}