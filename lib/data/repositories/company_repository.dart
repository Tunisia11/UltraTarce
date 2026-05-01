import '../../domain/app_models.dart';
import '../local/database/mappers/company_mapper.dart';
import 'app_repository.dart';

class CompanyRepository {
  CompanyRepository(this._appRepository);

  final AppRepository _appRepository;

  CompanyProfile getCompany() => _appRepository.snapshot.company;

  AppSnapshot updateCompany(CompanyProfile company, {required String status}) {
    final snapshot = _appRepository.snapshot;
    return _appRepository.commitDaoMutation(
      AppSnapshot(
        company: company,
        warehouses: snapshot.warehouses,
        categories: snapshot.categories,
        products: snapshot.products,
        partners: snapshot.partners,
        documents: snapshot.documents,
        movements: snapshot.movements,
        sequences: snapshot.sequences,
        auditEvents: snapshot.auditEvents,
      ),
      status: status,
      write: (database) => database.companyDao.upsertCompany(
        CompanyMapper.toCompanion(company, tenantId: _appRepository.tenantId),
      ),
    );
  }
}
