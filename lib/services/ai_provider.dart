import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scanpdf/services/ai_service.dart';

final aiServiceProvider = Provider<AiService>((ref) => AiService());
