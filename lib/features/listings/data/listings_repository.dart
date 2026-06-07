import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/listing.dart';
import '../domain/listing_filter.dart';

/// Read/write access to listings, their images, and Storage uploads.
class ListingsRepository {
  ListingsRepository(this._client);
  final SupabaseClient _client;

  static const _table = 'listings';
  static const _imagesTable = 'listing_images';
  static const _bucket = 'listing-images';
  // Name the FK explicitly: `listings` relates to `profiles` via several paths
  // (seller_id, plus m2m through favorites/offers/orders), so PostgREST needs
  // the exact constraint to disambiguate the embed.
  static const _select =
      '*, images:listing_images(*), seller:profiles!listings_seller_id_fkey(*)';
  static const pageSize = 20;

  /// Paginated feed/browse with filters. [page] is zero-based.
  Future<List<Listing>> fetchFeed({
    ListingFilter filter = const ListingFilter(),
    int page = 0,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    var query = _client.from(_table).select(_select).eq('status', 'active');

    if (filter.category != null) {
      query = query.eq('category', filter.category!.value);
    }
    if (filter.size != null) query = query.eq('size', filter.size!);
    if (filter.condition != null) {
      query = query.eq('condition', filter.condition!.value);
    }
    if (filter.color != null) query = query.ilike('color', '%${filter.color}%');
    if (filter.brand != null) query = query.ilike('brand', '%${filter.brand}%');
    if (filter.location != null) {
      query = query.ilike('location', '%${filter.location}%');
    }
    if (filter.minPrice != null) query = query.gte('price', filter.minPrice!);
    if (filter.maxPrice != null) query = query.lte('price', filter.maxPrice!);
    if (filter.styleTags.isNotEmpty) {
      query = query.contains('style_tags', filter.styleTags);
    }
    if (filter.query != null && filter.query!.trim().isNotEmpty) {
      // Full-text search across title/description/brand (see SQL: search_doc).
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

  Future<List<Listing>> fetchBySeller(String sellerId) async {
    final data = await _client
        .from(_table)
        .select(_select)
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);
    return data.map<Listing>((e) => Listing.fromJson(e)).toList();
  }

  /// Creates a listing then uploads its images. Returns the full listing.
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
      rows.add({'listing_id': listingId, 'image_url': publicUrl, 'position': i});
    }
    await _client.from(_imagesTable).insert(rows);
  }

  Future<void> updateListing(String id, Map<String, dynamic> values) async {
    await _client.from(_table).update(values).eq('id', id);
  }

  Future<void> deleteListing(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}

final listingsRepositoryProvider = Provider<ListingsRepository>((ref) {
  return ListingsRepository(ref.watch(supabaseClientProvider));
});
