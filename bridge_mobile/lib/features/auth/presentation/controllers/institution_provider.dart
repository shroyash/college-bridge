import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../data/models/institution_model.dart';

class InstitutionNotifier extends StateNotifier<InstitutionModel?> {
  final SecureStorageService _storage;

  InstitutionNotifier(this._storage) : super(null) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final id = await _storage.getInstitutionId();
    final name = await _storage.getInstitutionName();
    final code = await _storage.getInstitutionCode();

    if (id != null || (name != null && name.isNotEmpty)) {
      state = InstitutionModel(
        institutionId: id ?? 0,
        name: name ?? '',
        code: code ?? '',
      );
    }
  }

  void updateInstitution(InstitutionModel? institution) {
    state = institution;
    if (institution != null) {
      _storage.saveInstitutionDetails(
        institutionId: institution.institutionId,
        institutionCode: institution.code,
        institutionName: institution.name,
      );
    }
  }

  void clear() {
    state = null;
  }
}

final currentInstitutionProvider =
    StateNotifierProvider<InstitutionNotifier, InstitutionModel?>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return InstitutionNotifier(storage);
});
