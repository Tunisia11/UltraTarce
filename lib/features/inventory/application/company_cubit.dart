import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/company_repository.dart';
import '../../../domain/app_models.dart';
import '../../../domain/services/audit_service.dart';

class CompanyState {
  const CompanyState(this.company);

  final CompanyProfile company;
}

class CompanyCubit extends Cubit<CompanyState?> {
  CompanyCubit(this._companyRepository, this._auditRepository) : super(null);

  final CompanyRepository _companyRepository;
  final AuditRepository _auditRepository;

  void loadCompany() {
    emit(CompanyState(_companyRepository.getCompany()));
  }

  AppSnapshot updateCompanyProfile(CompanyProfile company) {
    _companyRepository.updateCompany(
      company,
      status: 'Profil société sauvegardé.',
    );
    final snapshot = _appendAudit(
      action: 'Configuration société',
      target: company.name,
      detail: 'Profil société et identité facture mis à jour.',
    );
    emit(CompanyState(company));
    return snapshot;
  }

  AppSnapshot updateFiscalSettings({
    required bool timbreFiscalEnabled,
    required double timbreFiscalAmount,
  }) {
    final company = _companyRepository.getCompany().copyWith(
      timbreFiscalEnabled: timbreFiscalEnabled,
      timbreFiscalAmount: timbreFiscalAmount,
    );
    _companyRepository.updateCompany(
      company,
      status: 'Configuration fiscale sauvegardée.',
    );
    final snapshot = _appendAudit(
      action: 'Configuration fiscale',
      target: 'Timbre fiscal',
      detail: timbreFiscalEnabled
          ? 'Activé par défaut'
          : 'Désactivé par défaut',
    );
    emit(CompanyState(company));
    return snapshot;
  }

  AppSnapshot updateLogo(String logoSource) {
    final company = _companyRepository.getCompany().copyWith(
      logoSource: logoSource,
    );
    final snapshot = _companyRepository.updateCompany(
      company,
      status: 'Logo société sauvegardé.',
    );
    emit(CompanyState(company));
    return snapshot;
  }

  AppSnapshot _appendAudit({
    required String action,
    required String target,
    required String detail,
  }) {
    return _auditRepository.saveAll(
      AuditService.append(
        events: _auditRepository.getAll(),
        action: action,
        target: target,
        detail: detail,
      ),
      status: 'Audit sauvegardé.',
    );
  }
}
