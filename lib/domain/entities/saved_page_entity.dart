enum SavedPageCollection { bookmarks, readingList }

class SavedPageEntity {
  final String id;
  final String title;
  final String url;
  final String folder;
  final SavedPageCollection collection;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavedPageEntity({
    required this.id,
    required this.title,
    required this.url,
    required this.folder,
    required this.collection,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedPageEntity.fromJson(Map<String, dynamic> json) {
    return SavedPageEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      folder: (json['folder'] as String?)?.trim() ?? '',
      collection: SavedPageCollection.values.firstWhere(
        (value) => value.name == json['collection'],
        orElse: () => SavedPageCollection.bookmarks,
      ),
      isRead: json['isRead'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'url': url,
    'folder': folder,
    'collection': collection.name,
    'isRead': isRead,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  SavedPageEntity copyWith({
    String? id,
    String? title,
    String? url,
    String? folder,
    SavedPageCollection? collection,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedPageEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      folder: folder ?? this.folder,
      collection: collection ?? this.collection,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
