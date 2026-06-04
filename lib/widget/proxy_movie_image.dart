import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

class ProxyMovieImage extends StatelessWidget {
  final String url;

  const ProxyMovieImage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: ExtendedImage.network(
        url,
        fit: BoxFit.cover,
        cache: true,
        compressionRatio: 0.5,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        headers: {
          "User-Agent":
              "Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Mobile/15E148 Safari/604.1",
        },
        loadStateChanged: (ExtendedImageState state) {
          if (state.extendedImageLoadState == LoadState.loading) {
            return Image.asset("images/movie-lazy.gif", fit: BoxFit.cover);
          } else if (state.extendedImageLoadState == LoadState.failed) {
            return Image.asset("images/movie-lazy.gif", fit: BoxFit.cover);
          } else {
            return null;
          }
        },
      ),
    );
  }
}
