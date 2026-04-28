import 'package:flutter/foundation.dart';

final ValueNotifier<int> skeletonVisibilityCounter = ValueNotifier<int>(0);

void markSkeletonVisible() {
  skeletonVisibilityCounter.value = skeletonVisibilityCounter.value + 1;
}

void markSkeletonHidden() {
  final current = skeletonVisibilityCounter.value;
  if (current > 0) {
    skeletonVisibilityCounter.value = current - 1;
  }
}
