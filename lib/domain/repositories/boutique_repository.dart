import 'package:opti_app/domain/entities/Boutique.dart';

abstract class BoutiqueRepository {
  Future<List<Opticien>> getOpticiens();
  Future<void> addOpticien(Opticien opticien);
  Future<void> updateOpticien(String id, Opticien opticien);
  Future<void> deleteOpticien(String id);
}