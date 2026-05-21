import 'package:flutter_test/flutter_test.dart';
import 'package:smatch_badminton/core/config/env.dart';
import 'package:smatch_badminton/core/utils/image_url_helper.dart';

void main() {
  group('ImageUrlHelper', () {
    test(
      'transforms supported LocalStack S3 hostnames through backend proxy',
      () {
        final urls = [
          'http://localhost:4566/smatch-photos/matches/1.jpg',
          'http://127.0.0.1:4566/smatch-photos/matches/1.jpg',
          'http://localstack:4566/smatch-photos/matches/1.jpg',
          'http://s3.localhost.localstack.cloud:4566/smatch-photos/matches/1.jpg',
          'http://smatch-photos.s3.localhost.localstack.cloud:4566/matches/1.jpg',
        ];

        for (final url in urls) {
          expect(
            ImageUrlHelper.transformImageUrl(url),
            '${Env.apiBaseUrl}/api/s3-proxy/smatch-photos/matches/1.jpg',
          );
        }
      },
    );

    test('keeps malformed and non-LocalStack URLs unchanged', () {
      final urls = [
        'not a url',
        'https://localhost:4566/smatch-photos/matches/1.jpg',
        'http://localhost:3000/smatch-photos/matches/1.jpg',
      ];

      for (final url in urls) {
        expect(ImageUrlHelper.transformImageUrl(url), url);
      }
    });

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
          'https://cdn.example.com/smatch-photos/matches/2.jpg',
        ]),
        [
          '${Env.apiBaseUrl}/api/s3-proxy/smatch-photos/matches/1.jpg',
          'https://cdn.example.com/smatch-photos/matches/2.jpg',
        ],
      );
    });
  });
}
