import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scanpdf/services/qr_service.dart';

final qrServiceProvider = Provider<QrService>((ref) => QrService());
