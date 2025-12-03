/// Model representing an autocomplete search suggestion
class SearchSuggestion {
  final String id;
  final String text;
  final double score;
  /// Address of the court (only available when includeDetails=true)
  final String? address;
  /// Latitude coordinate (only available when includeDetails=true)
  final double? latitude;
  /// Longitude coordinate (only available when includeDetails=true)
  final double? longitude;

  const SearchSuggestion({
    required this.id,
    required this.text,
    required this.score,
    this.address,
    this.latitude,
    this.longitude,
  });

  /// Check if this suggestion has location coordinates
  bool get hasLocation => latitude != null && longitude != null;

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      id: json['id'] as String,
      text: json['text'] as String,
      score: (json['score'] as num).toDouble(),
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'score': score,
      if (address != null) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  @override
  String toString() =>
      'SearchSuggestion(id: $id, text: $text, score: $score, address: $address, latitude: $latitude, longitude: $longitude)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchSuggestion &&
        other.id == id &&
        other.text == text &&
        other.score == score &&
        other.address == address &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      text.hashCode ^
      score.hashCode ^
      address.hashCode ^
      latitude.hashCode ^
      longitude.hashCode;
}

