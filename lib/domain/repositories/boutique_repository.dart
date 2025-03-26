import 'package:opti_app/domain/entities/Boutique.dart';

abstract class BoutiqueRepository {
  Future<List<Boutique>> getOpticiens();
  Future<void> addOpticien(Boutique opticien);
  Future<void> updateOpticien(String id, Boutique opticien);
  Future<void> deleteOpticien(String id);
  Future<Boutique> getOpticienById(String id);
  
}