import 'package:flutter_test/flutter_test.dart';
import 'package:smatch_badminton/core/config/env.dart';
import 'package:smatch_badminton/core/utils/image_url_helper.dart';

void main() {
  group('ImageUrlHelper', () {
    test(
      'returns LocalStack S3 URLs unchanged (directly reachable in local dev)',
      () {
        final urls = [
          'http://localhost:4566/smatch-photos/matches/1.jpg',
          'http://127.0.0.1:4566/smatch-photos/matches/1.jpg',
          'http://localstack:4566/smatch-photos/matches/1.jpg',
          'http://s3.localhost.localstack.cloud:4566/smatch-photos/matches/1.jpg',
        ];

        for (final url in urls) {
          expect(ImageUrlHelper.transformImageUrl(url), url);
        }
      },
    );

    test(
      'transforms virtual-hosted-style AWS S3 URLs through backend proxy',
      () {
        expect(
          ImageUrlHelper.transformImageUrl(
            'https://smatch-matches.s3.amazonaws.com/matches/uuid-ts.jpg',
          ),
          '${Env.apiBaseUrl}/api/s3-proxy/smatch-matches/matches/uuid-ts.jpg',
        );
        expect(
          ImageUrlHelper.transformImageUrl(
            'https://smatch-photos.s3.amazonaws.com/users/123/profile.jpg',
          ),
          '${Env.apiBaseUrl}/api/s3-proxy/smatch-photos/users/123/profile.jpg',
        );
      },
    );

    test(
      'transforms virtual-hosted-style AWS S3 URLs with region qualifier',
      () {
        expect(
          ImageUrlHelper.transformImageUrl(
            'https://smatch-matches.s3.ap-southeast-1.amazonaws.com/matches/x.jpg',
          ),
          '${Env.apiBaseUrl}/api/s3-proxy/smatch-matches/matches/x.jpg',
        );
      },
    );

    test(
      'transforms path-style AWS S3 URLs through backend proxy',
      () {
        expect(
          ImageUrlHelper.transformImageUrl(
            'https://s3.amazonaws.com/smatch-matches/matches/uuid-ts.jpg',
          ),
          '${Env.apiBaseUrl}/api/s3-proxy/smatch-matches/matches/uuid-ts.jpg',
        );
        expect(
          ImageUrlHelper.transformImageUrl(
            'https://s3.ap-southeast-1.amazonaws.com/smatch-photos/users/1.jpg',
          ),
          '${Env.apiBaseUrl}/api/s3-proxy/smatch-photos/users/1.jpg',
        );
      },
    );

    test('keeps external and already proxied URLs unchanged', () {
      final urls = [
        'https://cdn.example.com/smatch-photos/matches/1.jpg',
        '${Env.apiBaseUrl}/api/s3-proxy/smatch-photos/matches/1.jpg',
      ];

      for (final url in urls) {
        expect(ImageUrlHelper.transformImageUrl(url), url);
      }
    });

    test('transforms each URL in a list', () {
      expect(
        ImageUrlHelper.transformImageUrls([
          'http://localhost:4566/smatch-photos/matches/1.jpg',
          'https://smatch-matches.s3.amazonaws.com/matches/2.jpg',
          'https://cdn.example.com/smatch-photos/matches/3.jpg',
        ]),
        [
          'http://localhost:4566/smatch-photos/matches/1.jpg',
          '${Env.apiBaseUrl}/api/s3-proxy/smatch-matches/matches/2.jpg',
          'https://cdn.example.com/smatch-photos/matches/3.jpg',
        ],
      );
    });
  });
}
