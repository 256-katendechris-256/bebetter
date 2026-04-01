import 'dart:math';

class BookStore{
  final int  id;
  final String name;
  final String slug;
  final String primaryColor;
  final String logoUrl;
  final String address;
  final double? latitude;
  final double? longitude;
  double? distanceKm;
  
  BookStore({
    required this.id,
    required this.name,
    required this.slug,
    required this.primaryColor,
    required this.logoUrl,
    required this.address,
    this.latitude,
    this.longitude,
    this.distanceKm,
});

  factory BookStore.fromJson(Map<String, dynamic>json){
    return BookStore(
        id: json['id'],
        name: json['name'],
        slug: json['slug'],
        primaryColor: json['primary_color'] ?? '#6C63FF',
        logoUrl: json['logo_url'] ?? '',
        address: json['address'] ?? '',
        latitude: json['latitude']!= null
                  ? double.tryParse(json['latitude'].toString())
                  : null,
        longitude: json['longitude']!= null
                  ? double.tryParse(json['longitude'].toString())
                  :null,

    );
  }
  // get distance string
  String get distanceText{
    if (distanceKm == null) return 'Distance unknown';
    if (distanceKm!<1) return '${(distanceKm! * 1000).round()} m away';
    return '${distanceKm!.toStringAsFixed(1)} km away';
  }
}