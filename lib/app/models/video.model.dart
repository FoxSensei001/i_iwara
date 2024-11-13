
import 'package:i_iwara/app/models/tag.model.dart';
import 'package:i_iwara/app/models/user.model.dart';
import 'package:i_iwara/app/models/media_file.model.dart';
import 'package:i_iwara/app/models/video_source.model.dart';

import 'custom_thumbnail.model.dart';

class Video {
  final String id;
  final String? slug;
  final String? title;
  final String? body;
  final String? status;
  final String? rating; // general, ecchi 分别代表 一般, 色情
  final bool? private;
  final bool? unlisted;
  final int? thumbnail;
  final String? embedUrl;
  final bool? liked;
  final int? numLikes;
  final int? numViews;
  final int? numComments;
  final MediaFile? file;
  final CustomThumbnail? customThumbnail;
  final User? user;
  final List<Tag>? tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? fileUrl;

  final List<VideoSource>? videoSources;

  Video({
    required this.id,
    this.slug,
    this.title,
    this.body,
    this.status,
    this.rating,
    this.private,
    this.unlisted,
    this.thumbnail,
    this.embedUrl,
    this.liked,
    this.numLikes,
    this.numViews,
    this.numComments,
    this.file,
    this.customThumbnail,
    this.user,
    this.tags,
    this.createdAt,
    this.updatedAt,
    this.fileUrl,
    this.videoSources,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] ?? '',
      slug: json['slug'],
      title: json['title'],
      body: json['body'],
      status: json['status'],
      rating: json['rating'],
      private: json['private'],
      unlisted: json['unlisted'],
      thumbnail: json['thumbnail'],
      embedUrl: json['embedUrl'],
      liked: json['liked'],
      numLikes: json['numLikes'],
      numViews: json['numViews'],
      numComments: json['numComments'],
      file: json['file'] != null ? MediaFile.fromJson(json['file']) : null,
      customThumbnail: json['customThumbnail'] != null
          ? CustomThumbnail.fromJson(json['customThumbnail'])
          : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      tags: json['tags'] != null
          ? (json['tags'] as List).map((tag) => Tag.fromJson(tag)).toList()
          : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      fileUrl: json['fileUrl'],
      videoSources: null,
    );
  }

  // 头图
  String get thumbnailUrl {
    if (customThumbnail != null) {
      return 'https://i.iwara.tv/image/thumbnail/${customThumbnail!.id}/${customThumbnail!.name}';
    } else {
      return 'https://i.iwara.tv/image/thumbnail/${file?.id}/thumbnail-${_padNumber(thumbnail, 2)}.jpg';
    }
  }

  // 预览图
  String get previewUrl {
    return 'https://i.iwara.tv/image/original/${file?.id}/preview.webp';
  }

  // 获取分钟形式的时长
  String? get minutesDuration {
    if (file == null || file!.duration == null) {
      return null;
    }
    final int hours = file!.duration! ~/ 3600;
    final int minutes = (file!.duration! % 3600) ~/ 60;
    final int seconds = file!.duration! % 60;
    if (hours > 0) {
      return '${_padNumber(hours, 2)}:${_padNumber(minutes, 2)}:${_padNumber(seconds, 2)}';
    } else {
      return '${_padNumber(minutes, 2)}:${_padNumber(seconds, 2)}';
    }
  }

  String _padNumber(int? number, int width) {
    if (number == null) {
      return '00';
    }
    return number.toString().padLeft(width, '0');
  }

  Video copyWith({
    String? id,
    String? slug,
    String? title,
    String? body,
    String? status,
    String? rating,
    bool? private,
    bool? unlisted,
    int? thumbnail,
    String? embedUrl,
    bool? liked,
    int? numLikes,
    int? numViews,
    int? numComments,
    MediaFile? file,
    CustomThumbnail? customThumbnail,
    User? user,
    List<Tag>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fileUrl,
    List<VideoSource>? videoSources,
  }) {
    return Video(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      body: body ?? this.body,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      private: private ?? this.private,
      unlisted: unlisted ?? this.unlisted,
      thumbnail: thumbnail ?? this.thumbnail,
      embedUrl: embedUrl ?? this.embedUrl,
      liked: liked ?? this.liked,
      numLikes: numLikes ?? this.numLikes,
      numViews: numViews ?? this.numViews,
      numComments: numComments ?? this.numComments,
      file: file ?? this.file,
      customThumbnail: customThumbnail ?? this.customThumbnail,
      user: user ?? this.user,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fileUrl: fileUrl ?? this.fileUrl,
      videoSources: videoSources ?? this.videoSources,
    );
  }
}
