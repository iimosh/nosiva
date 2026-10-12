import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nosiva/core/widgets/shimmer_box.dart';

void main() {
  final skeletons = <String, Widget>{
    'listing grid': const ListingGridSkeleton(),
    'list': const ListSkeleton(),
    'list with thumbnails': const ListSkeleton(
        leading: SkeletonLeading.square, leadingSize: 64, lines: 3),
    'listing page': const ListingDetailSkeleton(),
    'profile': const ProfileSkeleton(),
    'chat': const ChatSkeleton(),
    'edit form': const FormSkeleton(),
    'edit listing form': const FormSkeleton(header: FormSkeletonHeader.photos),
    'detail': const DetailSkeleton(),
  };

  for (final brightness in Brightness.values) {
    for (final entry in skeletons.entries) {
      testWidgets('${entry.key} skeleton lays out on a phone (${brightness.name})',
          (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(body: entry.value),
        ));
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
      });
    }
  }
}
