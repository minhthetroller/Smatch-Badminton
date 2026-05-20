import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smatch_badminton/core/utils/image_url_helper.dart';
import 'package:smatch_badminton/models/match.dart';
import 'package:smatch_badminton/views/matches/widgets/match_card.dart';

void main() {
  group('MatchCard', () {
    Widget createWidget(MatchWithDetails match) {
      return MaterialApp(
        home: Scaffold(body: MatchCard(match: match)),
      );
    }

    testWidgets('renders a media placeholder when images are empty', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget(_matchWithImages()));

      expect(find.byKey(const Key('match_card_media_area')), findsOneWidget);
      expect(
        find.byKey(const Key('match_card_image_placeholder')),
        findsOneWidget,
      );
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('uses transformed image URL when an image is available', (
      tester,
    ) async {
      const rawUrl = 'http://127.0.0.1:4566/smatch-photos/matches/1.jpg';

      await tester.pumpWidget(createWidget(_matchWithImages(images: [rawUrl])));

      final image = tester.widget<CachedNetworkImage>(
        find.byKey(const Key('match_card_image')),
      );

      expect(image.imageUrl, ImageUrlHelper.transformImageUrl(rawUrl));
      expect(find.byKey(const Key('match_card_media_area')), findsOneWidget);
    });
  });
}

MatchWithDetails _matchWithImages({List<String> images = const []}) {
  return MatchWithDetails(
    id: 'match-1',
    courtId: 'court-1',
    hostUserId: 'user-1',
    title: 'Evening doubles',
    images: images,
    skillLevel: SkillLevel.tb,
    shuttleType: ShuttleType.other,
    playerFormat: PlayerFormat.doubleMale,
    date: '2026-05-20',
    startTime: '18:00',
    endTime: '20:00',
    isPrivate: false,
    price: 50000,
    slotsNeeded: 4,
    status: MatchStatus.open,
    createdAt: DateTime(2026, 5, 20),
    updatedAt: DateTime(2026, 5, 20),
    court: const MatchCourt(
      id: 'court-1',
      name: 'Smatch Court',
      addressDistrict: 'Cau Giay',
    ),
    host: const MatchHost(id: 'user-1', displayName: 'Minh'),
  );
}
