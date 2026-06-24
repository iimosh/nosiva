import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/listing.dart';
import '../domain/listing_enums.dart';
import '../domain/listing_filter.dart';

class ListingsRepository {
  ListingsRepository(this._client);
  final SupabaseClient _client;

  static const _table = 'listings';
  static const _imagesTable = 'listing_images';
  static const _bucket = 'listing-images';
  static const _select =
      '*, images:listing_images(*), seller:profiles!listings_seller_id_fkey(*)';
  static const pageSize = 20;

  Future<List<Listing>> fetchFeed({
    ListingFilter filter = const ListingFilter(),
    int page = 0,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    var query = _client.from(_table).select(_select).eq('status', 'active');

    final uid = _client.auth.currentUser?.id;
    if (uid != null) query = query.neq('seller_id', uid);

    if (filter.category != null) {
      query = query.eq('category', filter.category!.value);
    }
    if (filter.size != null) query = query.eq('size', filter.size!);
    if (filter.condition != null) {
      query = query.eq('condition', filter.condition!.value);
    }
    if (filter.color != null) query = query.ilike('color', '%${filter.color}%');
    if (filter.brand != null) query = query.ilike('brand', '%${filter.brand}%');
    if (filter.location != null && filter.location!.trim().isNotEmpty) {
      final city = filter.location!.split(',').first.trim();
      query = query.ilike('location', '%$city%');
    }
    if (filter.minPrice != null) query = query.gte('price', filter.minPrice!);
    if (filter.maxPrice != null) query = query.lte('price', filter.maxPrice!);
    if (filter.styleTags.isNotEmpty) {
      query = query.contains('style_tags', filter.styleTags);
    }
    if (filter.query != null && filter.query!.trim().isNotEmpty) {
      query = query.textSearch('search_doc', filter.query!.trim(),
          config: 'english', type: TextSearchType.websearch);
    }

    final data = await query
        .order(filter.sort.column, ascending: filter.sort.ascending)
        .range(from, to);

    return data.map<Listing>((e) => Listing.fromJson(e)).toList();
  }

  Future<Listing> fetchById(String id) async {
    final data =
        await _client.from(_table).select(_select).eq('id', id).single();
    return Listing.fromJson(data);
  }

  /// Active listings from a set of sellers (the "Following" home feed).
  Future<List<Listing>> fetchBySellers(List<String> sellerIds,
      {int limit = 50}) async {
    if (sellerIds.isEmpty) return [];
    final data = await _client
        .from(_table)
        .select(_select)
        .eq('status', 'active')
        .inFilter('seller_id', sellerIds)
        .order('created_at', ascending: false)
        .limit(limit);
    return data.map<Listing>((e) => Listing.fromJson(e)).toList();
  }

  Future<List<Listing>> fetchBySeller(String sellerId) async {
    final data = await _client
        .from(_table)
        .select(_select)
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);
    return data.map<Listing>((e) => Listing.fromJson(e)).toList();
  }

  Future<Listing> createListing({
    required String sellerId,
    required Map<String, dynamic> values,
    required List<({Uint8List bytes, String ext})> images,
  }) async {
    final inserted = await _client
        .from(_table)
        .insert({...values, 'seller_id': sellerId})
        .select('id')
        .single();
    final listingId = inserted['id'] as String;

    if (images.isNotEmpty) {
      await _uploadImages(sellerId: sellerId, listingId: listingId, images: images);
    }
    return fetchById(listingId);
  }

  Future<void> _uploadImages({
    required String sellerId,
    required String listingId,
    required List<({Uint8List bytes, String ext})> images,
    int startPosition = 0,
  }) async {
    const uuid = Uuid();
    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < images.length; i++) {
      final img = images[i];
      final path = '$sellerId/$listingId/${uuid.v4()}.${img.ext}';
      await _client.storage.from(_bucket).uploadBinary(
            path,
            img.bytes,
            fileOptions: FileOptions(
              contentType: 'image/${img.ext == 'jpg' ? 'jpeg' : img.ext}',
              upsert: true,
            ),
          );
      final publicUrl = _client.storage.from(_bucket).getPublicUrl(path);
      rows.add({
        'listing_id': listingId,
        'image_url': publicUrl,
        'position': startPosition + i,
      });
    }
    await _client.from(_imagesTable).insert(rows);
  }

 Future<void> addImages({
    required String sellerId,
    required String listingId,
    required List<({Uint8List bytes, String ext})> images,
    int startPosition = 0,
  }) =>
      _uploadImages(
        sellerId: sellerId,
        listingId: listingId,
        images: images,
        startPosition: startPosition,
      );

  Future<void> deleteImage(String imageId) async {
    await _client.from(_imagesTable).delete().eq('id', imageId);
  }

  Future<void> updateListing(String id, Map<String, dynamic> values) async {
    await _client.from(_table).update(values).eq('id', id);
  }

  Future<void> setStatus(String id, ListingStatus status) =>
      updateListing(id, {'status': status.value});

  Future<void> deleteListing(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  Future<List<Listing>> fetchAllRecent({int limit = 50}) async {
    final data = await _client
        .from(_table)
        .select(_select)
        .order('created_at', ascending: false)
        .limit(limit);
    return data.map<Listing>((e) => Listing.fromJson(e)).toList();
  }
}

final listingsRepositoryProvider = Provider<ListingsRepository>((ref) {
  return ListingsRepository(ref.watch(supabaseClientProvider));
});
